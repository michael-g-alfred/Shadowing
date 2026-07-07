import SwiftUI

struct TaskDetailsView: View {
    
    @State private var vm: TaskDetailsViewModel
    
    init(taskId: String, vm: TaskDetailsViewModel) {
        _vm = State(initialValue: vm)
    }
    
    var body: some View {
        content
            .task { await vm.loadDetails() }
            .navigationTitle("Task Details")
            .navigationBarTitleDisplayMode(.inline)
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
                timelineSection(task)
                taskInfoSection(task)
                locationSection(task)
                requesterSection(task.requester)
                if let executor = task.executor {
                    executorSection(executor)
                }
            }
            .listStyle(.insetGrouped)
        }
    }
    
        // MARK: - Title
    
    private func titleSection(_ task: TaskModel) -> some View {
        Section("Title") {
            Text(task.title)
                .font(.headline)
        }
    }
    
    private func descriptionSection(_ task: TaskModel) -> some View {
        Section("Description") {
            Text(task.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
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
                systemImage: "wallet.bifold",
                value: task.budget.formatted(.currency(code: task.currency)),
            )
            
            InfoRow(
                title: "Status",
                systemImage: "flag",
                value: task.status.localizedLabel,
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
    }
    
        // MARK: - Timeline
    
    private func timelineSection(_ task: TaskModel) -> some View {
        Section("Timeline") {
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
                value: "\(task.applicantsCount)"
            )
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
    }
    
        // MARK: - Requester / Executor
    
    private func requesterSection(_ user: TaskUserModel) -> some View {
        Section("Requester") {
            userRows(for: user)
        }
    }
    
    private func executorSection(_ user: TaskUserModel) -> some View {
        Section("Executor") {
            userRows(for: user)
        }
    }
    
    @ViewBuilder
    private func userRows(for user: TaskUserModel) -> some View {
        InfoRow(title: "Name", systemImage: "person", value: user.displayName)
        
        InfoRow(
            title: "Completed Tasks",
            systemImage: "checklist",
            value: "\(user.completedTasks)"
        )
        
        InfoRow(
            title: "Total Ratings",
            systemImage: "person.2",
            value: user.totalRatings > 0 ? String(user.totalRatings) : "No ratings yet"
        )
        
        InfoRow(
            title: "Rating",
            systemImage: "star",
            value: user.totalRatings > 0 ? String(format: "%.1f", user.rating) : "No ratings yet"
        )
    }
}
