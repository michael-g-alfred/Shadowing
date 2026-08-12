import SwiftUI

    // MARK: - Container

struct SignUpView: View {
    
        // MARK: Environment
    @Environment(DIContainer.self) private var container
    
        // MARK: Bindings
    @Binding var screen: AuthScreen
    
        // MARK: State
    @Bindable var vm: AuthViewModel
    @State private var showSpecialtiesSheet = false
    
        // MARK: Focus
    @FocusState private var focusedField: SignUpField?
    
        // MARK: Body
    var body: some View {
        ScreenContainer {
            ScrollView {
                VStack(spacing: Spacing.xxl) {
                    SignUpHeader()
                    SignUpFormFields(
                        vm: vm,
                        focusedField: $focusedField,
                        showSpecialtiesSheet: $showSpecialtiesSheet
                    )
                    .padding(.horizontal)
                    SignUpSubmitButton(vm: vm) {
                        Task { await submit() }
                    }
                    SignUpSwitchToSignInButton(screen: $screen)
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
    
        // MARK: Private Methods
    private func submit() async {
        guard await vm.signUp() else { return }
        container.setAppState(.main)
        container.relaunchRoot()
    }
}

    // MARK: - Focus

enum SignUpField: Hashable {
    case name, email, password, confirm
    case nationalID
    case phoneCode, phoneNumber
    case country, governorate
}

    // MARK: - Header

private struct SignUpHeader: View {
    var body: some View {
        VStack(spacing: Spacing.md) {
            AppIcon(icon: "person.crop.circle.fill.badge.plus")
            
            Text("Create Account").font(.largeTitle.bold())
            
            Text("Join us today and start your experience")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        .padding(.top, 40)
    }
}

    // MARK: - Form Fields

private struct SignUpFormFields: View {
    @Bindable var vm: AuthViewModel
    var focusedField: FocusState<SignUpField?>.Binding
    @Binding var showSpecialtiesSheet: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            AppInputField(
                icon: "person",
                title: "Full Name",
                text: $vm.displayName,
                textContentType: .name,
                isFocused: focusedField.wrappedValue == .name
            )
            .focused(focusedField, equals: .name)
            
            AppInputField(
                icon: "envelope",
                title: "Email Address",
                text: $vm.email,
                keyboardType: .emailAddress,
                textContentType: .emailAddress,
                isFocused: focusedField.wrappedValue == .email
            )
            .focused(focusedField, equals: .email)
            
            NationalIDView(nationalID: $vm.nationalID, focusedField: focusedField)
            
            PhoneNumberField(vm: vm, focusedField: focusedField)
            
            SignUpLocationPickers(vm: vm, focusedField: focusedField)
            
            AppInputField(
                icon: "lock",
                title: "Password",
                text: $vm.password,
                isSecure: true,
                isFocused: focusedField.wrappedValue == .password
            )
            .focused(focusedField, equals: .password)
            
            AppInputField(
                icon: "lock.shield",
                title: "Confirm Password",
                text: $vm.confirmPassword,
                iconColor: vm.confirmPassword.isEmpty
                ? .blue
                : (vm.password == vm.confirmPassword ? .green : .red),
                isSecure: true,
                isFocused: focusedField.wrappedValue == .confirm
            )
            .focused(focusedField, equals: .confirm)
            
            SignUpSpecialtiesButton(vm: vm, showSpecialtiesSheet: $showSpecialtiesSheet)
        }
    }
}

    // MARK: - Phone Number

private struct PhoneNumberField: View {
    @Bindable var vm: AuthViewModel
    var focusedField: FocusState<SignUpField?>.Binding
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            AppPickerField(
                icon: "flag",
                placeholder: "Code",
                selection: $vm.selectedPhoneCountry,
                options: vm.availablePhoneCodes,
                labelProvider: { "\($0.flag) \($0.dialCode)" },
                isFocused: focusedField.wrappedValue == .phoneCode
            )
            .focused(focusedField, equals: .phoneCode)
            .fixedSize(horizontal: true, vertical: false)
            
            AppInputField(
                icon: "phone",
                title: "Phone Number",
                text: $vm.phoneNumber,
                keyboardType: .numberPad,
                textContentType: .telephoneNumber,
                isFocused: focusedField.wrappedValue == .phoneNumber
            )
            .focused(focusedField, equals: .phoneNumber)
            .frame(maxWidth: .infinity)
        }
    }
}

    // MARK: - Location Pickers

private struct SignUpLocationPickers: View {
    @Bindable var vm: AuthViewModel
    var focusedField: FocusState<SignUpField?>.Binding
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            AppPickerField(
                icon: "globe",
                placeholder: "Select Country",
                selection: $vm.selectedCountry,
                options: vm.availableCountries,
                labelProvider: { $0.label },
                isFocused: focusedField.wrappedValue == .country
            )
            .focused(focusedField, equals: .country)
            
            AppPickerField(
                icon: "mappin.and.ellipse",
                placeholder: "Select Governorate",
                selection: $vm.selectedGovernorate,
                options: vm.availableGovernorates,
                labelProvider: { $0.label },
                isFocused: focusedField.wrappedValue == .governorate
            )
            .focused(focusedField, equals: .governorate)
            .disabled(vm.selectedCountry == nil)
            .opacity(vm.selectedCountry == nil ? 0.5 : 1)
        }
    }
}

    // MARK: - Specialties Entry Point

private struct SignUpSpecialtiesButton: View {
    let vm: AuthViewModel
    @Binding var showSpecialtiesSheet: Bool
    
    var body: some View {
        Button {
            showSpecialtiesSheet = true
        } label: {
            Label(vm.selectedSpecialties.isEmpty
                  ? "Specialties & Bio (optional)"
                  : "\(vm.selectedSpecialties.count) specialties selected", systemImage: "briefcase.fill")
            .font(.footnote)
            .underline()
            .foregroundStyle(.accent)
            .padding(.horizontal)
            .padding(.horizontal)
        }
    }
}

    // MARK: - Submit

private struct SignUpSubmitButton: View {
    let vm: AuthViewModel
    let action: () -> Void
    
    var body: some View {
        ActionButton(title: "Create Account", systemImage: "plus.circle", tint: .blue, isLoading: vm.isLoading, action: action)
            .disabled(!vm.isSignUpFormValid || vm.isLoading)
    }
}

    // MARK: - Switch Screen

private struct SignUpSwitchToSignInButton: View {
    @Binding var screen: AuthScreen
    
    var body: some View {
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
