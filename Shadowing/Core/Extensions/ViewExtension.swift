import SwiftUI

// MARK: - Custom text fields

extension View {
    func customTextField(
        title: LocalizedStringResource,
        text: Binding<String>,
        icon: String,
        type: UITextContentType
    ) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 30)
            TextField(title, text: text)
                .textContentType(type)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    func customSecureField(
        title: LocalizedStringResource,
        text: Binding<String>,
        icon: String,
        iconColor: Color = .blue
    ) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .frame(width: 30)
            SecureField(title, text: text)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - List row insets

extension View {
    func listRowInsets(_ edges: Edge.Set, _ value: CGFloat) -> some View {
        listRowInsets(EdgeInsets(
            top:      edges.contains(.top)      ? value : 0,
            leading:  edges.contains(.leading)  ? value : 0,
            bottom:   edges.contains(.bottom)   ? value : 0,
            trailing: edges.contains(.trailing) ? value : 0
        ))
    }
}

// MARK: - Selective corner radius

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius:  CGFloat      = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
