import SwiftUI

enum CornerRadius {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    
        /// Given an inner shape's radius and the padding around it,
        /// returns the radius the OUTER shape needs so both curves stay concentric.
        /// e.g. outer(innerRadius: .sm, padding: Spacing.md) == .xl
    static func outer(innerRadius: CGFloat, padding: CGFloat) -> CGFloat {
        innerRadius + padding
    }
    
        /// Given an outer shape's radius and the padding inside it,
        /// returns the radius the INNER shape needs so both curves stay concentric.
        /// e.g. inner(outerRadius: .xl, padding: Spacing.md) == .sm
    static func inner(outerRadius: CGFloat, padding: CGFloat) -> CGFloat {
        max(0, outerRadius - padding)
    }
}

#if DEBUG
    // Sanity check for the one nested case in the app today (TaskCard):
    // card outer radius .xl with .md padding should reduce to .sm.
private let _taskCardConcentricCheck: Void = {
    assert(CornerRadius.inner(outerRadius: CornerRadius.xl, padding: Spacing.md) == CornerRadius.sm,
           "TaskCard's outer/inner radii are no longer concentric — check Spacing.md and CornerRadius.xl/.sm")
}()
#endif
