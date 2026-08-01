import SwiftUI
import CoreLocation

struct TaskCard: View {
    
        // MARK: - Properties
    let task: TaskModel
    var onToggleFavorite: (() -> Void)? = nil
    
        // MARK: - State
    @State private var appeared = false
    
        // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(alignment: .top, spacing: Spacing.sm) {
                    AvatarView(profile: task.requester, nameLayout: .horizontal, subtitle: task.createdAt.toRelativeString())
                    
                    Spacer(minLength: Spacing.sm)
                    
                    VStack(alignment: .trailing, spacing: Spacing.xs) {
                        BudgetBadge(task: task)
                        ServiceBadge(task: task)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(task.title)
                    .font(.headline).fontWeight(.bold).foregroundStyle(.primary)
                    .lineLimit(1).multilineTextAlignment(.leading)
                if !task.description.isEmpty {
                    Text(task.description)
                        .font(.subheadline).foregroundStyle(.secondary)
                        .lineLimit(1).multilineTextAlignment(.leading)
                }
            }
            
            Divider()
            
            HStack(alignment: .center, spacing: Spacing.sm) {
                if let lat = task.latitude, let long = task.longitude {
                    DistanceBadge(taskLocation: CLLocation(latitude: lat, longitude: long))
                }
                LocationBadge(task: task)
            }
            
            ViewThatFits(in: .horizontal) {
                HStack(spacing: Spacing.xs) {
                    PriorityBadge(priority: task.priority)
                    StatusBadge(status: task.status)
                    ApplicantsBadge(applicants: task.applicantsCount, color: .brown)
                    Spacer()
                    if task.isApplicant == true {
                        AppliedBadge()
                    }
                    if let onToggleFavorite {
                        favoriteBadge(action: onToggleFavorite)
                    }
                }
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack(spacing: Spacing.xs) {
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
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous)
                .fill(.thinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous)
                        .fill(task.priority.color.opacity(0.05))
                )
        )
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous)
                .strokeBorder(
                    task.priority.color,
                    lineWidth: 1
                )
        }
        .scaleEffect(appeared ? 1 : 0.5)
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: appeared)
        .onAppear {
            appeared = true
        }
    }
    
        // MARK: - Private Views
    private func favoriteBadge(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: task.isFavourite ? "star.fill" : "star")
                .imageScale(.medium)
                .foregroundStyle(task.isFavourite ? .rating : .secondary)
                .frame(width: 32, height: 32)
                .appGlassCapsule(
                    overlayColor: .yellow.opacity(0.1),
                    strokeColor: .yellow.opacity(0.05),
                    shadowColor: .yellow.opacity(0.05)
                )
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
    }
}
