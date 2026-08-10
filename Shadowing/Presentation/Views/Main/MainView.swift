import SwiftUI

    // MARK: - Container

struct MainView: View {
    
        // MARK: Environment
    @Environment(DIContainer.self) private var container
    
        // MARK: State
    @State private var vm: MainViewModel
    
        // MARK: Init
    init(vm: MainViewModel) {
        _vm = State(initialValue: vm)
    }
    
        // MARK: Body
    var body: some View {
        TabView(selection: $vm.selectedTab) {
            ForEach(AppTab.allCases) { tab in
                Tab(tab.title, systemImage: tab.image, value: tab) {
                    view(for: tab)
                }
                .badge(badgeCount(for: tab))
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
    }
    
        // MARK: Private Helpers
    private func badgeCount(for tab: AppTab) -> Int {
        switch tab {
            case .chats: return container.chatViewModel.totalUnreadCount
            case .notifications: return container.notificationViewModel.unreadCount
            default: return 0
        }
    }
    
        // MARK: Private Views
    @ViewBuilder
    private func view(for tab: AppTab) -> some View {
        switch tab {
            case .home: container.makeHomeView()
            case .map: container.makeMapView()
            case .chats: container.makeChatView()
            case .notifications: container.makeNotificationView()
            case .profile: container.makeProfileView()
        }
    }
}
