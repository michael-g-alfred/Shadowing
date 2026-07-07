import SwiftUI

struct HomeView: View {
    
    @Environment(DIContainer.self) private var container
    @State private var vm: HomeViewModel
    
    init(vm: HomeViewModel) {
        _vm = State(initialValue: vm)
    }
    
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
                    }
                    .buttonStyle(.glassProminent)
                }
            }
        }
    }
}

#Preview {
    HomeView(vm: HomeViewModel())
}
