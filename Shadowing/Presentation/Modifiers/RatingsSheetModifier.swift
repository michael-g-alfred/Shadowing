import SwiftUI

    // MARK: - Ratings Sheet Modifier

    /// A reusable presentation modifier for the ratings sheet.
    ///
    /// Unlike the global app-flow sheets (see `GlobalSheetsModifier`), this
    /// sheet's state lives inside whichever ViewModel is presenting it
    /// (`TaskDetailsViewModel`, `UserViewModel`, `ProfileViewModel`, ...).
    /// This modifier stays agnostic of that origin — it only needs the
    /// user's id/name and a `Binding<Bool>` to drive presentation.
struct RatingsSheetModifier: ViewModifier {

        // MARK: Environment

    @Environment(DIContainer.self) private var container

        // MARK: Properties

    let userId: String?
    let userName: String?
    @Binding var isPresented: Bool

        // MARK: Body

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                if let userId, let userName {
                    container.makeRatingsView(
                        userId: userId,
                        userName: userName
                    )
                    .appSheetStyle()
                }
            }
    }
}

    // MARK: - View Extension

extension View {

        /// Presents the ratings sheet for a given user id/name, driven by
        /// an external `Binding<Bool>`.
    func ratingsSheet(
        userId: String?,
        userName: String?,
        isPresented: Binding<Bool>
    ) -> some View {
        modifier(
            RatingsSheetModifier(
                userId: userId,
                userName: userName,
                isPresented: isPresented
            )
        )
    }
}
