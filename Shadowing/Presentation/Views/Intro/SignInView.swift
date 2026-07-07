import SwiftUI

struct SignInView: View {
    
    @Binding var screen:   AuthScreen
    @State private var vm: SignInViewModel
    @Environment(DIContainer.self) private var container

    @FocusState private var focusedField: Field?
    enum Field: Hashable { case email, password }

    init(screen: Binding<AuthScreen>, vm: SignInViewModel) {
        _screen = screen
        _vm = State(initialValue: vm)
    }

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.fill.badge.checkmark")
                            .symbolRenderingMode(.hierarchical).font(.system(size: 80)).foregroundStyle(.blue)
                        Text("Welcome Back").font(.largeTitle.bold())
                        Text("Sign in to continue your journey with Shadowing")
                            .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)

                    VStack(spacing: 16) {
                        customTextField(title: "Email", text: $vm.email, icon: "envelope", type: .emailAddress)
                            .focused($focusedField, equals: .email)
                        customSecureField(title: "Password", text: $vm.password, icon: "lock")
                            .focused($focusedField, equals: .password)
                    }
                    .padding(.horizontal)

                    if let errorMessage = vm.errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote).foregroundStyle(.red)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    ActionButton(title: "Sign In", systemImage: "arrow.right", tint: .blue, isLoading: vm.isLoading, action: {
                        Task { await submit() }
                    })
                    .disabled(!vm.isFormValid)

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

    private func submit() async {
        guard await vm.submit() else { return }
        container.setAppState(vm.isAdmin ? .admin : .main)
        container.relaunchRoot()
    }
}
