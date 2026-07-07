import Observation

@MainActor
@Observable
final class MainViewModel {

    var selectedTab: AppTab = .home

    init() {}

    func select(_ tab: AppTab) {
        selectedTab = tab
    }
}
