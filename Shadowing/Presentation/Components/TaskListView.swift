import SwiftUI

struct TaskListView: View {
    
    @Environment(DIContainer.self) private var container
    
    let tasks: [TaskModel]
    let isLoading: Bool
    let errorMessage: String?
    let isLoadingMore: Bool
    
    let loadingTitle: LocalizedStringResource
    let loadingSubtitle: LocalizedStringResource
    let emptyState: EmptyState
    
    let onLoad: () async -> Void
    let onLoadMoreIfNeeded: () async -> Void
    
    var leadingSwipe: ((TaskModel) -> AnyView)? = nil
    var trailingSwipe: ((TaskModel) -> AnyView)? = nil
    
    var body: some View {
        content
            .task {
                await onLoad()
            }
            .refreshable {
                await onLoadMoreIfNeeded()
            }
    }
    
    @ViewBuilder
    private var content: some View {
        if isLoading {
            LoadingState.loading(
                title: loadingTitle,
                subtitle: loadingSubtitle
            ).view
            
        } else if let error = errorMessage {
            LoadingState.error(message: error).view
            
        } else if tasks.isEmpty {
            emptyState.view {
                await onLoad()
            }
            
        } else {
            List {
                ForEach(tasks) { task in
                    TaskCard(task: task)
                        .background(content: {
                            NavigationLink(value: task.id) {
                                EmptyView()
                            }
                        })
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            if let leadingSwipe {
                                leadingSwipe(task)
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            if let trailingSwipe {
                                trailingSwipe(task)
                            }
                        }
                        .task {
                            if tasks.suffix(5).contains(where: { $0.id == task.id }) {
                                await onLoadMoreIfNeeded()
                            }
                        }
                }
                
                if isLoadingMore {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .navigationDestination(for: String.self) { taskId in
                container.makeTaskDetailsView(taskId: taskId)
            }
        }
    }
}
