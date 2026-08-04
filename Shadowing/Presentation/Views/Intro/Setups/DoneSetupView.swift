import SwiftUI

struct DoneSetupView: View {
    @Bindable var vm: SettingsViewModel
    var onFinished: () -> Void

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: Spacing.xxl) {

                    // MARK: - Header
                SetupHeaderView(
                    icon: "checkmark.circle.fill",
                    title: vm.currentLanguage == .arabic ? "كل حاجة جاهزة!" : "All set!",
                    subtitle: vm.currentLanguage == .arabic
                        ? "تقدر تغيّر اللغة والمظهر في أي وقت من الإعدادات"
                        : "You can change the language and appearance anytime from Settings"
                )
                .padding(.top, Spacing.xl)
                
                Spacer()
                
                    // MARK: - Finish Button
                
                ActionButton(title: "Get Started", systemImage: "checkmark.circle", tint: .accent) {
                    onFinished()
                }
                .padding(.horizontal)
                .padding(.bottom, Spacing.xl)
            }
        }
        .environment(\.layoutDirection, vm.currentLanguage.layoutDirection)
        .environment(\.locale, vm.currentLanguage.locale)
        .background(Color(.systemBackground).ignoresSafeArea())
        .preferredColorScheme(vm.currentMode.colorScheme)
    }
}

    // MARK: - Previews
#Preview("Done Setup - Light") {
    DoneSetupView(
        vm: SettingsViewModel(locationService: CLLocationServiceImpl(), languageManager: .shared),
        onFinished: {}
    )
}

#Preview("Done Setup - Dark") {
    DoneSetupView(
        vm: SettingsViewModel(locationService: CLLocationServiceImpl(), languageManager: .shared),
        onFinished: {}
    )
    .preferredColorScheme(.dark)
}
