import SwiftUI

    // MARK: - App Sheet Style Modifier

struct AppSheetStyle: ViewModifier {
    
        // MARK: - Environment
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme

        // MARK: - Properties
    var detents: Set<PresentationDetent> = [.fraction(0.75)]
    var interactiveDismissDisabled: Bool = false
    
        // iPad (regular width) reads better as a popover; iPhone (compact) stays a sheet
    private var compactAdaptation: PresentationAdaptation {
        horizontalSizeClass == .regular ? .fullScreenCover : .sheet
    }
    
    func body(content: Content) -> some View {
        content
            .presentationDetents(detents)
            .presentationDragIndicator(.visible)
            .presentationBackground {
                colorScheme == .dark ? AppBackground() : nil
            }
            .interactiveDismissDisabled(interactiveDismissDisabled)
            .presentationCompactAdaptation(compactAdaptation)
    }
}

extension View {
    func appSheetStyle(
        detents: Set<PresentationDetent> = [.fraction(0.75)],
        interactiveDismissDisabled: Bool = false
    ) -> some View {
        modifier(AppSheetStyle(
            detents: detents,
            interactiveDismissDisabled: interactiveDismissDisabled
        ))
    }
}
