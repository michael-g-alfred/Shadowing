import SwiftUI
import MGOnboardingKit

struct OnboardingView: View {
    
        // MARK: - Environment
    @Environment(DIContainer.self) private var container
    
        // MARK: - Properties
    var vm: OnboardingViewModel
    
        // MARK: - Init
    init(vm: OnboardingViewModel) {
        self.vm = vm
    }
    
        // MARK: - Body
    var body: some View {
        MGOnboardingKitMainView(
            items: vm.items,
            nextButtonTitle: "Next",
            lastButtonTitle: "Start Now"
        ) {
            container.setAppState(.auth)
            container.relaunchRoot()
        }
    }
}
