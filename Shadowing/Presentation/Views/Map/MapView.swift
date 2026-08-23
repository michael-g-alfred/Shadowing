import SwiftUI
import MapKit

struct MapView: View {

        // MARK: - Environment
    @Environment(DIContainer.self) private var container

        // MARK: - Properties
    private let makeTaskDetails: (String) -> AnyView

        // MARK: - State
    @State private var vm: MapViewModel
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var navigationPath = NavigationPath()

        // MARK: - Init
    init(vm: MapViewModel, makeTaskDetails: @escaping (String) -> AnyView) {
        _vm = State(initialValue: vm)
        self.makeTaskDetails = makeTaskDetails
    }

        // MARK: - Body
    var body: some View {
        NavigationStack(path: $navigationPath) {
            Map(position: $cameraPosition) {
                UserAnnotation()

                ForEach(vm.tasks) { task in
                    if let coordinate = task.coordinate {
                        Annotation(task.title, coordinate: coordinate) {
                            Button {
                                withAnimation(.easeInOut) { vm.selectTask(task) }
                            } label: {
                                CustomMapPin(
                                    iconName: vm.serviceIconName(for: task),
                                    priorityColor: priorityColor(for: task)
                                )
                            }
                        }
                    }
                }
            }
            .overlay(alignment: .bottom) {
                if let task = vm.selectedTask {
                    TaskMapCard(
                        task: task,
                        priorityColor: priorityColor(for: task),
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
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }
            .onAppear {
                    // Use the shared, app-wide location service (already wired up
                    // with a proper CLLocationManagerDelegate in DIContainer) instead
                    // of spinning up a second, delegate-less CLLocationManager here.
                    // A second instance would trigger a duplicate permission prompt
                    // and never actually receive authorization-change callbacks.
                container.locationService.requestLocation()
            }
        }
    }

        // MARK: - Private Methods
    private func priorityColor(for task: TaskModel) -> Color {
        Color(lookupName: vm.priorityColorName(for: task))
    }

    private func navigateToDetails(_ taskId: String) {
        vm.clearSelection()
        navigationPath.append(taskId)
    }

    private func openDirections(to task: TaskModel) {
        guard let coordinate = task.coordinate else { return }
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let mapItem = MKMapItem(location: location, address: .none)
        mapItem.name = task.title
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}

struct CustomMapPin: View {

        // MARK: - Properties
    let iconName: String
    let priorityColor: Color

        // MARK: - State
    @State private var isAnimating = false

        // MARK: - Body
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

        // MARK: - Properties
    let task: TaskModel
    let priorityColor: Color
    let onDirections: () -> Void
    let onDetails: () -> Void
    let onDismiss: () -> Void

        // MARK: - Body
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
                        colors: [priorityColor, priorityColor.opacity(0.5), priorityColor.opacity(0.25)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        }
        .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 5)
    }
}
