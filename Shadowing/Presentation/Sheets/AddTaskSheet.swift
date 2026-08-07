import SwiftUI

struct AddTaskSheet: View {

        // MARK: - Environment
    @Environment(\.dismiss) private var dismiss

        // MARK: - State
    @State private var vm: AddTaskSheetViewModel

        // MARK: - Init
    init(vm: AddTaskSheetViewModel) {
        _vm = State(initialValue: vm)
    }

        // MARK: - Body
    var body: some View {
        NavigationStack {
            Form {
                Section("Task Info") {
                    TextField("Title", text: $vm.title)
                    TextField("Description", text: $vm.description, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Budget") {
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

                Section("Service Type") {
                    if vm.availableServices.isEmpty {
                        ProgressView()
                    } else {
                        Picker("Service Type", selection: $vm.selectedService) {
                            ForEach(vm.availableServices) { service in
                                Label(service.label, systemImage: service.icon)
                                    .tag(service as TaskServiceLookup?)
                            }
                        }
                        .pickerStyle(.navigationLink)
                    }
                }

                Section("Priority") {
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

                Section("Location") {
                    TextField("Address", text: $vm.address)
                }

                Section {
                    Picker("Timing", selection: $vm.timing) {
                        ForEach(TaskTiming.allCases) { t in
                            Text(t.title).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)

                    if vm.timing == .scheduled {
                        DatePicker("Schedule", selection: $vm.scheduledDate, in: Date()...)
                    }
                } header: {
                    Text("Task Timing")
                }

                Section {
                    Toggle(isOn: Binding(
                        get: { vm.isPreferredTimeOfDay },
                        set: { _ in vm.preferredTimeOfDayToggle() }
                    )) {
                        Label("I need a certain time of day", systemImage: "clock.badge.checkmark")
                    }
                    
                    if vm.isPreferredTimeOfDay {
                        TimeOfDaySelectionView(
                            availableTimesOfDay: vm.availableTimesOfDay,
                            selection: $vm.preferredTimeOfDay
                        )
                        .listRowInsets(EdgeInsets())
                    }
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
            .navigationTitle("New Task")
            .disabled(vm.isLoading)
            .task {
                await vm.loadLookupsIfNeeded()
            }
            .onChange(of: vm.didPostSuccessfully) { _, success in
                if success { dismiss() }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    if vm.isLoading {
                        ProgressView()
                    } else {
                        Button("Post") {
                            Task {
                                await vm.submitTask()
                            }
                        }
                        .buttonSizing(.fitted)
                        .buttonStyle(.glassProminent)
                        .disabled(!vm.isValid)
                    }
                }
            }
        }
    }
}
