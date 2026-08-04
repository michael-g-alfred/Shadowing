import SwiftUI

struct SetupFlowView: View {
    
        // MARK: - Environment
    @Environment(DIContainer.self) private var container
    
    private enum Step: Int, CaseIterable {
        case language
        case mode
        case done
    }
    
    @State private var step: Step = .language
    var vm: SettingsViewModel
    var onFinished: () -> Void
    
    var body: some View {
        TabView(selection: $step) {
            container.makeLanguageSetupView()
                .tag(Step.language)
            container.makeModeSetupView()
                .tag(Step.mode)
            container.makeDoneSetupView(onFinished: onFinished)
                .tag(Step.done)
            
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .ignoresSafeArea()
        .animation(.easeInOut, value: step)
    }
}
