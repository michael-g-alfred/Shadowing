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
                    
                    if let error = vm.errorMessage {
                        Section {
                            Text(error).foregroundStyle(.red).font(.caption)
                        }
                    }
                }
            }
            .navigationTitle("Apply to Task")
            .navigationBarTitleDisplayMode(.inline)
            .disabled(vm.isApplying)
            .onAppear {
                if let task { proposedBudget = task.budget }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(vm.isApplying)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if vm.isApplying {
                        ProgressView()
                    } else {
                        Button("Send") {
                            guard let task else { return }
                            let budgetToSend = proposedBudget == task.budget ? nil : proposedBudget
                                // Shows a confirmation alert with the net amount (after the
                                // platform fee) before the application is actually sent.
                            vm.requestApply(to: task, proposedBudget: budgetToSend)
                        }
                        .buttonStyle(.glassProminent)
                    }
                }
            }
        }
    }
}
