import Foundation
import Observation
import CoreLocation

@MainActor
@Observable
final class AddTaskSheetViewModel {
    
    var title: String = ""
    var description: String = ""
    var budget: Double = 0
    var selectedPriority: TaskPriority = .normal
    var selectedService: TaskService = .delivery
    var serviceOther: String = ""
    var address: String = ""
    var timing: TaskTiming = .now
    var scheduledDate: Date = Date()
    var isPreferredTimeOfDay: Bool = false
    var preferredTimeOfDay: PreferredTimeOfDay? = nil
    
    var isLoading: Bool = false
    var errorMessage: String?
    var didPostSuccessfully: Bool = false
    
    var onTaskAdded: (() async -> Void)?
    
    private let taskRepo: TaskRepositoryProtocol
    private let locationService: LocationService
    
    init(
        taskRepo: TaskRepositoryProtocol,
        locationService: LocationService,
        onTaskAdded: (() async -> Void)? = nil
    ) {
        self.taskRepo = taskRepo
        self.locationService = locationService
        self.onTaskAdded = onTaskAdded
    }
    
    func submitTask() async {
        let validation = validate()
        
        guard validation.isValid else {
            errorMessage = validation.errors.first
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
                priority: selectedPriority,
                serviceType: selectedService.rawValue,
                address: address.trimmingCharacters(in: .whitespacesAndNewlines),
                latitude: latitudeToSend,
                longitude: longitudeToSend,
                scheduledAt: scheduledAtToSend,
                preferredTimeOfDay: preferredTimeOfDay
            )
            
            didPostSuccessfully = true
            AlertCenter.shared.show(responseType: result.type, message: result.message)
            reset()
            
            if let onTaskAdded {
                await onTaskAdded()
            }
            
        } catch {
            errorMessage = error.localizedDescription
            AlertCenter.shared.showError(error)
        }
    }
    
    func reset() {
        title = ""
        description = ""
        budget = 0
        address = ""
        
        selectedPriority = .normal
        selectedService = .delivery
        serviceOther = ""
        
        timing = .now
        scheduledDate = Date()
        
        isPreferredTimeOfDay = false
        preferredTimeOfDay = nil
    }
    
    var isValid: Bool {
        validate().isValid
    }
    
    func validate() -> TaskValidationResult {
        var errors: [String] = []
        
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Title is required")
        } else if title.count < 3 {
            errors.append("Title must be at least 3 characters")
        }
        
        if description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Description is required")
        } else if description.count < 10 {
            errors.append("Description must be at least 10 characters")
        }
        
        if budget <= 0 {
            errors.append("Budget must be greater than 0 EGP")
        } else if budget > 100000 {
            errors.append("Budget seems too high")
        }
        
        if address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Address is required")
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
