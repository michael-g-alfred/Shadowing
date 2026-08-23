import Foundation
import CoreLocation
import MapKit

@MainActor
@Observable
final class MapViewModel {
    private(set) var tasks: [TaskModel] = []
    private(set) var isLoading = false
    private(set) var isTruncated = false
    var errorMessage: String?
    var selectedTask: TaskModel?
    
    private let taskRepo: TaskRepositoryProtocol
    private let lookupStore: LookupStore
    private nonisolated(unsafe) var debounceTask: Task<Void, Never>?
    private var lastBounds: MapBounds?

    init(taskRepo: TaskRepositoryProtocol, lookupStore: LookupStore) {
        self.taskRepo = taskRepo
        self.lookupStore = lookupStore
    }

    deinit {
        debounceTask?.cancel()
    }
    
    func regionDidChange(_ region: MKCoordinateRegion) {
        let bounds = MapBounds(
            minLat: region.center.latitude - region.span.latitudeDelta / 2,
            maxLat: region.center.latitude + region.span.latitudeDelta / 2,
            minLng: region.center.longitude - region.span.longitudeDelta / 2,
            maxLng: region.center.longitude + region.span.longitudeDelta / 2
        )
        guard bounds != lastBounds else { return }
        lastBounds = bounds
        
        debounceTask?.cancel()
        debounceTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            await self?.fetch(bounds)
        }
    }

    private func fetch(_ bounds: MapBounds) async {
        isLoading = true
        errorMessage = nil
        do {
            // The repository already maps to domain and filters out
            // coordinate-less tasks, so this can be assigned directly.
            let page = try await taskRepo.getMapTasks(bounds: bounds)
            tasks = page.tasks
            isTruncated = page.truncated
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func selectTask(_ task: TaskModel) { selectedTask = task }
    func clearSelection() { selectedTask = nil }

        // MARK: - Pin Presentation

        /// SF Symbol name for a task's service type (falls back to a generic pin).
    func serviceIconName(for task: TaskModel) -> String {
        lookupStore.service(named: task.serviceType)?.icon ?? "mappin"
    }

        /// Lookup color name for a task's priority (falls back to gray).
    func priorityColorName(for task: TaskModel) -> String {
        lookupStore.priority(named: task.priority)?.color ?? "gray"
    }
}
