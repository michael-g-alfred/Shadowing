import SwiftUI

struct MainView: View {
    
    // MARK: - Environment
    @Environment(DIContainer.self) private var container
    
    // MARK: - State
    @State private var vm: MainViewModel
    
    // MARK: - Init
    init(vm: MainViewModel) {
        _vm = State(initialValue: vm)
    }
    
    // MARK: - Body
    var body: some View {
        TabView(selection: $vm.selectedTab) {
            ForEach(AppTab.allCases) { tab in
                Tab(tab.title, systemImage: tab.image, value: tab) {
                    view(for: tab)
                }
            }
        }
    }
    
    // MARK: - Private Views
    @ViewBuilder
    private func view(for tab: AppTab) -> some View {
        switch tab {
            case .home: container.makeHomeView()
            case .map: container.makeMapView()
            case .chat: ChatView()
            case .profile: container.makeProfileView()
        }
    }
}
