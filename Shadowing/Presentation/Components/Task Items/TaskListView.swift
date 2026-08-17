import SwiftUI

struct TaskListView<LeadingSwipe: View, TrailingSwipe: View>: View {
    
        // MARK: - Environment
    @Environment(DIContainer.self) private var container
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
        // MARK: - Properties
    let tasks: [TaskModel]
    let isLoading: Bool
    let errorMessage: String?
    let isLoadingMore: Bool
    
    let loadingTitle: LocalizedStringResource
    let emptyState: EmptyState
    
    let onLoad: () async -> Void
    let onLoadMoreIfNeeded: () async -> Void
    var onClearFilter: (() -> Void)? = nil
    var onToggleFavorite: ((TaskModel) -> Void)? = nil
    
    let leadingSwipe: (TaskModel) -> LeadingSwipe
    let trailingSwipe: (TaskModel) -> TrailingSwipe
    
        // MARK: - Initializer
    init(
        tasks: [TaskModel],
        isLoading: Bool,
        errorMessage: String?,
        isLoadingMore: Bool,
        loadingTitle: LocalizedStringResource,
        emptyState: EmptyState,
        onLoad: @escaping () async -> Void,
        onLoadMoreIfNeeded: @escaping () async -> Void,
        onClearFilter: (() -> Void)? = nil,
        onToggleFavorite: ((TaskModel) -> Void)? = nil,
        @ViewBuilder leadingSwipe: @escaping (TaskModel) -> LeadingSwipe = { _ in EmptyView() },
        @ViewBuilder trailingSwipe: @escaping (TaskModel) -> TrailingSwipe = { _ in EmptyView() }
    ) {
        self.tasks = tasks
        self.isLoading = isLoading
        self.errorMessage = errorMessage
        self.isLoadingMore = isLoadingMore
        self.loadingTitle = loadingTitle
        self.emptyState = emptyState
        self.onLoad = onLoad
        self.onLoadMoreIfNeeded = onLoadMoreIfNeeded
        self.onClearFilter = onClearFilter
        self.onToggleFavorite = onToggleFavorite
        self.leadingSwipe = leadingSwipe
        self.trailingSwipe = trailingSwipe
    }
    
        // MARK: - Body
    var body: some View {
        content
            .task {
                await onLoad()
            }
            .refreshable {
                await onLoadMoreIfNeeded()
            }
            .navigationDestination(for: String.self) { taskId in
                container.makeTaskDetailsView(taskId: taskId)
            }
    }
    
        // MARK: - Private Views
    @ViewBuilder
    private var content: some View {
        if horizontalSizeClass == .compact {
            compactContent
        } else {
            regularContent
        }
    }
    
        // MARK: Compact Content (iPhone)
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
    
        // MARK: Regular Content (iPad)
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
                            TaskCardSkeleton()
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
    
        // MARK: Compact (List with swipe actions)
    private var listContent: some View {
        List {
            ForEach(tasks) { task in
                TaskCard(
                    task: task,
                    onToggleFavorite: onToggleFavorite.map { handler in { handler(task) } }
                )
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
                    leadingSwipe(task)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    trailingSwipe(task)
                }
                .task {
                    if tasks.suffix(5).contains(where: { $0.id == task.id }) {
                        await onLoadMoreIfNeeded()
                    }
                }
            }
            
            if isLoadingMore {
                TaskCardSkeleton()
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
    }
    
        // MARK: Regular (Grid, 2 or 3 columns based on width)
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
                            TaskCard(
                                task: task,
                                onToggleFavorite: onToggleFavorite.map { handler in { handler(task) } }
                            )
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            trailingSwipe(task)
                            leadingSwipe(task)
                        }
                        .task {
                            if tasks.suffix(5).contains(where: { $0.id == task.id }) {
                                await onLoadMoreIfNeeded()
                            }
                        }
                    }
                    
                    if isLoadingMore {
                        ForEach(0..<columnCount, id: \.self) { _ in
                            TaskCardSkeleton()
                        }
                    }
                }
                .padding()
            }
        }
    }
    
        // MARK: - Private Methods
    private func columnCount(for width: CGFloat) -> Int {
        if width >= 1080 {
            return 3
        } else {
            return 2
        }
    }
}
