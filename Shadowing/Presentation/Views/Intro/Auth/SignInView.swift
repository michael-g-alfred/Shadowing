import SwiftUI

// MARK: - Container

struct SignInView: View {

    // MARK: Environment
    @Environment(DIContainer.self) private var container

    // MARK: Bindings
    @Binding var screen: AuthScreen

    // MARK: State
    @Bindable var vm: AuthViewModel

    // MARK: Focus
    @FocusState private var focusedField: SignInField?

    // MARK: Body
    var body: some View {
        ScreenContainer {
            ScrollView {
                VStack(spacing: Spacing.xxl) {
                    SignInHeader()
                    SignInFormFields(vm: vm, focusedField: $focusedField)
                        .padding(.horizontal)
                    SignInSubmitButton(vm: vm) {
                        Task { await submit() }
                    }
                    SignInSwitchToSignUpButton(screen: $screen)
                }
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: Private Methods
    private func submit() async {
        guard await vm.signIn() else { return }
        container.setAppState(vm.isAdmin ? .admin : .main)
        container.relaunchRoot()
    }
}

// MARK: - Focus

enum SignInField: Hashable {
    case email, password
}

// MARK: - Header

private struct SignInHeader: View {
    var body: some View {
        VStack(spacing: Spacing.md) {
            AppIcon(icon: "person.crop.circle.fill.badge.checkmark")

            Text("Welcome Back").font(.largeTitle.bold())

            Text("Sign in to continue your journey with Shadowing")
                .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .padding(.top, 40)
    }
}

// MARK: - Form Fields

private struct SignInFormFields: View {
    @Bindable var vm: AuthViewModel
    var focusedField: FocusState<SignInField?>.Binding

    var body: some View {
        VStack(spacing: Spacing.lg) {
            AppInputField(
                icon: "envelope",
                title: "Email",
                text: $vm.email,
                keyboardType: .emailAddress,
                textContentType: .emailAddress,
                isFocused: focusedField.wrappedValue == .email
            )
            .focused(focusedField, equals: .email)

            AppInputField(
                icon: "lock",
                title: "Password",
                text: $vm.password,
                isSecure: true,
                isFocused: focusedField.wrappedValue == .password
            )
            .focused(focusedField, equals: .password)
        }
    }
}

// MARK: - Submit

private struct SignInSubmitButton: View {
    let vm: AuthViewModel
    let action: () -> Void

    var body: some View {
        ActionButton(title: "Sign In", systemImage: "arrow.right.circle", tint: .blue, isLoading: vm.isLoading, action: action)
            .disabled(vm.isLoading)
    }
}

// MARK: - Switch Screen

private struct SignInSwitchToSignUpButton: View {
    @Binding var screen: AuthScreen

    var body: some View {
        Button {
            withAnimation(.spring()) { screen = .signUp }
        } label: {
            HStack {
                Text("Don't have an account?").foregroundStyle(.blue.opacity(0.75))
                Text("Sign Up").fontWeight(.bold).foregroundStyle(.blue)
            }
            .font(.footnote)
        }
        .padding(.bottom)
    }
}
