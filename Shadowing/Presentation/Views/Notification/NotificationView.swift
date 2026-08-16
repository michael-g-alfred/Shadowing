import SwiftUI

    // MARK: - Container

struct NotificationView: View {
    
        // MARK: Environment
    @Environment(DIContainer.self) private var container
    
        // MARK: State
    @State private var vm: NotificationViewModel
    @State private var showDeleteAllAlert = false
    
        // MARK: Init
    init(vm: NotificationViewModel) {
        _vm = State(initialValue: vm)
    }
    
        // MARK: Body
    var body: some View {
        NavigationStack {
            ScreenContainer {
                NotificationContentView(state: state, vm: vm)
            }
            .navigationTitle("Notifications")
            .toolbar {
                NotificationToolbar(vm: vm, showDeleteAllAlert: $showDeleteAllAlert)
            }
            .alert("Delete all notifications?", isPresented: $showDeleteAllAlert) {
                Button("Delete All", role: .destructive) {
                    Task { await vm.deleteAll() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This can't be undone.")
            }
            .navigationDestination(item: Bindable(vm).selectedDestination) { destination in
                switch destination {
                    case .taskDetails(let taskId):
                        container.makeTaskDetailsView(taskId: taskId)
                    case .chat(let taskId):
                        container.makeDirectChatDetailView(taskId: taskId)
                }
            }
        }
        .task {
            vm.startListening()
        }
    }
    
        // MARK: Private Helpers
    private var state: ViewState<[NotificationModel]> {
        if vm.isLoading && vm.notifications.isEmpty { return .loading }
        if vm.notifications.isEmpty { return .empty }
        return .loaded(vm.notifications)
    }
}

    // MARK: - Toolbar

private struct NotificationToolbar: ToolbarContent {
    let vm: NotificationViewModel
    @Binding var showDeleteAllAlert: Bool
    
    var body: some ToolbarContent {
        if !vm.notifications.isEmpty {
            ToolbarItem(placement: .topBarLeading) {
                Button("Delete all", role: .destructive) {
                    showDeleteAllAlert = true
                }
            }
        }
        
        if vm.unreadCount > 0 {
            ToolbarItem(placement: .primaryAction) {
                Button("Mark all read") {
                    Task { await vm.markAllAsRead() }
                }
            }
        }
    }
}

    // MARK: - Content (state routing)

private struct NotificationContentView: View {
    let state: ViewState<[NotificationModel]>
    let vm: NotificationViewModel
    
    var body: some View {
        DataStateView(
            state: state,
            loadingState: .loading(title: "Loading notifications", subtitle: "Please wait a moment..."),
            emptyState: .noNotifications
        ) { notifications in
            NotificationLoadedView(notifications: notifications, vm: vm)
        }
    }
}

    // MARK: - Loaded

private struct NotificationLoadedView: View {
    
        // MARK: Environment
    @Environment(\.colorScheme) private var colorScheme
    
        // MARK: Properties
    let notifications: [NotificationModel]
    let vm: NotificationViewModel
    
    private func listRowColor(isRead: Bool) -> Color? {
        if isRead {
            return colorScheme == .dark ? Color.accentColor.opacity(0.15) : nil
        }
        return colorScheme == .dark
        ? Color.green.opacity(0.15)
        : Color.green.opacity(0.35)
    }
    
        // MARK: Body
    var body: some View {
        List {
            ForEach(notifications) { notification in
                NotificationRow(notification: notification)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        vm.didTap(notification)
                    }
                    .listRowBackground(listRowColor(isRead: notification.isRead))
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            Task { await vm.delete(notification) }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        if !notification.isRead {
                            Button {
                                Task { await vm.markAsRead(notification) }
                            } label: {
                                Label("Read", systemImage: "envelope.open")
                            }
                            .tint(.blue)
                        }
                    }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }
}

    // MARK: - Row

private struct NotificationRow: View {
    let notification: NotificationModel
    
    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: notification.type.iconName)
                .foregroundStyle(notification.isRead ? .primary : Color(.accent))
                .imageScale(.large)
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Text(notification.title)
                        .font(.subheadline)
                        .bold()
                        .foregroundStyle(.primary)
                    Spacer()
                    Text(notification.createdAt, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Text(notification.body)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
