import Foundation
import Observation
import CoreLocation

@MainActor
@Observable
final class AddTaskSheetViewModel {
    
    var title: String = ""
    var description: String = ""
    var budget: Double = 0
    var selectedCurrency: CurrencyLookup?
    var selectedPriority: PriorityLookup?
    var selectedService: TaskServiceLookup? {
        didSet {
            guard oldValue?.id != selectedService?.id else { return }
            Task { await loadSuggestedSpecialists() }
        }
    }
    var serviceOther: String = ""
    var address: String = ""
    var timing: TaskTiming = .now
    var scheduledDate: Date = Date()
    var isPreferredTimeOfDay: Bool = false
    var preferredTimeOfDay: TimeOfDayLookup? = nil
    
    var isLoading: Bool = false
    var errorMessage: String?
    private(set) var didAttemptSubmit: Bool = false
    var didPostSuccessfully: Bool = false
    
        // MARK: - Validation / Alert State
    
    var showErrorsAlert: Bool = false
    
    var currentValidation: TaskValidationResult { validate() }
    var isFormValid: Bool { currentValidation.isValid }
    var validationAlertMessage: String {
        currentValidation.errors.map { "• \($0)" }.joined(separator: "\n")
    }
    
        // MARK: - Suggested Specialists
    
    private(set) var suggestedSpecialists: [UserSummaryModel] = []
    private(set) var isLoadingSpecialists: Bool = false
    private var specialistsGeneration = 0
    
        /// Specialists picked on the invite screen. Kept here (rather than only
        /// inside `SpecialistsSelectionViewModel`) because the task doesn't
        /// exist yet at selection time — the actual invitation notifications
        /// (which need the created task's id so tapping one opens that task)
        /// are sent from `submitTask()` once the post succeeds.
    var selectedSpecialistIDs: Set<String> = []
    
    var onTaskAdded: (() async -> Void)?
    
    private let taskRepo: TaskRepositoryProtocol
    private let userRepo: UserRepositoryProtocol
    private let locationService: LocationServiceProtocol
    private let notificationRepo: NotificationRepositoryProtocol
    private let authRepo: AuthRepositoryProtocol
    let lookupStore: LookupStore
    
    init(
        authRepo: AuthRepositoryProtocol,
        taskRepo: TaskRepositoryProtocol,
        userRepo: UserRepositoryProtocol,
        notificationRepo: NotificationRepositoryProtocol,
        locationService: LocationServiceProtocol,
        lookupStore: LookupStore,
        onTaskAdded: (() async -> Void)? = nil
    ) {
        self.authRepo = authRepo
        self.taskRepo = taskRepo
        self.userRepo = userRepo
        self.locationService = locationService
        self.notificationRepo = notificationRepo
        self.lookupStore = lookupStore
        self.onTaskAdded = onTaskAdded
    }
    
        // MARK: - Lookup-derived data for the form
    var availablePriorities: [PriorityLookup] { lookupStore.priorities }
    var availableServices: [TaskServiceLookup] { lookupStore.services }
    var availableTimesOfDay: [TimeOfDayLookup] { lookupStore.timesOfDay }
    var availableCurrencies: [CurrencyLookup] { lookupStore.currencies }
    
    func loadLookupsIfNeeded() async {
        await lookupStore.loadLookup()
        if selectedPriority == nil {
            selectedPriority = lookupStore.priority(named: "normal")
        }
        if selectedService == nil {
            selectedService = lookupStore.service(named: "delivery")
        }
        if selectedCurrency == nil {
            selectedCurrency = lookupStore.currency(named: "EGP")
        }
    }
    
        // MARK: - Suggested Specialists
    
        /// Fetches the top-rated users registered under the currently selected
        /// service type. Silent on failure - this is a nice-to-have preview,
        /// not something that should block or clutter the form with an error.
    func loadSuggestedSpecialists() async {
        guard let selectedService else {
            suggestedSpecialists = []
            return
        }
        
        specialistsGeneration += 1
        let myGeneration = specialistsGeneration
        isLoadingSpecialists = true
        defer { isLoadingSpecialists = false }
        
        do {
            let result = try await userRepo.fetchUsersBySpecialty(serviceId: selectedService.id, limit: 50)
            guard myGeneration == specialistsGeneration else { return }
            suggestedSpecialists = result
        } catch {
            guard myGeneration == specialistsGeneration else { return }
            print("⚠️ loadSuggestedSpecialists failed for serviceId \(selectedService.id): \(error)")
            suggestedSpecialists = []
        }
    }
    
    func makeSpecialistsSelectionViewModel() -> SpecialistsSelectionViewModel {
        SpecialistsSelectionViewModel(
            specialists: suggestedSpecialists,
            userRepo: userRepo,
            initialSelectedIDs: selectedSpecialistIDs
        )
    }
    
        /// Called by the invite screen when the user confirms their picks
        /// (see `AddTaskToolbar`'s `.onDismiss` wiring in the View). Just
        /// stores the picks — the actual notifications go out after the task
        /// is successfully posted, so they can carry a real `taskId`.
    func updateSelectedSpecialists(_ ids: Set<String>) {
        selectedSpecialistIDs = ids
    }
    
        // MARK: - Submission
    
        /// Single entry point the view calls for the "Post" action (and the
        /// warning-triangle toolbar button). Decides itself whether to submit
        /// or surface the validation errors alert.
    func attemptSubmit() {
        Task { await submitTask() }
        
    }
    
    func submitTask() async {
        didAttemptSubmit = true
        let validation = validate()
        
        guard validation.isValid else {
            return
        }
        
        guard let selectedPriority, let selectedService, let selectedCurrency else {
            errorMessage = "Lookups not loaded yet"
            return
        }
        
        isLoading = true
        errorMessage = nil
        didPostSuccessfully = false
        
        defer {
            isLoading = false
        }
        
        do {
            let scheduledAtToSend = timing == .scheduled
            ? scheduledDate
            : nil
            
            let latitudeToSend = locationService.currentLocation?.coordinate.latitude
            let longitudeToSend = locationService.currentLocation?.coordinate.longitude
            
            let result = try await taskRepo.postTask(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                description: description.trimmingCharacters(in: .whitespacesAndNewlines),
                budget: budget,
                currencyId: selectedCurrency.id,
                priorityId: selectedPriority.id,
                serviceTypeId: selectedService.id,
                address: address.trimmingCharacters(in: .whitespacesAndNewlines),
                latitude: latitudeToSend,
                longitude: longitudeToSend,
                scheduledAt: scheduledAtToSend,
                preferredTimeOfDayId: preferredTimeOfDay?.id
            )
            
            didPostSuccessfully = true
            AlertCenter.shared.show(responseType: result.type, message: result.message)
            
            await sendSpecialistInvites(taskId: result.task.id)
            
            reset()
            
            if let onTaskAdded {
                await onTaskAdded()
            }
            
        } catch {
            errorMessage = error.localizedDescription
            AlertCenter.shared.showError(error.localizedDescription)
        }
    }
    
        /// Sends a `taskInvitation` notification (carrying the real `taskId`)
        /// to every specialist picked on the invite screen, so tapping the
        /// notification can deep-link straight into this task.
        ///
        /// The title/body shown on-device are localized — `NotificationModel`
        /// derives them from the type plus `taskTitle` (passed here as
        /// `subjectText`), so this only needs to supply the raw task title,
        /// not any composed English text.
        ///
        /// Per `NotificationRepositoryProtocol`, sends are fire-and-forget —
        /// a failure for one specialist shouldn't block the others or the
        /// (already-succeeded) task post, so each call is wrapped in `try?`.
        ///
        /// - Parameter taskId: The just-created task's id.
    private func sendSpecialistInvites(taskId: String) async {
        guard !selectedSpecialistIDs.isEmpty else { return }
        
        let invitedSpecialists = suggestedSpecialists.filter { selectedSpecialistIDs.contains($0.id) }
        let taskTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        
        await withTaskGroup(of: Void.self) { group in
            for specialist in invitedSpecialists {
                group.addTask { [notificationRepo] in
                    try? await notificationRepo.send(
                        to: specialist.id,
                        type: .taskInvitation,
                        subjectText: taskTitle,
                        messageText: nil,
                        taskId: taskId
                    )
                }
            }
        }
    }
    
    func reset() {
        title = ""
        description = ""
        budget = 0
        address = ""
        
        selectedPriority = lookupStore.priority(named: "normal")
        selectedService = lookupStore.service(named: "delivery")
        selectedCurrency = lookupStore.currency(named: "EGP")
        serviceOther = ""
        
        timing = .now
        scheduledDate = Date()
        
        isPreferredTimeOfDay = false
        preferredTimeOfDay = nil
        
        suggestedSpecialists = []
        selectedSpecialistIDs = []
        didAttemptSubmit = false
        showErrorsAlert = false
    }
    
    var isValid: Bool {
        validate().isValid
    }
    
        // MARK: - Validation
        // Mirrors task.schema.js (Joi) exactly, so a submission that passes
        // here is guaranteed to pass backend validation too:
        //   title: min 3, max 100
        //   description: min 10, max 500
        //   budget: positive, min 1 (no upper bound - backend has none)
        //   address: min 3
        //   scheduledAt: cannot be in the past (when timing == .scheduled)
    func validate() -> TaskValidationResult {
        var errors: [String] = []
        
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedTitle.isEmpty {
            errors.append("Title is required")
        } else if trimmedTitle.count < 3 {
            errors.append("Title must be at least 3 characters")
        } else if trimmedTitle.count > 100 {
            errors.append("Title must be at most 100 characters")
        }
        
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedDescription.isEmpty {
            errors.append("Description is required")
        } else if trimmedDescription.count < 10 {
            errors.append("Description must be at least 10 characters")
        } else if trimmedDescription.count > 500 {
            errors.append("Description must be at most 500 characters")
        }
        
        if budget < 1 {
            errors.append("Budget must be at least 1")
        }
        
        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedAddress.isEmpty {
            errors.append("Address is required")
        } else if trimmedAddress.count < 3 {
            errors.append("Address must be at least 3 characters")
        }
        
        if timing == .scheduled && scheduledDate < Date().addingTimeInterval(-60) {
            errors.append("Scheduled time cannot be in the past")
        }
        
        return TaskValidationResult(
            isValid: errors.isEmpty,
            errors: errors
        )
    }
    
    func preferredTimeOfDayToggle() {
        isPreferredTimeOfDay.toggle()
        
        if !isPreferredTimeOfDay {
            preferredTimeOfDay = nil
        }
    }
}

struct TaskValidationResult {
    let isValid: Bool
    let errors: [String]
}

    // MARK: - Specialists Selection View Model

@MainActor
@Observable
final class SpecialistsSelectionViewModel {
    
    let specialists: [UserSummaryModel]
    var selectedIDs: Set<UserSummaryModel.ID>
    
    private let userRepo: UserRepositoryProtocol
    
    init(specialists: [UserSummaryModel], userRepo: UserRepositoryProtocol, initialSelectedIDs: Set<String> = []) {
        self.specialists = specialists
        self.userRepo = userRepo
        self.selectedIDs = initialSelectedIDs
    }
    
    var hasSelection: Bool { !selectedIDs.isEmpty }
    var selectionCount: Int { selectedIDs.count }
}
