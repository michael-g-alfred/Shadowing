import SwiftUI

struct TaskListView: View {
    
        // MARK: - Environment
    @Environment(DIContainer.self) private var container
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
        // MARK: - Properties
    let tasks: [TaskModel]
    let isLoading: Bool
    let errorMessage: String?
    let isLoadingMore: Bool
    
    let loadingTitle: LocalizedStringResource
    let loadingSubtitle: LocalizedStringResource
    let emptyState: EmptyState
    
    let onLoad: () async -> Void
    let onLoadMoreIfNeeded: () async -> Void
    var onClearFilter: (() -> Void)? = nil

    
    var leadingSwipe: ((TaskModel) -> AnyView)? = nil
    var trailingSwipe: ((TaskModel) -> AnyView)? = nil
    
        // MARK: - Body
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
        if horizontalSizeClass == .compact {
            compactContent
        } else {
            regularContent
        }
    }
    
        // MARK: - Compact Content (iPhone)
    @ViewBuilder
    private var compactContent: some View {
        if isLoading {
            ScrollView {
                TaskCardSingletonList()
            }
        } else if let error = errorMessage {
            LoadingState.error(message: error).view
        } else if tasks.isEmpty {
            emptyState.view(
                retryAction: { await onLoad() },
                clearFilterAction: onClearFilter
            )
        } else {
            listContent
        }
    }
    
        // MARK: - Regular Content (iPad)
    @ViewBuilder
    private var regularContent: some View {
        if isLoading {
            GeometryReader { geometry in
                let columnCount = columnCount(for: geometry.size.width)
                let columns = Array(
                    repeating: GridItem(.flexible(), spacing: 16, alignment: .top),
                    count: columnCount
                )
                
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(0..<15, id: \.self) { _ in
                            TaskCardSingleton()
                        }
                    }
                    .padding(16)
                }
            }
        } else if let error = errorMessage {
            LoadingState.error(message: error).view
        } else if tasks.isEmpty {
            emptyState.view(
                retryAction: { await onLoad() },
                clearFilterAction: onClearFilter
            )
        } else {
            gridContent
        }
    }
    
        // MARK: - Compact (List with swipe actions)
    private var listContent: some View {
        List {
            ForEach(tasks) { task in
                TaskCard(task: task)
                    .background(
                        NavigationLink(value: task.id) {
                            EmptyView()
                        }
                            .opacity(0)
                    )
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
                TaskCardSingleton()
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .navigationDestination(for: String.self) { taskId in
            container.makeTaskDetailsView(taskId: taskId)
        }
    }
    
        // MARK: - Regular (Grid, 2 or 3 columns based on width)
    private var gridContent: some View {
        GeometryReader { geometry in
            let columnCount = columnCount(for: geometry.size.width)
            let columns = Array(
                repeating: GridItem(.flexible(), spacing: 16, alignment: .top),
                count: columnCount
            )
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(tasks) { task in
                        NavigationLink(value: task.id) {
                            TaskCard(task: task)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {

                            if let trailingSwipe {
                                trailingSwipe(task)
                            }
                            if let leadingSwipe {
                                leadingSwipe(task)
                            }
                        }
                        .task {
                            if tasks.suffix(5).contains(where: { $0.id == task.id }) {
                                await onLoadMoreIfNeeded()
                            }
                        }
                    }
                    
                    if isLoadingMore {
                        ForEach(0..<columnCount, id: \.self) { _ in
                            TaskCardSingleton()
                        }
                    }
                }
                .padding(16)
            }
            .navigationDestination(for: String.self) { taskId in
                container.makeTaskDetailsView(taskId: taskId)
            }
        }
    }
    
    private func columnCount(for width: CGFloat) -> Int {
        if width >= 1080 {
            return 3
        } else {
            return 2
        }
    }
}
