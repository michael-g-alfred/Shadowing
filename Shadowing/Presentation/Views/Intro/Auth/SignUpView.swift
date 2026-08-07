import SwiftUI

struct SignUpView: View {
    
        // MARK: - Environment
    @Environment(DIContainer.self) private var container
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.locale) private var locale
    
        // MARK: - Bindings
    @Binding var screen: AuthScreen
    
        // MARK: - State
    @Bindable var vm: AuthViewModel
    @State private var showSpecialtiesSheet = false
    
        // MARK: - Focus
    @FocusState private var focusedField: Field?
    enum Field: Hashable {
        case name, email, password, confirm
        case nationalID
        case country, governorate
    }
    
        // MARK: - Body
    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(spacing: Spacing.xxl) {
                    VStack(spacing: Spacing.md) {
                        
                        AppIcon(icon: "person.crop.circle.fill.badge.plus")
                        
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
                        
                        countryAndGovernoratePickers
                        
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
                        
                        specialtiesAndBioButton
                    }
                    .padding(.horizontal)
                    
                    ActionButton(title: "Create Account", systemImage: "plus.circle", tint: .blue, isLoading: vm.isLoading) {
                        Task { await submit() }
                    }
                    .disabled(!vm.isSignUpFormValid || vm.isLoading)
                    
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
        .task {
            await vm.loadLookupsIfNeeded()
        }
        .sheet(isPresented: $showSpecialtiesSheet) {
            SpecialtiesBioSheet(vm: vm)
                .appSheetStyle()
        }
    }
    
        // MARK: - Private Methods
    private func submit() async {
        guard await vm.signUp() else { return }
        container.setAppState(.main)
        container.relaunchRoot()
    }
    
        // MARK: - Specialties & Bio Entry Point
    private var specialtiesAndBioButton: some View {
        Button {
            showSpecialtiesSheet = true
        } label: {
            HStack {
                Image(systemName: "briefcase.fill")
                Text(vm.selectedSpecialties.isEmpty
                     ? "Specialties & Bio (optional)"
                     : "\(vm.selectedSpecialties.count) specialties selected")
                Spacer()
                Image(systemName: "chevron.right")
            }
            .font(.subheadline)
            .foregroundStyle(.accent)
            .padding()
        }
    }
    
        // MARK: - Country / Governorate Pickers
    @ViewBuilder
    private var countryAndGovernoratePickers: some View {
        VStack(spacing: Spacing.lg) {
            
                // Country Picker
            AppPickerField(
                icon: "globe",
                placeholder: "Select Country",
                selection: $vm.selectedCountry,
                options: vm.availableCountries,
                labelProvider: { $0.label },
                isFocused: focusedField == .country
            )
            .focused($focusedField, equals: .country)
            
                // Governorate Picker
            AppPickerField(
                icon: "mappin.and.ellipse",
                placeholder: "Select Governorate",
                selection: $vm.selectedGovernorate,
                options: vm.availableGovernorates,
                labelProvider: { $0.label },
                isFocused: focusedField == .governorate
            )
            .focused($focusedField, equals: .governorate)
            .disabled(vm.selectedCountry == nil)
            .opacity(vm.selectedCountry == nil ? 0.5 : 1)
        }
    }
}
