import Foundation
import CoreLocation

@MainActor
@Observable
final class MapViewModel {
    
    private(set) var tasks: [MapTaskItem] = []
    private(set) var isLoading = false
    var errorMessage: String?
    
    var selectedTask: MapTaskItem?
    
    private let taskRepo: TaskRepositoryProtocol
    private var cursor: String?
    private var hasMore = true
    
    init(taskRepo: TaskRepositoryProtocol) {
        self.taskRepo = taskRepo
    }
    
    func loadMapTasks() async {
        guard !isLoading, hasMore else { return }
        isLoading = true
        errorMessage = nil
        do {
            let page = try await taskRepo.getMapTasks(cursor: cursor)
            tasks.append(contentsOf: page.tasks)
            cursor = page.nextCursor
            hasMore = page.nextCursor != nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func selectTask(_ task: MapTaskItem) {
        selectedTask = task
    }
    
    func clearSelection() {
        selectedTask = nil
    }
}
