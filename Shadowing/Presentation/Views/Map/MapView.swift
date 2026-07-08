import SwiftUI
import MapKit

struct MapView: View {
    
    @State private var vm: MapViewModel
    @State private var cameraPosition: MapCameraPosition = .automatic
    
    private let makeTaskDetails: (String) -> AnyView
    
    init(vm: MapViewModel, makeTaskDetails: @escaping (String) -> AnyView) {
        _vm = State(initialValue: vm)
        self.makeTaskDetails = makeTaskDetails
    }
    
    var body: some View {
        NavigationStack {
            Map(position: $cameraPosition) {
                ForEach(vm.tasks) { task in
                    Annotation(task.title, coordinate: task.coordinate) {
                        Button {
                            withAnimation(.easeInOut) { vm.selectTask(task) }
                        } label: {
                            Image(systemName: "mappin.circle.fill")
                                .font(.title2)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, .blue)
                        }
                    }
                }
            }
            .overlay(alignment: .bottom) {
                if let task = vm.selectedTask {
                    TaskMapCard(
                        task: task,
                        onDirections: { openDirections(to: task) },
                        onDetails: { navigateToDetails(task.id) },
                        onDismiss: { withAnimation(.easeInOut) { vm.clearSelection() } }
                    )
                    .padding()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationDestination(for: String.self) { taskId in
                makeTaskDetails(taskId)
            }
            .onMapCameraChange(frequency: .onEnd) { context in
                vm.regionDidChange(context.region)
            }
            .overlay {
                if vm.isLoading && vm.tasks.isEmpty {
                    ProgressView()
                }
            }
        }
    }
    
    @State private var navigationPath = NavigationPath()
    
    private func navigateToDetails(_ taskId: String) {
        vm.clearSelection()
        navigationPath.append(taskId)
    }
    
    private func openDirections(to task: MapTaskItem) {
        let placemark = MKPlacemark(coordinate: task.coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = task.title
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}

private struct TaskMapCard: View {
    let task: MapTaskItem
    let onDirections: () -> Void
    let onDetails: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.headline)
                        .lineLimit(2)
                    Text(task.budget, format: .currency(code: "EGP"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
            
            HStack(spacing: 12) {
                ActionButton(title: "Directions", systemImage: "car.fill", labelStyle: .titleAndIcon, tint: .accentColor, buttonSizing: .fitted) {
                    onDirections()
                }
                ActionButton(title: "Details", systemImage: "doc.text.magnifyingglass", labelStyle: .titleAndIcon, tint: .accentColor, buttonSizing: .fitted) {
                    onDetails()
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 8)
    }
}
