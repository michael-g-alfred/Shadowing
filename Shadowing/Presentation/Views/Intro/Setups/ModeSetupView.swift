import SwiftUI

    // MARK: - Container

struct ModeSetupView: View {
    @Bindable var vm: SettingsViewModel
    
    var body: some View {
        ScreenContainer {
            VStack(spacing: Spacing.xxl) {
                ModeSetupHeader(vm: vm)
                ModeOptionsList(vm: vm)
                Spacer()
            }
        }
    }
}

    // MARK: - Header

private struct ModeSetupHeader: View {
    let vm: SettingsViewModel
    
    var body: some View {
        SetupHeaderView(
            icon: vm.currentMode.icon,
            title: vm.currentLanguage.appearanceTitle,
            subtitle: vm.currentLanguage.appearanceMessage
        )
        .padding(.top, Spacing.xl)
    }
}

    // MARK: - Options

private struct ModeOptionsList: View {
    let vm: SettingsViewModel
    
    var body: some View {
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
    }
}
