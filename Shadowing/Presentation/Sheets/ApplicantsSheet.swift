import SwiftUI

struct ApplicantsSheet: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(DIContainer.self) private var container

    var vm: RequesterViewModel
    
    @State private var applicantPendingDecline: ApplicantModel?
    
    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Applicants")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { dismiss() }
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
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            applicantPendingDecline = applicant
                        } label: {
                            Label("Decline", systemImage: "xmark.circle")
                        }
                        .tint(.red)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .disabled(vm.isAssigningExecutor)
        }
    }
    
    @ViewBuilder
    private func applicantRow(_ applicant: ApplicantModel) -> some View {
        HStack(spacing: 14) {
            
            AvatarView(profile: applicant)
            
            VStack(alignment: .leading, spacing: 6) {
                
                Text(applicant.displayName)
                    .font(.headline)
                
                CompletedTaskRatingLabel(rating: applicant.rating ?? 0.0, completedTasks: applicant.completedTasks)
                
                Text("Applied \(applicant.appliedAt.toRelativeString())")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                if let proposedBudget = applicant.proposedBudget {
                    Text(proposedBudget.formatted(.currency(code: "EGP")))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.green)
                }
            }
            
            Spacer(minLength: 12)
            
            Button {
                Task {
                    await vm.assignExecutor(applicant)
                }
            } label: {
                Image(systemName: "checkmark")
            }
            .buttonStyle(.glassProminent)
            .buttonBorderShape(.circle)
        }
        .contentShape(Rectangle())
    }
}
