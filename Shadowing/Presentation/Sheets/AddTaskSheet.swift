import SwiftUI

    // MARK: - Container

struct AddTaskSheet: View {
    
        // MARK: Environment
    @Environment(\.dismiss) private var dismiss
    
        // MARK: State
    @State private var vm: AddTaskSheetViewModel
    
        // MARK: Init
    init(vm: AddTaskSheetViewModel) {
        _vm = State(initialValue: vm)
    }
    
        // MARK: Body
    var body: some View {
        NavigationStack {
            AddTaskForm(vm: vm)
                .navigationTitle("New Task")
                .disabled(vm.isLoading)
                .task {
                    await vm.loadLookupsIfNeeded()
                }
                .onChange(of: vm.didPostSuccessfully) { _, success in
                    if success { dismiss() }
                }
                .alert("Please fix the following", isPresented: $vm.showErrorsAlert) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(vm.validationAlertMessage)
                }
                .toolbar {
                    AddTaskToolbar(vm: vm, dismiss: dismiss)
                }
        }
    }
}

    // MARK: - Form

private struct AddTaskForm: View {
    @Bindable var vm: AddTaskSheetViewModel
    
    var body: some View {
        Form {
            Section("Task Info") {
                TextField("Title", text: $vm.title)
                TextField("Description", text: $vm.description, axis: .vertical)
                    .lineLimit(3...6)
            }
            
            Section("Budget") {
                BudgetRow(vm: vm)
            }
            
            Section("Service Type") {
                ServiceTypePicker(vm: vm)
                
                if !vm.suggestedSpecialists.isEmpty {
                    SpecialistsEntryPointButton(vm: vm)
                        .listRowSeparator(.hidden)
                }
            }
            
            Section("Priority") {
                PriorityPicker(vm: vm)
            }
            
            Section("Location") {
                TextField("Address", text: $vm.address)
            }
            
            Section {
                TimingPicker(vm: vm)
            } header: {
                Text("Task Timing")
            }
            
            Section {
                PreferredTimeOfDaySection(vm: vm)
            } header: {
                if vm.isPreferredTimeOfDay {
                    Text("Preferred Time")
                }
            }
            
            if let error = vm.errorMessage {
                Section {
                    Text(error).foregroundStyle(.red).font(.caption)
                }
            }
        }
    }
}

    // MARK: - Budget

private struct BudgetRow: View {
    @Bindable var vm: AddTaskSheetViewModel
    
    var body: some View {
        HStack(alignment: .center) {
            TextField("Amount", value: $vm.budget, format: .number)
                .keyboardType(.decimalPad)
            
            if vm.availableCurrencies.isEmpty {
                ProgressView()
            } else {
                Picker("Currency", selection: $vm.selectedCurrency) {
                    ForEach(vm.availableCurrencies) { currency in
                        Text(currency.code).tag(currency as CurrencyLookup?)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .fixedSize()
            }
        }
    }
}

    // MARK: - Service Type

private struct ServiceTypePicker: View {
    @Bindable var vm: AddTaskSheetViewModel
    
    var body: some View {
        if vm.availableServices.isEmpty {
            ProgressView()
                .listRowSeparator(.hidden)
        } else {
            Picker("Service Type", selection: $vm.selectedService) {
                
                ForEach(vm.availableServices) { service in
                    Label(service.label, systemImage: service.icon)
                        .tag(service as TaskServiceLookup?)
                }
            }
            .pickerStyle(.navigationLink)
            .listRowSeparator(.hidden)
        }
    }
}

private struct SpecialistsEntryPointButton: View {
    let vm: AddTaskSheetViewModel
    
    var body: some View {
        NavigationLink {
            SpecialistsSelectionView(
                vm: vm.makeSpecialistsSelectionViewModel(),
                onConfirm: { vm.updateSelectedSpecialists($0) }
            )
        } label: {
            HStack {
                Image(systemName: "person.fill")
                Text("\(vm.suggestedSpecialists.count) available in this specialty")
                Spacer()
                if vm.isLoadingSpecialists {
                    ProgressView()
                }
            }
            .font(.subheadline)
            .foregroundStyle(.accent)
        }
    }
}

    // MARK: - Priority

private struct PriorityPicker: View {
    @Bindable var vm: AddTaskSheetViewModel
    
    var body: some View {
        if vm.availablePriorities.isEmpty {
            ProgressView()
        } else {
            Picker("Priority", selection: $vm.selectedPriority) {
                ForEach(vm.availablePriorities) { p in
                    Label(p.label, systemImage: p.icon)
                        .foregroundStyle(Color(lookupName: p.color))
                        .tint(Color(lookupName: p.color))
                        .tag(p as PriorityLookup?)
                }
            }
            .tint(vm.selectedPriority.map { Color(lookupName: $0.color) } ?? .gray)
            .pickerStyle(.segmented)
        }
    }
}

    // MARK: - Timing

private struct TimingPicker: View {
    @Bindable var vm: AddTaskSheetViewModel
    
    var body: some View {
        Picker("Timing", selection: $vm.timing) {
            ForEach(TaskTiming.allCases) { t in
                Text(t.title).tag(t)
            }
        }
        .pickerStyle(.segmented)
        
        if vm.timing == .scheduled {
            DatePicker("Schedule", selection: $vm.scheduledDate, in: Date()...)
        }
    }
}

    // MARK: - Preferred Time Of Day

private struct PreferredTimeOfDaySection: View {
    @Bindable var vm: AddTaskSheetViewModel
    
    var body: some View {
        Toggle(isOn: Binding(
            get: { vm.isPreferredTimeOfDay },
            set: { _ in vm.preferredTimeOfDayToggle() }
        )) {
            Label("I need a certain time of day", systemImage: "clock.badge.checkmark.fill")
        }
        
        if vm.isPreferredTimeOfDay {
            TimeOfDaySelectionView(
                availableTimesOfDay: vm.availableTimesOfDay,
                selection: $vm.preferredTimeOfDay
            )
            .listRowInsets(EdgeInsets())
        }
    }
}

    // MARK: - Toolbar

private struct AddTaskToolbar: ToolbarContent {
    let vm: AddTaskSheetViewModel
    let dismiss: DismissAction
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("Cancel") {
                dismiss()
            }
        }
        
        ToolbarSpacer(.fixed, placement: .topBarLeading)
        
        ToolbarItem(placement: .topBarLeading) {
            if !vm.isFormValid {
                Button {
                    vm.showErrorsAlert = true
                } label: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
            }
        }
        
        ToolbarItem(placement: .confirmationAction) {
            if vm.isLoading {
                ProgressView()
            } else {
                Button("Post") {
                    vm.attemptSubmit()
                }
                .buttonSizing(.fitted)
                .buttonStyle(.glassProminent)
                .disabled(!vm.isFormValid)
            }
        }
    }
}

    // MARK: - Specialists Selection

private struct SpecialistsSelectionView: View {
    
        // MARK: Environment
    @Environment(DIContainer.self) private var container
    @Environment(\.dismiss) private var dismiss
    
        // MARK: State
    @State var vm: SpecialistsSelectionViewModel
    let onConfirm: (Set<String>) -> Void
    
        // MARK: Body
    var body: some View {
        List(vm.specialists, selection: $vm.selectedIDs) { user in
            NavigationLink {
                container.makeUserView(userId: user.id)
            } label: {
                SpecialistRow(user: user)
            }
        }
        .navigationTitle("Available Specialists")
        .toolbar {
            SpecialistsSelectionToolbar(vm: vm, onConfirm: onConfirm, dismiss: dismiss)
        }
    }
}

private struct SpecialistRow: View {
    let user: UserSummaryModel
    
    var body: some View {
        HStack {
            AvatarView(
                profile: user,
                nameLayout: .horizontal,
                subtitle: user.bio
            )
            
            Spacer()
            
            CompletedTaskRatingLabel(
                rating: user.rating,
                completedTasks: user.completedTasks
            )
        }
        .contentShape(Rectangle())
    }
}

private struct SpecialistsSelectionToolbar: ToolbarContent {
    let vm: SpecialistsSelectionViewModel
    let onConfirm: (Set<String>) -> Void
    let dismiss: DismissAction
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            EditButton()
        }
        
        if vm.hasSelection {
            ToolbarItem(placement: .bottomBar) {
                Button {
                    onConfirm(vm.selectedIDs)
                    dismiss()
                } label: {
                    Text("Invite (\(vm.selectionCount))")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
            }
        }
    }
}
