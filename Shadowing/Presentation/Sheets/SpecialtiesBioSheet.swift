import SwiftUI

struct SpecialtiesBioSheet: View {
    @Bindable var vm: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    NavigationLink {
                        SpecialtiesPickerView(vm: vm)
                    } label: {
                        HStack {
                            Text("Specialties")
                            Spacer()
                            Text(summaryText)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                } footer: {
                    Text("Requesters posting a matching task will be able to find you.")
                }
                
                Section("About You") {
                    TextEditor(text: $vm.bio)
                        .frame(minHeight: 120)
                }
            }
            .navigationTitle("Specialties & Bio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private var summaryText: String {
        vm.selectedSpecialties.isEmpty
        ? "Select"
        : vm.selectedSpecialties
            .map(\.label)
            .sorted()
            .joined(separator: ", ")
    }
}

    // MARK: - Specialties Picker

private struct SpecialtiesPickerView: View {
    @Bindable var vm: AuthViewModel
    private let maxSpecialties = 5
    
    var body: some View {
        List(vm.availableSpecialties) { specialty in
            Button {
                toggle(specialty)
            } label: {
                HStack {
                    Label(specialty.label, systemImage: specialty.icon)
                        .foregroundStyle(.primary)
                    Spacer()
                    if vm.selectedSpecialties.contains(specialty) {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.accent)
                            .fontWeight(.semibold)
                    }
                }
            }
            .disabled(
                !vm.selectedSpecialties.contains(specialty)
                && vm.selectedSpecialties.count >= maxSpecialties
            )
        }
        .navigationTitle("Select Specialties")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Text("Pick up to \(maxSpecialties)")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(.bar)
        }
    }
    
    private func toggle(_ specialty: TaskServiceLookup) {
        if vm.selectedSpecialties.contains(specialty) {
            vm.selectedSpecialties.remove(specialty)
        } else if vm.selectedSpecialties.count < maxSpecialties {
            vm.selectedSpecialties.insert(specialty)
        }
    }
}
