import SwiftUI

struct SignUpView: View {
    
    // MARK: - Environment
    @Environment(DIContainer.self) private var container
    
    // MARK: - Bindings
    @Binding var screen: AuthScreen
    
    // MARK: - State
    @State private var vm: SignUpViewModel
    
    // MARK: - Focus
    @FocusState private var focusedField: Field?
    enum Field: Hashable {
        case name, email, password, confirm
        case nationalID(Int)
    }
    
    // MARK: - Init
    init(screen: Binding<AuthScreen>, vm: SignUpViewModel) {
        _screen = screen
        _vm = State(initialValue: vm)
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.fill.badge.plus")
                            .symbolRenderingMode(.hierarchical).font(.system(size: 80)).foregroundStyle(.blue)
                        Text("Create Account").font(.largeTitle.bold())
                        Text("Join us today and start your experience")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    .padding(.top, 40)

                    VStack(spacing: 16) {
                        customTextField(title: "Full Name", text: $vm.displayName, icon: "person", type: .name)
                            .focused($focusedField, equals: .name)
                        customTextField(title: "Email Address", text: $vm.email, icon: "envelope", type: .emailAddress)
                            .focused($focusedField, equals: .email)
                        NationalIDView(nationalIDCells: $vm.nationalIDCells, focusedField: $focusedField)
                        customSecureField(title: "Password", text: $vm.password, icon: "lock")
                            .focused($focusedField, equals: .password)
                        customSecureField(
                            title: "Confirm Password", text: $vm.confirmPassword, icon: "lock.shield",
                            iconColor: vm.confirmPassword.isEmpty
                                ? .blue
                                : (vm.password == vm.confirmPassword ? .green : .red)
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
                    .disabled(!vm.isFormValid)

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
        guard await vm.submit() else { return }
        container.setAppState(.main)
        container.relaunchRoot()
    }
}
