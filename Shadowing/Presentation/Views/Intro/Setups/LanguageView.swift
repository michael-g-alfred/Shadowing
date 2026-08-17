import SwiftUI

    // MARK: - Container

struct LanguageSetupView: View {
    @Bindable var vm: SettingsViewModel
    
    var body: some View {
        ScreenContainer {
            VStack(spacing: Spacing.xxl) {
                LanguageSetupHeader(vm: vm)
                LanguageOptionsList(vm: vm)
                Spacer()
            }
        }
        .task {
            vm.startGreetingLoop()
        }
        .onDisappear {
            vm.stopGreetingLoop()
        }
    }
}

    // MARK: - Header

private struct LanguageSetupHeader: View {
    let vm: SettingsViewModel
    
    var body: some View {
        SetupHeaderView(
            icon: "globe",
            title: vm.currentGreeting,
            subtitle: vm.currentGreetingSubtitle
        )
        .id(vm.isLanguageSelectedByUser ? vm.currentLanguage.rawValue : "\(vm.currentGreetingIndex)")
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
        .padding(.top, Spacing.xl)
    }
}

    // MARK: - Options

private struct LanguageOptionsList: View {
    let vm: SettingsViewModel
    
    var body: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(AppLanguage.allCases) { language in
                SetupOptionCard(
                    icon: language == .arabic ? "text.justify.right" : "text.justify.left",
                    title: language.title,
                    isSelected: vm.isLanguageSelectedByUser && vm.currentLanguage == language
                ) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        vm.setLanguage(language)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}
