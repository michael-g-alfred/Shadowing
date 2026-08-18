import SwiftUI

struct AvatarView<Accessory: View>: View {
    
        // MARK: - Environment
    @Environment(\.colorScheme) private var colorScheme
    
        // MARK: - Enums
    enum NameLayout {
        case none
        case horizontal
        case vertical
    }
    
        // MARK: - Properties
    let profile: Profile?
    var size: CGFloat = 44
    var accentColor: Color = .accent
    var nameLayout: NameLayout = .none
    var nameFont: Font = .body
    var subtitle: String? = nil
    @ViewBuilder var accessory: () -> Accessory
    
    init(
        profile: Profile?,
        size: CGFloat = 44,
        accentColor: Color = .accent,
        nameLayout: NameLayout = .none,
        nameFont: Font = .body,
        subtitle: String? = nil,
        @ViewBuilder accessory: @escaping () -> Accessory
    ) {
        self.profile = profile
        self.size = size
        self.accentColor = accentColor
        self.nameLayout = nameLayout
        self.nameFont = nameFont
        self.subtitle = subtitle
        self.accessory = accessory
    }
    
    private var avatarBackground: Color {
        colorScheme == .dark
        ? accentColor.opacity(0.35)
        : accentColor.opacity(0.15)
    }
    
    private var avatarForeground: Color {
        colorScheme == .dark
        ? accentColor.opacity(0.9)
        : accentColor
    }
    
        // MARK: - Body
    var body: some View {
        switch nameLayout {
            case .none:
                avatar
            case .horizontal:
                HStack(spacing: Spacing.sm) {
                    avatar
                    nameBlock(alignment: .leading)
                }
            case .vertical:
                VStack(spacing: Spacing.xs) {
                    avatar
                    nameBlock(alignment: .center)
                }
        }
    }
    
        // MARK: - Private Views
    private var avatar: some View {
        ZStack {
            Circle()
                .fill(avatarBackground.opacity(1))
            
            Group {
                if let urlString = profile?.avatarUrl,
                   let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            case .failure, .empty:
                                placeholder
                            @unknown default:
                                placeholder
                        }
                    }
                    .clipShape(Circle())
                } else {
                    placeholder
                }
            }
        }
        .frame(width: size, height: size)
    }
    
    private var placeholder: some View {
        Image(systemName: "person.fill")
            .font(.system(size: size * 0.4))
            .foregroundStyle(avatarForeground)
    }
    
    private func nameBlock(alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 0) {
            if alignment == .leading {
                HStack(alignment: .center,spacing: Spacing.sm) {
                    Text(profile?.displayName ?? "Guest")
                        .font(nameFont)
                        .bold()
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    accessory()
                }
            } else {
                HStack(alignment: .center, spacing: Spacing.sm) {
                    Text(profile?.displayName ?? "Guest")
                        .font(nameFont)
                        .bold()
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    accessory()
                }
            }
            
            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }
}

    // MARK: - Convenience init (no accessory)
extension AvatarView where Accessory == EmptyView {
    init(
        profile: Profile?,
        size: CGFloat = 44,
        accentColor: Color = .accent,
        nameLayout: NameLayout = .none,
        nameFont: Font = .body,
        subtitle: String? = nil
    ) {
        self.init(
            profile: profile,
            size: size,
            accentColor: accentColor,
            nameLayout: nameLayout,
            nameFont: nameFont,
            subtitle: subtitle,
            accessory: { EmptyView() }
        )
    }
}
