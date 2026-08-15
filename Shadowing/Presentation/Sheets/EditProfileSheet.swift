import SwiftUI

struct EditProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: EditProfileField?
    
    let vm: ProfileViewModel
    let lookupStore: LookupStore
    
    private let originalUser: UserModel
    
    @State private var displayName: String
    @State private var bio: String
    @State private var selectedPhoneCountry: PhoneLookup?
    @State private var phoneNumber: String
    @State private var selectedCountry: CountryLookup?
    @State private var selectedGovernorate: GovernorateLookup?
    @State private var selectedSpecialties: Set<TaskServiceLookup>
    
    init(user: UserModel, vm: ProfileViewModel, lookupStore: LookupStore) {
        self.originalUser = user
        self.vm = vm
        self.lookupStore = lookupStore
        _displayName = State(initialValue: user.displayName)
        _bio = State(initialValue: user.bio ?? "")
        _selectedPhoneCountry = State(initialValue: user.phoneCountryId.flatMap(lookupStore.phone(id:)))
        _phoneNumber = State(initialValue: user.phoneNumber ?? "")
        _selectedCountry = State(initialValue: user.countryId.flatMap(lookupStore.country(id:)))
        _selectedGovernorate = State(initialValue: user.governorateId.flatMap(lookupStore.governorate(id:)))
        
        let matchedSpecialties = lookupStore.services.filter { service in
            user.specialties.contains { $0.id == service.id }
        }
        _selectedSpecialties = State(initialValue: Set(matchedSpecialties))
    }
    
    private var availableGovernorates: [GovernorateLookup] {
        guard let countryId = selectedCountry?.id else { return [] }
        return lookupStore.governorates(for: countryId)
    }
    
    private var specialtiesSummary: String {
        selectedSpecialties.isEmpty
        ? "Select"
        : selectedSpecialties
            .map(\.label)
            .sorted()
            .joined(separator: ", ")
    }
    
    private var isSaveDisabled: Bool {
        vm.isSavingProfile || displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Display Name", text: $displayName)
                }
                
                Section("Phone Number") {
                    PhoneEditField(
                        selectedPhoneCountry: $selectedPhoneCountry,
                        phoneNumber: $phoneNumber,
                        availablePhoneCodes: lookupStore.phone,
                        focusedField: $focusedField
                    )
                }
                .listRowBackground(Color.clear)
                .listRowInsets(.all, 0)
                
                Section("About You") {
                    TextEditor(text: $bio)
                        .frame(minHeight: 120)
                }
                
                Section {
                    NavigationLink {
                        EditSpecialtiesPickerView(
                            available: lookupStore.services,
                            selected: $selectedSpecialties
                        )
                    } label: {
                        HStack {
                            Text("Specialties")
                            Spacer()
                            Text(specialtiesSummary)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                } footer: {
                    Text("Requesters posting a matching task will be able to find you.")
                }
                
                Section("Location") {
                    AppPickerField(
                        icon: "globe",
                        placeholder: "Select Country",
                        selection: $selectedCountry,
                        options: lookupStore.countries,
                        labelProvider: { $0.label }
                    )
                    .onChange(of: selectedCountry) { _, newCountry in
                            // Reset governorate if it no longer belongs to the
                            // newly selected country.
                        if let selectedGovernorate,
                           !lookupStore.governorates(for: newCountry?.id ?? -1).contains(selectedGovernorate) {
                            self.selectedGovernorate = nil
                        }
                    }
                    
                    AppPickerField(
                        icon: "mappin.and.ellipse",
                        placeholder: "Select Governorate",
                        selection: $selectedGovernorate,
                        options: availableGovernorates,
                        labelProvider: { $0.label }
                    )
                    .disabled(selectedCountry == nil)
                    .opacity(selectedCountry == nil ? 0.5 : 1)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(.all, 0)
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .task { await lookupStore.loadLookup() }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if vm.isSavingProfile {
                        ProgressView()
                    } else {
                        Button("Save") {
                            Task { await save() }
                        }
                        .disabled(isSaveDisabled)
                    }
                }
            }
        }
    }
    
        // MARK: - Actions

    private func save() async {
        var payload = EditProfilePayload()
        
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName != originalUser.displayName {
            payload.displayName = trimmedName
        }
        
        let trimmedBio = bio.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedBio != (originalUser.bio ?? "") {
            payload.bio = trimmedBio
        }
        
        if selectedPhoneCountry?.id != originalUser.phoneCountryId {
            payload.phoneCountryId = selectedPhoneCountry?.id
        }
        
        let trimmedPhoneNumber = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedPhoneNumber != (originalUser.phoneNumber ?? "") {
            payload.phoneNumber = trimmedPhoneNumber
        }
        
        if selectedCountry?.id != originalUser.countryId {
            payload.countryId = selectedCountry?.id
        }
        
        if selectedGovernorate?.id != originalUser.governorateId {
            payload.governorateId = selectedGovernorate?.id
        }
        
        let selectedSpecialtyIds = Set(selectedSpecialties.map(\.id))
        let originalSpecialtyIds = Set(originalUser.specialties.map(\.id))
        if selectedSpecialtyIds != originalSpecialtyIds {
            payload.specialtyIds = Array(selectedSpecialtyIds)
        }
        
        guard payload.hasChanges else {
            dismiss()
            return
        }
        
        if await vm.saveProfile(payload) {
            dismiss()
        }
    }
}

    // MARK: - Focus

private enum EditProfileField: Hashable {
    case phoneCode, phoneNumber
}

    // MARK: - Phone Number

private struct PhoneEditField: View {
    @Binding var selectedPhoneCountry: PhoneLookup?
    @Binding var phoneNumber: String
    let availablePhoneCodes: [PhoneLookup]
    var focusedField: FocusState<EditProfileField?>.Binding
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            AppPickerField(
                icon: "flag",
                placeholder: "Code",
                selection: $selectedPhoneCountry,
                options: availablePhoneCodes,
                labelProvider: { "\($0.flag) \($0.dialCode)" },
                isFocused: focusedField.wrappedValue == .phoneCode
            )
            .focused(focusedField, equals: .phoneCode)
            .fixedSize(horizontal: true, vertical: false)
            
            AppInputField(
                icon: "phone",
                title: "Phone Number",
                text: $phoneNumber,
                keyboardType: .numberPad,
                textContentType: .telephoneNumber,
                isFocused: focusedField.wrappedValue == .phoneNumber
            )
            .focused(focusedField, equals: .phoneNumber)
            .frame(maxWidth: .infinity)
        }
    }
}

    // MARK: - Specialties Picker

private struct EditSpecialtiesPickerView: View {
    let available: [TaskServiceLookup]
    @Binding var selected: Set<TaskServiceLookup>
    private let maxSpecialties = 5
    
    var body: some View {
        List(available) { specialty in
            Button {
                toggle(specialty)
            } label: {
                HStack {
                    Label(specialty.label, systemImage: specialty.icon)
                        .foregroundStyle(.primary)
                    Spacer()
                    if selected.contains(specialty) {
                        Image(systemName: "checkmark")
                            .imageScale(.medium)
                            .bold()
                            .foregroundStyle(.accent)
                    }
                }
            }
            .disabled(
                !selected.contains(specialty)
                && selected.count >= maxSpecialties
            )
        }
        .navigationTitle("Select Specialties")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Text("Pick (\(selected.count)/\(maxSpecialties))")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.vertical, Spacing.sm)
                .frame(maxWidth: .infinity)
                .background(.bar)
        }
    }
    
    private func toggle(_ specialty: TaskServiceLookup) {
        if selected.contains(specialty) {
            selected.remove(specialty)
        } else if selected.count < maxSpecialties {
            selected.insert(specialty)
        }
    }
}

    // MARK: - EditProfilePayload + hasChanges

private extension EditProfilePayload {
    var hasChanges: Bool {
        displayName != nil
        || bio != nil
        || countryId != nil
        || governorateId != nil
        || phoneCountryId != nil
        || phoneNumber != nil
        || specialtyIds != nil
    }
}
