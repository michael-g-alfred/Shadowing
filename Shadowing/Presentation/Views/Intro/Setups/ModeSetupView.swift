import SwiftUI

struct ModeSetupView: View {
    @Bindable var vm: SettingsViewModel
    
    var body: some View {
        ZStack {
            AppBackground()
            
            VStack(spacing: Spacing.xxl) {
                
                    // MARK: - Header
                SetupHeaderView(
                    icon: vm.currentMode.icon,
                    title: vm.currentLanguage == .arabic ? "اختار مظهر التطبيق" : "Choose your appearance",
                    subtitle: vm.currentLanguage == .arabic ? "اختار الوضع اللي مريحلك" : "Pick the look that feels right"
                )
                .padding(.top, Spacing.xl)
                
                    // MARK: - Mode Options
                VStack(spacing: Spacing.sm) {
                    ForEach(AppColorScheme.allCases) { mode in
                        SetupOptionCard(
                            icon: mode.icon,
                            title: mode.title,
                            isSelected: vm.currentMode == mode
                        ) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                vm.setMode(mode)
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
        .preferredColorScheme(vm.currentMode.colorScheme)
    }
}

    // MARK: - Previews
#Preview("Mode Setup - Light") {
    ModeSetupView(
        vm: SettingsViewModel(locationService: CLLocationServiceImpl(), languageManager: .shared, appearanceManager: .shared)
    )
}

#Preview("Mode Setup - Dark") {
    ModeSetupView(
        vm: SettingsViewModel(locationService: CLLocationServiceImpl(), languageManager: .shared, appearanceManager: .shared)
    )
    .preferredColorScheme(.dark)
}
