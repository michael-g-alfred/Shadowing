import SwiftUI

struct TaskDetailsView: View {
    
        // MARK: - Environment
    @Environment(\.colorScheme) private var colorScheme
    @Environment(DIContainer.self) private var container
    @Environment(\.locale) private var locale
    @Environment(\.dismiss) private var dismiss
    
        // MARK: - Properties
    private var listRowColor: Color? {
        colorScheme == .dark
        ? Color.accentColor.opacity(0.15)
        : nil
    }
    
        // MARK: - State
    @State private var vm: TaskDetailsViewModel
    @State private var isIdExpanded = false
    
        // MARK: - Init
    init(taskId: String, vm: TaskDetailsViewModel) {
        _vm = State(initialValue: vm)
    }
    
        // MARK: - Ratings Sheet Binding
    
        /// Derives an `isPresented` binding from `vm.selectedUserForRatings`
        /// so the shared `ratingsSheet` modifier can drive presentation
        /// without needing to know about `TaskDetailsViewModel` directly.
    private var isRatingsSheetPresented: Binding<Bool> {
        Binding(
            get: { vm.selectedUserForRatings != nil },
            set: { isPresented in
                if !isPresented {
                    vm.selectedUserForRatings = nil
                }
            }
        )
    }
    
        // MARK: - Body
    var body: some View {
        ZStack {
            AppBackground()
            content
        }
        .task { await vm.loadDetails() }
        .toolbar {
            if !vm.availableActions.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    actionsMenu
                }
            }
        }
        .ratingsSheet(
            userId: vm.selectedUserForRatings?.id,
            userName: vm.selectedUserForRatings?.displayName,
            isPresented: isRatingsSheetPresented
        )
    }
    
        // MARK: - Actions Menu
    private var actionsMenu: some View {
        Menu {
            ForEach(vm.availableActions) { action in
                Button(role: action.role) {
                    Task {
                        await vm.perform(action)
                        if action == .delete {
                            dismiss()
                        } else {
                            await vm.loadDetails()
                        }
                    }
                } label: {
                    Label(action.title, systemImage: action.systemImage)
                }
                .tint(action.color)
            }
        } label: {
            Image(systemName: "ellipsis")
        }
    }
    
        // MARK: - Private Views
    @ViewBuilder
    private var content: some View {
        if vm.isLoading {
            LoadingState.loading(title: "Loading task details").view
        } else if let error = vm.errorMessage {
            LoadingState.error(message: error).view
        } else if let task = vm.task {
            List {
                titleSection(task)
                descriptionSection(task)
                overviewSection(task)
                schedulingSection(task)
                locationSection(task)
                taskInfoSection(task)
                requesterSection(task.requester)
                if let executor = task.executor {
                    executorSection(executor)
                }
                historySection(task)
                idSection(for: task)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
    }
    
        // MARK: Title
    private func titleSection(_ task: TaskModel) -> some View {
        Section("Title") {
            Text(task.title)
                .font(.headline)
        }
        .listRowBackground(listRowColor)
    }
    
    private func descriptionSection(_ task: TaskModel) -> some View {
        Section("Description") {
            Text(task.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .listRowBackground(listRowColor)
    }
    
        // MARK: Overview
    private func overviewSection(_ task: TaskModel) -> some View {
        let service = container.lookupStore.service(named: task.serviceType)
        let status = container.lookupStore.status(named: task.status)
        let priority = container.lookupStore.priority(named: task.priority)
        
        return Section("Overview") {
            InfoRow(
                title: "Service",
                systemImage: service?.icon ?? "questionmark.circle",
                value: service?.label ?? task.serviceType
            )
            
            budgetRow(task)
            
            InfoRow(
                title: "Status",
                systemImage: "flag.fill",
                value: status?.label ?? task.status,
                iconColor: Color(lookupName: status?.color ?? "gray"),
                valueColor: Color(lookupName: status?.color ?? "gray")
            )
            
            InfoRow(
                title: "Priority",
                systemImage: priority?.icon ?? "questionmark.circle",
                value: priority?.label ?? task.priority,
                iconColor: Color(lookupName: priority?.color ?? "gray"),
                valueColor: Color(lookupName: priority?.color ?? "gray")
            )
        }
        .listRowBackground(listRowColor)
    }
    
    @ViewBuilder
    private func budgetRow(_ task: TaskModel) -> some View {
        if task.budgetDidChange, let originalBudget = task.originalBudget {
            
            InfoRow(title: "Original Budget", systemImage: "wallet.bifold.fill") {
                
                Text(
                    originalBudget.formatted(
                        .currency(code: task.currency)
                        .precision(.fractionLength(0))
                        .locale(locale)
                    )
                )
                .bold()
                .strikethrough()
            }
            
            InfoRow(title: "Accepted Budget", systemImage: "checkmark.seal.fill") {
                HStack(spacing: Spacing.xxs) {
                    Image(systemName: task.budgetIncreased ? "arrow.up" : "arrow.down")
                        .imageScale(.small)
                    
                    Text(
                        task.budget.formatted(
                            .currency(code: task.currency)
                            .precision(.fractionLength(0))
                            .locale(locale)
                        )
                    )
                }
                .foregroundStyle(budgetChangeColor(task))
                .bold()
            }
            
        } else {
            
            InfoRow(
                title: "Budget",
                systemImage: "wallet.bifold.fill",
                value: task.budget.formatted(.currency(code: task.currency).precision(.fractionLength(0)).locale(locale))
            )
        }
    }
    
        // MARK: Scheduling
    @ViewBuilder
    private func schedulingSection(_ task: TaskModel) -> some View {
        if task.scheduledAt != nil || task.preferredTimeOfDay != nil {
            Section("Scheduling") {
                if let scheduledAt = task.scheduledAt {
                    InfoRow(
                        title: "Scheduled",
                        systemImage: "calendar.badge.clock",
                        value: scheduledAt.formatted(.dateTime.day().month().year().hour().minute().locale(locale))
                    )
                }
                
                if let preferredTimeName = task.preferredTimeOfDay {
                    let timeOfDay = container.lookupStore.timeOfDay(named: preferredTimeName)
                    InfoRow(
                        title: "Preferred Time",
                        systemImage: timeOfDay?.icon ?? "sun.max",
                        value: timeOfDay?.label ?? preferredTimeName
                    )
                }
            }
            .listRowBackground(listRowColor)
        }
    }
    
        // MARK: Location
    private func locationSection(_ task: TaskModel) -> some View {
        Section("Location") {
            InfoRow(
                title: "Address",
                systemImage: "map.fill",
                value: task.address
            )
        }
        .listRowBackground(listRowColor)
    }
    
        // MARK: Task Info
    private func taskInfoSection(_ task: TaskModel) -> some View {
        let escrow = container.lookupStore.escrowStatus(named: task.escrowStatus)
        
        return Section("Task Info") {
            InfoRow(
                title: "Escrow",
                systemImage: "lock.shield.fill",
                value: escrow?.label ?? task.escrowStatus
            )
            
            InfoRow(
                title: "Applicants",
                systemImage: "person.3.fill",
                localizedValue: "\(task.applicantsCount)"
            )
        }
        .listRowBackground(listRowColor)
    }
    
        // MARK: Requester / Executor
    private func requesterSection(_ user: UserSummaryModel) -> some View {
        Section("Requester") {
            userRows(for: user)
        }
        .listRowBackground(listRowColor)
    }
    
    private func executorSection(_ user: UserSummaryModel) -> some View {
        Section("Executor") {
            userRows(for: user)
        }
        .listRowBackground(listRowColor)
    }
    
    @ViewBuilder
    private func userRows(for user: UserSummaryModel) -> some View {
        
        AvatarView(profile: user, size: 36, nameLayout: .horizontal)
            .listRowBackground(Color(.tertiaryLabel))
            .listRowSeparator(.hidden)
        
        InfoRow(
            title: "Completed Tasks",
            systemImage: "checklist",
            localizedValue: "\(user.completedTasks)"
        )
        
        InfoRow(
            title: "Total Ratings",
            systemImage: "list.star",
            localizedValue: user.totalRatings > 0
            ? "\(user.totalRatings)"
            : "-"
        )
        .contentShape(Rectangle())
        .onTapGesture {
            vm.selectedUserForRatings = user
        }
        
        InfoRow(
            title: "Rating",
            systemImage: "star.fill",
            localizedValue: user.totalRatings > 0
            ? "\(user.rating, specifier: "%.1f")"
            : "-"
        )
    }
    
        // MARK: History
    private func historySection(_ task: TaskModel) -> some View {
        Section("History") {
            InfoRow(
                title: "Created",
                systemImage: "calendar",
                value: task.createdAt.formatted(.dateTime.day().month().year().hour().minute().locale(locale))
            )
            
            InfoRow(
                title: "Updated",
                systemImage: "clock.badge.fill",
                value: task.updatedAt.formatted(.dateTime.day().month().year().hour().minute().locale(locale))
            )
        }
        .listRowBackground(listRowColor)
    }
    
        // MARK: Id
    private func idSection(for task: TaskModel) -> some View {
        Section("Reference Code") {
            InfoRow(title: "Reference Code", systemImage: "number.circle.fill") {
                Text(task.id.isEmpty ? "—" : displayedId(for: task.id))
                    .font(.caption)
                    .contentTransition(.numericText())
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation {
                    isIdExpanded.toggle()
                }
            }
        }
        .listRowBackground(listRowColor)
        .contextMenu {
            Button {
                UIPasteboard.general.string = task.id
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            } label: {
                Label("Copy Reference Code", systemImage: "doc.on.doc")
            }
        }
    }
    
        // MARK: - Private Methods
    
    private func budgetChangeColor(_ task: TaskModel) -> Color {
        let isRequester = container.authRepository.currentUser?.id == task.requester.id
        let increasedIsGood = isRequester ? false : true
        if task.budgetIncreased {
            return increasedIsGood ? .green : .red
        } else {
            return increasedIsGood ? .red : .green
        }
    }
    
    private func displayedId(for id: String) -> String {
        guard !isIdExpanded else { return id }
        return "\(id.prefix(9))...."
    }
}
