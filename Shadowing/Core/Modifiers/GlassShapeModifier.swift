import SwiftUI

struct GlassCapsuleModifier: ViewModifier {
    var fill: AnyShapeStyle = AnyShapeStyle(.thinMaterial)
    var overlayColor: Color = .accentColor.opacity(0.15)
    var strokeColor: Color = Color(.separator).opacity(0.2)
    var shadowColor: Color = .accentColor.opacity(0.25)
    var shadowRadius: CGFloat = 0.1
    var shadowY: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .background(
                Capsule()
                    .fill(fill)
                    .overlay(Capsule().fill(overlayColor))
                    .overlay(Capsule().strokeBorder(strokeColor, lineWidth: 1))
            )
            .clipShape(Capsule())
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowY)
            .glassEffect()
    }
}

extension View {
    func GlassCapsule(
        fill: AnyShapeStyle = AnyShapeStyle(.thinMaterial),
        overlayColor: Color = .accentColor.opacity(0.15),
        strokeColor: Color = Color(.separator).opacity(0.2),
        shadowColor: Color = .accentColor.opacity(0.25),
        shadowRadius: CGFloat = 1,
        shadowY: CGFloat = 0
    ) -> some View {
        modifier(
            GlassCapsuleModifier(
                fill: fill,
                overlayColor: overlayColor,
                strokeColor: strokeColor,
                shadowColor: shadowColor,
                shadowRadius: shadowRadius,
                shadowY: shadowY
            )
        )
    }
}


