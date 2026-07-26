import SwiftUI

struct TaskDetailsView: View {
    
        // MARK: - Environment
    @Environment(\.colorScheme) private var colorScheme
    @Environment(DIContainer.self) private var container
    
        // MARK: - Properties
    private var listRowColor: Color? {
        colorScheme == .dark
        ? Color.accentColor.opacity(0.15)
        : nil
    }
    
    @State private var vm: TaskDetailsViewModel
    @State private var isIdExpanded = false
    
    init(taskId: String, vm: TaskDetailsViewModel) {
        _vm = State(initialValue: vm)
    }
    
    var body: some View {
        ZStack {
            AppBackground()
            content
        }
        .task { await vm.loadDetails() }
        .navigationTitle("Task Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $vm.selectedUserForRatings) { user in
            container.makeRatingsView(userId: user.id, userName: user.displayName)
                .appSheetStyle()
        }
    }
    
    @ViewBuilder
    private var content: some View {
        if vm.isLoading {
            LoadingState.loading(title: "Loading", subtitle: "Fetching task details").view
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
    
        // MARK: - Title
    
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
    
        // MARK: - Overview
    
    private func overviewSection(_ task: TaskModel) -> some View {
        Section("Overview") {
            InfoRow(
                title: "Service",
                systemImage: task.serviceType.icon,
                value: task.serviceType.localizedLabel
            )
            
            InfoRow(
                title: "Budget",
                systemImage: "wallet.bifold.fill",
                value: task.budget.formatted(.currency(code: task.currency))
            )
            
            InfoRow(
                title: "Status",
                systemImage: "flag.fill",
                value: task.status.localizedLabel,
                iconColor: task.status.color,
                valueColor: task.status.color
            )
            
            InfoRow(
                title: "Priority",
                systemImage: task.priority.icon,
                value: task.priority.localizedLabel,
                iconColor: task.priority.color,
                valueColor: task.priority.color
            )
        }
        .listRowBackground(listRowColor)
    }
    
        // MARK: - Scheduling
    
    @ViewBuilder
    private func schedulingSection(_ task: TaskModel) -> some View {
        if task.scheduledAt != nil || task.preferredTimeOfDay != nil {
            Section("Scheduling") {
                if let scheduledAt = task.scheduledAt {
                    InfoRow(
                        title: "Scheduled",
                        systemImage: "clock.badge",
                        value: scheduledAt.formatted(date: .abbreviated, time: .shortened)
                    )
                }
                
                if let preferredTime = task.preferredTimeOfDay {
                    InfoRow(
                        title: "Preferred Time",
                        systemImage: "sun.max",
                        value: preferredTime.localizedLabel
                    )
                }
            }
            .listRowBackground(listRowColor)
        }
    }
    
        // MARK: - Location
    
    private func locationSection(_ task: TaskModel) -> some View {
        Section("Location") {
            InfoRow(
                title: "Address",
                systemImage: "map",
                value: task.address
            )
        }
        .listRowBackground(listRowColor)
    }
    
        // MARK: - Task Info
    
    private func taskInfoSection(_ task: TaskModel) -> some View {
        Section("Task Info") {
            InfoRow(
                title: "Escrow",
                systemImage: "lock.shield",
                value: task.escrowStatus.localizedLabel
            )
            
            InfoRow(
                title: "Applicants",
                systemImage: "person.3",
                localizedValue: "\(task.applicantsCount)"
            )
        }
        .listRowBackground(listRowColor)
    }
    
        // MARK: - Requester / Executor
    
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
            systemImage: "person.2",
            localizedValue: user.totalRatings > 0
            ? "\(user.totalRatings)"
            : "No ratings yet"
        )
        .contentShape(Rectangle())
        .onTapGesture {
            vm.selectedUserForRatings = user
        }
        
        InfoRow(
            title: "Rating",
            systemImage: "star",
            localizedValue: user.totalRatings > 0
            ? "\(user.rating, specifier: "%.1f")"
            : "No ratings yet"
        )
    }
    
        // MARK: - History
    
    private func historySection(_ task: TaskModel) -> some View {
        Section("History") {
            InfoRow(
                title: "Created",
                systemImage: "calendar",
                value: task.createdAt.formatted(date: .abbreviated, time: .shortened)
            )
            
            InfoRow(
                title: "Updated",
                systemImage: "clock.arrow.circlepath",
                value: task.updatedAt.formatted(date: .abbreviated, time: .shortened)
            )
        }
        .listRowBackground(listRowColor)
    }
    
        // MARK: - Id
    
    private func idSection(for task: TaskModel) -> some View {
        Section("ID") {
            InfoRow(title: "Id", systemImage: "number.circle") {
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
                Label("Copy ID", systemImage: "doc.on.doc")
            }
        }
    }
    
    private func displayedId(for id: String) -> String {
        guard !isIdExpanded else { return id }
        return "\(id.prefix(9))...."
    }
}
