import SwiftUI

// MARK: - Container

struct DoneSetupView: View {
    @Bindable var vm: SettingsViewModel
    var onFinished: () -> Void

    var body: some View {
        ScreenContainer {
            VStack(spacing: Spacing.xxl) {
                DoneSetupHeader(vm: vm)
                Spacer()
                DoneSetupFinishButton(onFinished: onFinished)
            }
        }
        .environment(\.layoutDirection, vm.currentLanguage.layoutDirection)
        .environment(\.locale, vm.currentLanguage.locale)
        .preferredColorScheme(vm.currentMode.colorScheme)
    }
}

// MARK: - Header

private struct DoneSetupHeader: View {
    let vm: SettingsViewModel

    var body: some View {
        SetupHeaderView(
            icon: "checkmark.circle.fill",
            title: vm.currentLanguage == .arabic ? "كل حاجة جاهزة!" : "All set!",
            subtitle: vm.currentLanguage == .arabic
                ? "تقدر تغيّر اللغة والمظهر في أي وقت من الإعدادات"
                : "You can change the language and appearance anytime from Settings"
        )
        .padding(.top, Spacing.xl)
    }
}

// MARK: - Finish Button

private struct DoneSetupFinishButton: View {
    let onFinished: () -> Void

    var body: some View {
        ActionButton(title: "Get Started", systemImage: "checkmark.circle", tint: .accent) {
            onFinished()
        }
        .padding(.horizontal)
        .padding(.bottom, Spacing.xl)
    }
}

// MARK: - Previews

#Preview("Done Setup - Light") {
    DoneSetupView(
        vm: SettingsViewModel(locationService: LocationService(), languageManager: .shared, appearanceManager: .shared),
        onFinished: {}
    )
}

#Preview("Done Setup - Dark") {
    DoneSetupView(
        vm: SettingsViewModel(locationService: LocationService(), languageManager: .shared, appearanceManager: .shared),
        onFinished: {}
    )
    .preferredColorScheme(.dark)
}
