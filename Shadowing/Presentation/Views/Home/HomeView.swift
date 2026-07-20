import SwiftUI

struct HomeView: View {
    
    // MARK: - Environment
    @Environment(DIContainer.self) private var container
    
    // MARK: - State
    @State private var vm: HomeViewModel
    
    // MARK: - Init
    init(vm: HomeViewModel) {
        _vm = State(initialValue: vm)
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                
                Group {
                    switch vm.selectedMode {
                        case .requester:
                            container.makeRequesterView()
                            
                        case .executor:
                            container.makeExecutorView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle(vm.selectedMode.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        vm.toggleMode()
                    } label: {
                        Label(
                            vm.selectedMode == .requester
                            ? UserMode.executor.title
                            : UserMode.requester.title,
                            systemImage: vm.selectedMode == .requester
                            ? UserMode.executor.image
                            : UserMode.requester.image
                        )
                        .labelStyle(.titleAndIcon)
                    }
                }
            }
        }
    }
}

#Preview {
    HomeView(vm: HomeViewModel())
}
