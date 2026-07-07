import SwiftUI

struct MainView: View {
    
    @Environment(DIContainer.self) private var container
    @State private var vm: MainViewModel
    
    init(vm: MainViewModel) {
        _vm = State(initialValue: vm)
    }
    
    var body: some View {
        TabView(selection: $vm.selectedTab) {
            ForEach(AppTab.allCases) { tab in
                Tab(tab.title, systemImage: tab.image, value: tab) {
                    view(for: tab)
                }
            }
        }
    }
    
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
