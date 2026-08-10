import SwiftUI

// MARK: - Container

struct HomeView: View {

    // MARK: Environment
    @Environment(DIContainer.self) private var container

    // MARK: State
    @State private var vm: HomeViewModel

    // MARK: Init
    init(vm: HomeViewModel) {
        _vm = State(initialValue: vm)
    }

    // MARK: Body
    var body: some View {
        NavigationStack {
            ScreenContainer {
                HomeModeContentView(container: container, selectedMode: vm.selectedMode)
            }
            .navigationTitle(vm.selectedMode.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HomeModeToggleButton(vm: vm)
                }
            }
        }
    }
}

// MARK: - Content

private struct HomeModeContentView: View {
    let container: DIContainer
    let selectedMode: UserMode

    var body: some View {
        Group {
            switch selectedMode {
                case .requester:
                    container.makeRequesterView()
                case .executor:
                    container.makeExecutorView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Toolbar

private struct HomeModeToggleButton: View {
    let vm: HomeViewModel

    var body: some View {
        Button {
            vm.toggleMode()
        } label: {
            Label(
                vm.selectedMode == .requester ? UserMode.executor.title : UserMode.requester.title,
                systemImage: vm.selectedMode == .requester ? UserMode.executor.image : UserMode.requester.image
            )
            .labelStyle(.titleAndIcon)
        }
    }
}

// MARK: - Preview

#Preview {
    HomeView(vm: HomeViewModel())
}
