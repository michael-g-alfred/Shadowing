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
        .environment(\.layoutDirection, vm.currentLanguage.layoutDirection)
        .environment(\.locale, vm.currentLanguage.locale)
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
            title: vm.greetings[vm.currentGreetingIndex],
            subtitle: vm.currentLanguage == .arabic
                ? "اختر لغتك المفضلـة للمتابعة"
                : "Choose your preferred language to continue"
        )
        .id(vm.currentGreetingIndex)
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
                    isSelected: vm.currentLanguage == language
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

// MARK: - Previews

#Preview("Language Setup - Light") {
    LanguageSetupView(
        vm: SettingsViewModel(locationService: CLLocationServiceImpl(), languageManager: .shared, appearanceManager: .shared)
    )
}

#Preview("Language Setup - Dark") {
    LanguageSetupView(
        vm: SettingsViewModel(locationService: CLLocationServiceImpl(), languageManager: .shared, appearanceManager: .shared)
    )
    .preferredColorScheme(.dark)
}
