import Observation

@MainActor
@Observable
final class HomeViewModel {
    
    var selectedMode: UserMode = .requester
    
    init() {}
    
    func select(_ mode: UserMode) {
        selectedMode = mode
    }
    
    func toggleMode() {
        selectedMode = (selectedMode == .requester)
        ? .executor
        : .requester
    }
}
