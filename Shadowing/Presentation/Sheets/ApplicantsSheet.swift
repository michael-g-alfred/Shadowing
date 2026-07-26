import SwiftUI

struct ApplicantsSheet: View {
    
        // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    @Environment(DIContainer.self) private var container
    
        // MARK: - Properties
    var vm: RequesterViewModel
    
        // MARK: - State
    @State private var applicantPendingDecline: ApplicantModel?
    
        // MARK: - Body
    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Applicants")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                            .buttonSizing(.fitted)
                            .buttonStyle(.glassProminent)
                            .tint(.red)
                            .disabled(vm.isAssigningExecutor)
                    }
                }
                .alert(item: $applicantPendingDecline) { applicant in
                    Alert(
                        title: Text("Decline Applicant"),
                        message: Text("Are you sure you want to decline \(applicant.displayName)?"),
                        primaryButton: .destructive(Text("Decline")) {
                            Task { await vm.declineApplicant(applicant) }
                        },
                        secondaryButton: .cancel()
                    )
                }
        }
    }
    
        // MARK: - Private Views
    @ViewBuilder
    private var content: some View {
        if vm.isLoadingApplicants {
            LoadingState.loading(
                title: "Loading",
                subtitle: "Fetching applicants."
            ).view
            
        } else if vm.selectedTaskApplicants.isEmpty {
            EmptyState.noApplicantsYet.view()
        } else {
            List {
                ForEach(vm.selectedTaskApplicants) { applicant in
                    NavigationLink {
                        container.makeRatingsView(userId: applicant.id, userName: applicant.displayName)
                    } label: {
                        applicantRow(applicant)
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            applicantPendingDecline = applicant
                        } label: {
                            Label("Decline", systemImage: "xmark.circle")
                        }
                        .tint(.red)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .confirm) {
                            Task {
                                await vm.assignExecutor(applicant)
                            }
                        } label: {
                            Label("Accept", systemImage: "checkmark.circle.fill")
                        }
                        .tint(.blue)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .disabled(vm.isAssigningExecutor)
        }
    }
    @ViewBuilder
    private func applicantRow(_ applicant: ApplicantModel) -> some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                
                AvatarView(profile: applicant, nameLayout: .horizontal, subtitle: applicant.appliedAt.toRelativeString())
                
                HStack(alignment: .center, spacing: 0) {
                    
                    CompletedTaskRatingLabel(rating: applicant.rating ?? 0.0, completedTasks: applicant.completedTasks)
                    
                    Spacer()
                    Divider()
                    Spacer()
                    
                    if let taskBudget = vm.selectedTaskForApplicants?.budget {
                        ApplicantBudgetBadge(
                            taskBudget: taskBudget,
                            proposedBudget: applicant.proposedBudget
                        )
                    }
                }
            }
        }
        .contentShape(Rectangle())
    }
}
