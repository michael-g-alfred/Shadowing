import SwiftUI
import MGOnboardingKit

struct OnboardingView: View {
    
    var vm: OnboardingViewModel
    @Environment(DIContainer.self) private var container
    
    init(vm: OnboardingViewModel) {
        self.vm = vm
    }
    
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
