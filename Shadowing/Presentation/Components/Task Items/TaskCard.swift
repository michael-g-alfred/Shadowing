import SwiftUI
import CoreLocation

private struct SelectedUser: Identifiable {
    let id: String
}

struct TaskCard: View {
    
        // MARK: - Environment
    @Environment(DIContainer.self) private var container
    @Environment(\.colorScheme) private var colorScheme
    
        // MARK: - Properties
    let task: TaskModel
    var onToggleFavorite: (() -> Void)? = nil
    
        // MARK: - State
    @State private var appeared = false
    @State private var selectedUser: SelectedUser?
    
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
    private var darkMode: Bool {
        colorScheme == .dark
    }
    
        // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            
                // 1. Header (User Info + Price/Service)
            HStack(alignment: .top, spacing: Spacing.sm) {
                Button {
                    selectedUser = SelectedUser(id: task.requester.id)
                } label: {
                    AvatarView(profile: task.requester, nameLayout: .horizontal, subtitle: task.createdAt.toRelativeString())
                }
                .buttonStyle(.plain)
                .layoutPriority(0)
                
                Spacer(minLength: Spacing.xs)
                
                VStack(alignment: .trailing, spacing: Spacing.xs) {
                    BudgetBadge(task: task)
                    if let serviceLookup {
                        ServiceBadge(service: serviceLookup)
                    }
                }
                .layoutPriority(1)
            }
            
                // 2. Title & Description
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(task.title)
                    .font(.headline).fontWeight(.bold).foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                if !task.description.isEmpty {
                    Text(task.description)
                        .font(.subheadline).foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            
            Divider()
            
                // 3. Distance & Location
            HStack(alignment: .center, spacing: Spacing.sm) {
                if let lat = task.latitude, let long = task.longitude {
                    DistanceBadge(taskLocation: CLLocation(latitude: lat, longitude: long))
                }
                LocationBadge(task: task)
                    .lineLimit(1)
            }
            
                // 4. Badges & Actions Bottom Row
            HStack(alignment: .center, spacing: Spacing.xs) {
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.xs) {
                        if let priorityLookup {
                            PriorityBadge(priority: priorityLookup)
                        }
                        if let statusLookup {
                            StatusBadge(status: statusLookup)
                        }
                        ApplicantsBadge(applicants: task.applicantsCount, color: .brown)
                    }
                }
                
                Spacer(minLength: Spacing.xs)
                
                HStack(spacing: Spacing.xs) {
                    if task.isApplicant == true {
                        AppliedBadge()
                    }
                    if let onToggleFavorite {
                        favoriteBadge(action: onToggleFavorite)
                    }
                }
                .layoutPriority(1)
            }
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous)
                .fill(.thinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous)
                        .fill(darkMode ? priorityColor.opacity(0.075) : priorityColor.opacity(0.1))
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
        .sheet(item: $selectedUser) { user in
            container.makeUserView(userId: user.id)
                .appSheetStyle()
        }
    }
    
        // MARK: - Private Views
    private func favoriteBadge(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: task.isFavourite ? "star.fill" : "star")
                .imageScale(.small)
                .foregroundStyle(darkMode ? .rating : Color.black.opacity(0.75))
                .frame(width: Spacing.xxl, height: Spacing.xxl)
                .appGlassCapsule(
                    overlayColor: darkMode ? .rating.opacity(0.1) : .rating.opacity(0.5),
                    strokeColor: darkMode ? .rating.opacity(0.1) : Color.black.opacity(0.15)
                )
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
    }
}
