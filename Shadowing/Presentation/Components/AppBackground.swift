import SwiftUI

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
                startRadius: 0,
                endRadius: max(geometry.size.width, geometry.size.height) * 1.25
            )
            .ignoresSafeArea(edges: .all)
        }
        .ignoresSafeArea(edges: .all)
    }
}
