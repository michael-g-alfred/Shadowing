import SwiftUI
import CoreLocation

// MARK: - AppBackground

struct AppBackground: View {
    var body: some View {
        GeometryReader { geometry in
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.accentColor.opacity(0.25),
                    Color.accentColor.opacity(0.125),
                    Color.accentColor.opacity(0.25)
                ]),
                center: .topLeading,
                startRadius: 5,
                endRadius: max(geometry.size.width, geometry.size.height) * 1.25
            )
            .ignoresSafeArea(edges: .all)
        }
        .ignoresSafeArea(edges: .all)
    }
}

    // MARK: - ActionButton

struct ActionButton<S: LabelStyle>: View {
    let title:        LocalizedStringResource
    let systemImage:  String
    var labelStyle:   S
    let tint:         Color
    var role:         ButtonRole?
    var buttonSizing: ButtonSizing
    var isLoading:    Bool = false
    let action:       () -> Void
    
    var body: some View {
        Button(role: role) { action() } label: {
            Group {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Label(title, systemImage: systemImage)
                        .labelStyle(labelStyle)
                }
            }
            .font(.headline).bold()
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.glassProminent)
        .buttonSizing(buttonSizing)
        .tint(tint)
        .listRowInsets(.init())
        .listRowBackground(Color.clear)
        .padding(.horizontal)
        .keyboardShortcut(.defaultAction)
    }
}

extension ActionButton where S == TitleAndIconLabelStyle {
    init(
        title:        LocalizedStringResource,
        systemImage:  String,
        labelStyle:   S = .titleAndIcon,
        tint:         Color,
        role:         ButtonRole? = nil,
        buttonSizing: ButtonSizing = .flexible,
        isLoading:    Bool = false,
        action:       @escaping () -> Void
    ) {
        self.title        = title
        self.systemImage  = systemImage
        self.labelStyle   = labelStyle
        self.tint         = tint
        self.role         = role
        self.buttonSizing = buttonSizing
        self.isLoading    = isLoading
        self.action       = action
    }
}

    // MARK: - PriorityBadge

struct PriorityBadge: View {
    let priority: TaskPriority
    
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: priority.icon)
                .font(.caption2).fontWeight(.bold).foregroundStyle(priority.color)
            Text(priority.localizedLabel)
                .font(.caption2).fontWeight(.bold).textCase(.uppercase).foregroundStyle(priority.color)
        }
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background { Capsule().fill(priority.color.opacity(0.1)) }
        .overlay { Capsule().strokeBorder(priority.color.opacity(0.25), lineWidth: 1) }
    }
}

    // MARK: - StatusBadge

struct StatusBadge: View {
    let status: TaskStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(status.color).frame(width: 5, height: 5)
                .shadow(color: status.color.opacity(0.3), radius: 2)
            Text(status.localizedLabel)
                .font(.caption2).fontWeight(.bold).textCase(.uppercase).foregroundStyle(status.color)
        }
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background { Capsule().fill(status.color.opacity(0.1)) }
        .overlay { Capsule().strokeBorder(status.color.opacity(0.25), lineWidth: 1) }
    }
}

    // MARK: - BudgetBadge

struct BudgetBadge: View {
    let task: TaskModel
    
    var body: some View {
        Text(task.budget.formatted(.currency(code: task.currency)))
            .font(.caption2).fontWeight(.bold).foregroundStyle(task.priority.color)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background { Capsule().fill(task.priority.color.opacity(0.1)) }
            .overlay { Capsule().strokeBorder(task.priority.color.opacity(0.25), lineWidth: 1) }
    }
}

    // MARK: - ServiceBadge

struct ServiceBadge: View {
    let task: TaskModel
    
    var body: some View {
        HStack(alignment: .center, spacing: 2) {
            Image(systemName: task.serviceType.icon)
            Text(task.serviceType.localizedLabel)
        }
        .font(.caption).fontWeight(.medium).foregroundStyle(.tertiary)
    }
}

// MARK: - LocationBadge

struct LocationBadge: View {
    let task: TaskModel

    var body: some View {
        HStack(alignment: .center, spacing: 3) {
            Image(systemName: "map.fill")
            Text(task.address)
        }
        .font(.caption).fontWeight(.medium).foregroundStyle(.secondary)
    }
}

// MARK: - ApplicantsBadge

struct ApplicantsBadge: View {
    let applicants: Int
    let color:      Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "person.2.fill").font(.caption2)
            Text("\(applicants)")
                .font(.caption2)
                .fontWeight(.bold)
                .contentTransition(.numericText())
        }
        .foregroundStyle(color)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background { Capsule().fill(color.opacity(0.1)) }
        .overlay {
            Capsule().strokeBorder(color.opacity(0.75), style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [2, 3]))
        }
    }
}

// MARK: - AppliedBadge

struct AppliedBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(.white)
                .frame(width: 5, height: 5)

            Text("Applied")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background { Capsule().fill(.green.opacity(0.8)) }
        .overlay { Capsule().strokeBorder(.green.opacity(1), lineWidth: 1) }
    }
}

// MARK: - DistanceBadge

struct DistanceBadge: View {
    let taskLocation: CLLocation
    @Environment(DIContainer.self) private var container

    private var distance: String? {
        container.locationService.currentLocation?.distance(from: taskLocation).formatted(.number)
    }

    var body: some View {
        if let distance {
            HStack(spacing: 3) {
                Image(systemName: "location.fill").font(.caption2)
                Text(distance).font(.caption2).fontWeight(.semibold)
            }
            .foregroundStyle(.cyan)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background { Capsule().fill(Color.cyan.opacity(0.1)) }
            .overlay { Capsule().strokeBorder(Color.cyan.opacity(0.25), lineWidth: 1) }
        }
    }
}

// MARK: - TimeLabel

struct TimeLabel: View {
    let time: Date

    var body: some View {
        HStack(alignment: .center, spacing: 2) {
            Image(systemName: "clock")
            Text(time.formatted(date: .omitted, time: .shortened))
        }
        .font(.caption).foregroundStyle(.tertiary)
    }
}

// MARK: - CompletedTaskRatingLabel

struct CompletedTaskRatingLabel: View {
    let rating:         Double
    let completedTasks: Int

    var body: some View {
        HStack {
            HStack(spacing: 4) {
                Text("Completed Tasks:").font(.caption).foregroundStyle(.secondary)
                Text("\(completedTasks)").font(.caption).foregroundStyle(.primary).fontWeight(.semibold)
            }
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                Text(String(format: "%.1f", rating))
            }
            .font(.caption).bold().foregroundStyle(.orange)
        }
    }
}

// MARK: - AvatarView

struct AvatarView: View {
    let profile: Profile?
    var size: CGFloat = 44
    var accentColor: Color = .accentColor

    var body: some View {
        ZStack {
            Circle()
                .fill(accentColor.opacity(0.12))
            if let profile {
                Text(profile.displayName.prefix(1).uppercased())
                    .font(.system(size: size * 0.4, weight: .bold, design: .monospaced))
                    .foregroundStyle(accentColor)
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.4))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    VStack(alignment: .leading, spacing: 24) {
        HStack {
            PriorityBadge(priority: .low)
            PriorityBadge(priority: .normal)
            PriorityBadge(priority: .high)
            PriorityBadge(priority: .urgent)
        }
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                StatusBadge(status: .published)
                StatusBadge(status: .pending)
                StatusBadge(status: .inProgress)
            }
            HStack {
                StatusBadge(status: .pendingCompleted)
                StatusBadge(status: .completed)
            }
        }
//        BudgetBadge(task: .preview)
//        ServiceBadge(task: .preview)
//        LocationBadge(task: .preview)
        ApplicantsBadge(applicants: 3, color: .brown)
        AppliedBadge()
    }
    .padding()
}
