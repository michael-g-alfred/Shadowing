import SwiftUI

struct AppliedSheet: View {
    
        // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    
        // MARK: - Properties
    var vm: ExecutorViewModel
    
    private var task: TaskModel? { vm.selectedTaskForApply }
    
        // MARK: - State
    @State private var proposedBudget: Double = 0
    
        // MARK: - Body
    var body: some View {
        NavigationStack {
            Group {
                if vm.isConfirmingApply {
                    confirmStep
                } else {
                    editStep
                }
            }
            .navigationTitle(vm.isConfirmingApply ? "Confirm Application" : "Apply to Task")
            .navigationBarTitleDisplayMode(.inline)
            .disabled(vm.isApplying)
            .overlay {
                if vm.isApplying {
                    ProgressView("Submitting…")
                        .padding()
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: CornerRadius.md))
                }
            }
            .onAppear {
                if let task { proposedBudget = task.budget }
            }
            .toolbar {
                if vm.isConfirmingApply {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Back") {
                            vm.cancelApply()
                        }
                        .disabled(vm.isApplying)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Confirm") {
                            Task { await vm.confirmApply() }
                        }
                        .buttonStyle(.glassProminent)
                        .disabled(vm.isApplying)
                    }
                } else {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Send") {
                            guard let task else { return }
                            let budgetToSend = proposedBudget == task.budget ? nil : proposedBudget
                                // Switches this same sheet to the confirm step —
                                // does not dismiss anything.
                            vm.requestApply(to: task, proposedBudget: budgetToSend)
                        }
                        .buttonStyle(.glassProminent)
                    }
                }
            }
        }
    }
    
        // MARK: - Edit Step
    
    @ViewBuilder
    private var editStep: some View {
        Form {
            if let task {
                Section("Task") {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(task.title)
                            .font(.headline)
                        Text(task.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Section("Offered Budget") {
                    HStack {
                        Text("Original")
                        Spacer()
                        Text(task.budget.formatted(.currency(code: task.currency)))
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section {
                    Stepper(
                        value: $proposedBudget,
                        in: 0...1_000_000,
                        step: 25
                    ) {
                        HStack {
                            Text("Your Price")
                            Spacer()
                            Text(proposedBudget.formatted(.currency(code: task.currency)))
                                .fontWeight(.semibold)
                        }
                    }
                    
                    TextField(
                        "Amount",
                        value: $proposedBudget,
                        format: .currency(code: task.currency)
                    )
                    .keyboardType(.numberPad)
                    
                    if proposedBudget > task.budget {
                        Label("You're asking for more than the offered budget.", systemImage: "arrow.up.circle")
                            .font(.caption)
                            .foregroundStyle(.green)
                    } else if proposedBudget < task.budget {
                        Label("You're offering to do it for less.", systemImage: "arrow.down.circle")
                            .font(.caption)
                            .foregroundStyle(.red)
                    } else {
                        Label("You're accepting the original budget.", systemImage: "checkmark.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Your Offer")
                }
            }
        }
    }
    
        // MARK: - Confirm Step
    
    @ViewBuilder
    private var confirmStep: some View {
        Form {
            if let task {
                Section("Your Offer") {
                    HStack {
                        Text("Amount")
                        Spacer()
                        Text(
                            vm.feeConfirmationGrossAmount.formatted(.currency(code: task.currency))
                        )
                        .fontWeight(.semibold)
                    }
                }
                
                Section {
                    Text(vm.feeConfirmationMessage)
                        .font(.subheadline)
                } header: {
                    Text("Platform Fee")
                }
            }
            if let error = vm.errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
        }
    }
}
