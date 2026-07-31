import SwiftUI

struct SignUpView: View {
    
        // MARK: - Environment
    @Environment(DIContainer.self) private var container
    
        // MARK: - Bindings
    @Binding var screen: AuthScreen
    
        // MARK: - State
    @Bindable var vm: AuthViewModel
    
        // MARK: - Focus
    @FocusState private var focusedField: Field?
    enum Field: Hashable {
        case name, email, password, confirm
        case nationalID
    }
    
        // MARK: - Body
    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(spacing: Spacing.xxl) {
                    VStack(spacing: Spacing.md) {
                        Image(systemName: "person.crop.circle.fill.badge.plus")
                            .symbolRenderingMode(.hierarchical).font(.system(size: 80)).foregroundStyle(.blue)
                        Text("Create Account").font(.largeTitle.bold())
                        Text("Join us today and start your experience")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    .padding(.top, 40)
                    
                    VStack(spacing: Spacing.lg) {
                        AppInputField(
                            icon: "person",
                            title: "Full Name",
                            text: $vm.displayName,
                            textContentType: .name,
                            isFocused: focusedField == .name
                        )
                        .focused($focusedField, equals: .name)
                        
                        AppInputField(
                            icon: "envelope",
                            title: "Email Address",
                            text: $vm.email,
                            keyboardType: .emailAddress,
                            textContentType: .emailAddress,
                            isFocused: focusedField == .email
                        )
                        .focused($focusedField, equals: .email)
                        
                        NationalIDView(nationalID: $vm.nationalID, focusedField: $focusedField)
                        
                        AppInputField(
                            icon: "lock",
                            title: "Password",
                            text: $vm.password,
                            isSecure: true,
                            isFocused: focusedField == .password
                        )
                        .focused($focusedField, equals: .password)
                        
                        AppInputField(
                            icon: "lock.shield",
                            title: "Confirm Password",
                            text: $vm.confirmPassword,
                            iconColor: vm.confirmPassword.isEmpty
                            ? .blue
                            : (vm.password == vm.confirmPassword ? .green : .red),
                            isSecure: true,
                            isFocused: focusedField == .confirm
                        )
                        .focused($focusedField, equals: .confirm)
                    }
                    .padding(.horizontal)
                    
                    if let errorMessage = vm.errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote).foregroundStyle(.red).padding(.horizontal)
                    }
                    
                    ActionButton(title: "Create Account", systemImage: "plus", tint: .blue, isLoading: vm.isLoading) {
                        Task { await submit() }
                    }
                    .disabled(!vm.isSignUpFormValid)
                    
                    Button {
                        withAnimation(.spring()) { screen = .signIn }
                    } label: {
                        HStack {
                            Text("Already have an account?").foregroundStyle(.blue.opacity(0.75))
                            Text("Sign In").fontWeight(.bold).foregroundStyle(.blue)
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
        guard await vm.signUp() else { return }
        container.setAppState(.main)
        container.relaunchRoot()
    }
}
