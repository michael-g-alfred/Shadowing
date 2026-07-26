import SwiftUI

    // MARK: - App Sheet Style Modifier

struct AppSheetStyle: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var detents: Set<PresentationDetent> = [.fraction(0.75)]
    var interactiveDismissDisabled: Bool = false
    
        // iPad (regular width) reads better as a popover; iPhone (compact) stays a sheet
    private var compactAdaptation: PresentationAdaptation {
        horizontalSizeClass == .regular ? .popover : .sheet
    }
    
    func body(content: Content) -> some View {
        content
            .presentationDetents(detents)
            .presentationDragIndicator(.visible)
            .presentationBackground {
                AppBackground()
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
