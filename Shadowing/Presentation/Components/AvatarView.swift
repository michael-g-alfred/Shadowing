import SwiftUI

struct AvatarView: View {
    
    enum NameLayout {
        case none
        case horizontal
        case vertical
    }
    
        // MARK: - Properties
    let profile: Profile?
    var size: CGFloat = 44
    var accentColor: Color = .accentColor
    var nameLayout: NameLayout = .none
    var nameFont: Font = .body
    var subtitle: String? = nil
    var borderColor: Color? = nil
    var borderWidth: CGFloat = 1
    
        // MARK: - Body
    var body: some View {
        switch nameLayout {
            case .none:
                avatar
            case .horizontal:
                HStack(spacing: 16) {
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
                .fill(accentColor.opacity(0.12))
            
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
            .overlay {
                if let borderColor {
                    Circle()
                        .strokeBorder(borderColor, lineWidth: borderWidth)
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
                    .fontDesign(.rounded)
                    .foregroundStyle(accentColor)
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.4))
                    .foregroundStyle(accentColor)
            }
        }
    }
    
    private func nameBlock(alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 2) {
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
