import SwiftUI
import CoreLocation

struct TaskCard: View {
    let task: TaskModel
    
    @State private var appeared = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            
                // MARK: Header
            HStack(alignment: .center, spacing: 12) {
                
                AvatarView(profile: task.requester)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.requester.displayName)
                        .font(.subheadline).fontWeight(.semibold).lineLimit(1)
                    Text(task.createdAt.toRelativeString())
                        .font(.caption).foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .center, spacing: 4) {
                    BudgetBadge(task: task)
                    ServiceBadge(task: task)
                }
            }
            .frame(maxHeight: 44)
            
                // MARK: Content
            VStack(alignment: .leading, spacing: 6) {
                Text(task.title)
                    .font(.headline).fontWeight(.bold).foregroundStyle(.primary)
                    .lineLimit(1).multilineTextAlignment(.leading)
                if !task.description.isEmpty {
                    Text(task.description)
                        .font(.subheadline).foregroundStyle(.secondary)
                        .lineLimit(2).multilineTextAlignment(.leading)
                }
            }
            
            Divider()
            
                // MARK: Footer
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 8) {
                    if let lat = task.latitude, let long = task.longitude {
                        DistanceBadge(taskLocation: CLLocation(latitude: lat, longitude: long))
                        
                    }
                }
                LocationBadge(task: task)
            }
            
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 6) {
                    PriorityBadge(priority: task.priority)
                    StatusBadge(status: task.status)
                    ApplicantsBadge(applicants: task.applicantsCount, color: .brown)
                    Spacer()
                    if task.isApplicant == true {
                        AppliedBadge()
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        PriorityBadge(priority: task.priority)
                        StatusBadge(status: task.status)
                        ApplicantsBadge(applicants: task.applicantsCount, color: .brown)
                    }
                    if task.isApplicant == true {
                        AppliedBadge()
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemGroupedBackground))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [task.priority.color, task.priority.color.opacity(0.5), task.priority.color.opacity(0.25)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        }
        .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 4)
        .scaleEffect(appeared ? 1 : 0.5)
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: appeared)
        .onAppear {
            appeared = true
        }
    }
}
