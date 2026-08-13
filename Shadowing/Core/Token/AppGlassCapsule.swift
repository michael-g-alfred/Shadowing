import SwiftUI

struct AppGlassCapsule: ViewModifier {
    
        // MARK: - Environment
    @Environment(\.colorScheme) private var colorScheme
    
    var fill: AnyShapeStyle = AnyShapeStyle(.thinMaterial)
    var overlayColor: Color = .accentColor.opacity(0.15)
    var strokeColor: Color = Color(.separator).opacity(0.2)
    
    @ViewBuilder
    func body(content: Content) -> some View {
        let baseContent = content
            .background(
                Capsule()
                    .fill(fill)
                    .overlay(Capsule().fill(overlayColor))
                    .overlay(Capsule().strokeBorder(strokeColor, lineWidth: 1))
            )
            .clipShape(Capsule())
        
        if colorScheme == .dark {
            baseContent.glassEffect()
        } else {
            baseContent
        }
    }
}

extension View {
    func appGlassCapsule(
        fill: AnyShapeStyle = AnyShapeStyle(.thinMaterial),
        overlayColor: Color = .accentColor.opacity(0.15),
        strokeColor: Color = Color(.separator).opacity(0.2),
    ) -> some View {
        modifier(
            AppGlassCapsule(
                fill: fill,
                overlayColor: overlayColor,
                strokeColor: strokeColor,
            )
        )
    }
}
