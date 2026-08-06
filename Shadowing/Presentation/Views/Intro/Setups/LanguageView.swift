import SwiftUI

struct LanguageSetupView: View {
    @Bindable var vm: SettingsViewModel
    
    var body: some View {
        ZStack {
            AppBackground()
            
            VStack(spacing: Spacing.xxl) {
                
                    // MARK: - Header
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
                
                    // MARK: - Language Options
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
