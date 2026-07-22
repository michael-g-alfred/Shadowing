import SwiftUI

struct AvatarView: View {
    
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
                HStack(spacing: 8) {
                    avatar
                    nameBlock(alignment: .leading)
                }
            case .vertical:
                VStack(spacing: 6) {
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
                                initialsOrPlaceholder
                            @unknown default:
                                initialsOrPlaceholder
                        }
                    }
                    .clipShape(Circle())
                } else {
                    initialsOrPlaceholder
                }
            }
        }
        .frame(width: size, height: size)
    }
    
    private var initialsOrPlaceholder: some View {
        Group {
            if let profile {
                Text(profile.displayName.prefix(1).uppercased())
                    .font(.system(size: size * 0.4))
                    .bold()
                    .foregroundStyle(avatarForeground)
                    .lineLimit(1)
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.4))
                    .foregroundStyle(avatarForeground)
            }
        }
    }
    
    private func nameBlock(alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 0) {
            Text(profile?.displayName ?? "Guest")
                .font(nameFont)
                .bold()
                .foregroundStyle(.primary)
                .lineLimit(1)
            
            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }
}
