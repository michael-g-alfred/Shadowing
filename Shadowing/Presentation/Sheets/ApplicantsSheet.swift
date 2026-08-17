import SwiftUI

struct ApplicantsSheet: View {
    
        // MARK: - Environment
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
                .alert(
                    vm.assignResult.map { AlertType(responseType: $0.type).label } ?? "",
                    isPresented: Binding(
                        get: { vm.assignResult != nil },
                        set: { if !$0 { vm.assignResult = nil } }
                    )
                ) {
                    Button("OK") {
                        vm.dismissAssignSuccessAlert()
                    }
                } message: {
                    Text(vm.assignResult?.message ?? "")
                }
        }
    }
    
        // MARK: - Private Views
    @ViewBuilder
    private var content: some View {
        if vm.isLoadingApplicants {
            LoadingState.loading(
                title: "Loading Applicants",
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
            .listSectionSeparatorTint(.rating)
            .listStyle(.insetGrouped)
            .disabled(vm.isAssigningExecutor)
        }
    }
    
    @ViewBuilder
    private func applicantRow(_ applicant: ApplicantModel) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(alignment: .top, spacing: Spacing.xs) {
                
                AvatarView(profile: applicant, nameLayout: .horizontal, subtitle: applicant.appliedAt.toRelativeString())
                
                Spacer(minLength: Spacing.md)
                
                CompletedTaskRatingLabel(rating: applicant.rating ?? 0.0, completedTasks: applicant.completedTasks)
            }
            
            if let taskBudget = vm.selectedTaskForApplicants?.budget {
                ApplicantBudgetBadge(
                    taskBudget: taskBudget,
                    proposedBudget: applicant.proposedBudget
                )
            }
        }
        .contentShape(Rectangle())
    }
}
