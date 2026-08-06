import SwiftUI

struct SignInView: View {
    
        // MARK: - Environment
    @Environment(DIContainer.self) private var container
    
        // MARK: - Bindings
    @Binding var screen: AuthScreen
    
        // MARK: - State
    @Bindable var vm: AuthViewModel
    
        // MARK: - Focus
    @FocusState private var focusedField: Field?
    enum Field: Hashable { case email, password }
    
        // MARK: - Body
    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(spacing: Spacing.xxl) {
                    VStack(spacing: Spacing.md) {
                        
                        AppIcon(icon: "person.crop.circle.fill.badge.checkmark")
                        
                        Text("Welcome Back").font(.largeTitle.bold())
                        
                        Text("Sign in to continue your journey with Shadowing")
                            .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    
                    VStack(spacing: Spacing.lg) {
                        AppInputField(
                            icon: "envelope",
                            title: "Email",
                            text: $vm.email,
                            keyboardType: .emailAddress,
                            textContentType: .emailAddress,
                            isFocused: focusedField == .email
                        )
                        .focused($focusedField, equals: .email)
                        
                        AppInputField(
                            icon: "lock",
                            title: "Password",
                            text: $vm.password,
                            isSecure: true,
                            isFocused: focusedField == .password
                        )
                        .focused($focusedField, equals: .password)
                    }
                    .padding(.horizontal)
                    
                    ActionButton(title: "Sign In", systemImage: "arrow.right", tint: .blue, isLoading: vm.isLoading, action: {
                        Task { await submit() }
                    })
                    .disabled(vm.isLoading)
                    
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
            .navigationBarHidden(true)
        }
    }
    
        // MARK: - Private Methods
    private func submit() async {
        guard await vm.signIn() else { return }
        container.setAppState(vm.isAdmin ? .admin : .main)
        container.relaunchRoot()
    }
}
