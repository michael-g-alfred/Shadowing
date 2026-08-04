import SwiftUI
import CoreLocation

struct TaskCard: View {
    
        // MARK: - Environment
    @Environment(DIContainer.self) private var container
    @Environment(\.locale) private var locale
    
        // MARK: - Properties
    let task: TaskModel
    var onToggleFavorite: (() -> Void)? = nil
    
        // MARK: - State
    @State private var appeared = false
    @State private var selectedUserId: String?
    
        // MARK: - Lookup-resolved values
    private var priorityLookup: PriorityLookup? {
        container.lookupStore.priority(named: task.priority)
    }
    private var statusLookup: StatusLookup? {
        container.lookupStore.status(named: task.status)
    }
    private var serviceLookup: TaskServiceLookup? {
        container.lookupStore.service(named: task.serviceType)
    }
    private var priorityColor: Color {
        Color(lookupName: priorityLookup?.color ?? "gray")
    }
    
        // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(alignment: .top, spacing: Spacing.sm) {
                    Button {
                        selectedUserId = task.requester.id
                    } label: {
                        AvatarView(profile: task.requester, nameLayout: .horizontal, subtitle: task.createdAt.toRelativeString())
                    }
                    .buttonStyle(.plain)
                    
                    Spacer(minLength: Spacing.sm)
                    
                    VStack(alignment: .trailing, spacing: Spacing.xs) {
                        BudgetBadge(task: task)
                        if let serviceLookup {
                            ServiceBadge(service: serviceLookup)
                        }
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
                    badgesRow
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
                        badgesRow
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
                        .fill(priorityColor.opacity(0.05))
                )
        )
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous)
                .strokeBorder(priorityColor, lineWidth: 1)
        }
        .scaleEffect(appeared ? 1 : 0.5)
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: appeared)
        .onAppear {
            appeared = true
        }
        .sheet(item: Binding(
            get: { selectedUserId },
            set: { selectedUserId = $0 }
        )) { userId in
            container.makeUserView(userId: userId)
                .appSheetStyle()
        }
    }
    
        // MARK: - Private Views
    @ViewBuilder
    private var badgesRow: some View {
        if let priorityLookup {
            PriorityBadge(priority: priorityLookup)
        }
        if let statusLookup {
            StatusBadge(status: statusLookup)
        }
        ApplicantsBadge(applicants: task.applicantsCount, color: .brown)
    }
    
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
