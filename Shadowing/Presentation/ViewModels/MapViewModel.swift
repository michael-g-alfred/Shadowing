import Foundation
import CoreLocation
import MapKit

@MainActor
@Observable
final class MapViewModel {
    private(set) var tasks: [MapTaskItem] = []
    private(set) var isLoading = false
    private(set) var isTruncated = false
    var errorMessage: String?
    var selectedTask: MapTaskItem?
    
    private let taskRepo: TaskRepositoryProtocol
    private var debounceTask: Task<Void, Never>?
    private var lastBounds: MapBounds?
    
    init(taskRepo: TaskRepositoryProtocol) {
        self.taskRepo = taskRepo
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
        debounceTask = Task {
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            await fetch(bounds)
        }
    }
    
    private func fetch(_ bounds: MapBounds) async {
        isLoading = true
        errorMessage = nil
        do {
            let page = try await taskRepo.getMapTasks(bounds: bounds)
            tasks = page.tasks
            isTruncated = page.truncated
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func selectTask(_ task: MapTaskItem) { selectedTask = task }
    func clearSelection() { selectedTask = nil }
}
