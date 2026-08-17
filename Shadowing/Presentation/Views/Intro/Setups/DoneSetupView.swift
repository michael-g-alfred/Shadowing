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
    }
}

    // MARK: - Header

private struct DoneSetupHeader: View {
    let vm: SettingsViewModel
    
    var body: some View {
        SetupHeaderView(
            icon: "checkmark.circle.fill",
            title: vm.currentLanguage.doneTitle,
            subtitle: vm.currentLanguage.doneMessage
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
