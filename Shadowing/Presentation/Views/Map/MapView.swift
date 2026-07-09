import SwiftUI
import MapKit

struct MapView: View {
    
    @State private var vm: MapViewModel
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var navigationPath = NavigationPath()
    
    private let makeTaskDetails: (String) -> AnyView
    
    init(vm: MapViewModel, makeTaskDetails: @escaping (String) -> AnyView) {
        _vm = State(initialValue: vm)
        self.makeTaskDetails = makeTaskDetails
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            Map(position: $cameraPosition) {
                ForEach(vm.tasks) { task in
                    Annotation(task.title, coordinate: task.coordinate) {
                        Button {
                            withAnimation(.easeInOut) { vm.selectTask(task) }
                        } label: {
                            CustomMapPin(
                                iconName: task.serviceType.icon,
                                priorityColor: task.priority.color
                            )
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
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
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
    
    private func navigateToDetails(_ taskId: String) {
        vm.clearSelection()
        navigationPath.append(taskId)
    }
    
    private func openDirections(to task: TaskModel) {
        let location = CLLocation(latitude: task.coordinate.latitude, longitude: task.coordinate.longitude)
        let mapItem = MKMapItem(location: location, address: .none)
        mapItem.name = task.title
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}

struct CustomMapPin: View {
    let iconName: String
    let priorityColor: Color
    
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Circle()
                .fill(priorityColor.opacity(0.25))
                .frame(width: 44, height: 44)
                .scaleEffect(isAnimating ? 1.3 : 0.85)
                .opacity(isAnimating ? 0 : 1)
                .animation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: false),
                    value: isAnimating
                )
            
            Circle()
                .fill(priorityColor)
                .frame(width: 36, height: 36)
                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
            
            Circle()
                .fill(.white)
                .frame(width: 32, height: 32)
                .overlay {
                    Image(systemName: iconName)
                        .foregroundStyle(priorityColor)
                }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

private struct TaskMapCard: View {
    let task: TaskModel
    let onDirections: () -> Void
    let onDetails: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(task.title)
                        .font(.title3)
                        .bold()
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    
                    Text(task.budget, format: .currency(code: "EGP"))
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button(role:.destructive, action: onDismiss) {
                    Image(systemName: "xmark")
                        .padding(8)
                        .background(.red)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }
            }
            
            Divider()
            
            HStack(spacing: 12) {
                Button(action: onDirections) {
                    Label("Directions", systemImage: "point.bottomleft.forward.to.arrow.triangle.uturn.scurvepath.fill")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue.opacity(0.15))
                        .foregroundColor(.blue)
                        .cornerRadius(12)
                }
                
                Button(action: onDetails) {
                    Label("Details", systemImage: "text.page.badge.magnifyingglass")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
        }
        .padding(20)
        .background(.ultraThickMaterial)
        .cornerRadius(24)
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [task.priority.color, task.priority.color.opacity(0.5), task.priority.color.opacity(0.25)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        }
        .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 5)
    }
}
