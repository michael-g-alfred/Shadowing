import SwiftUI

struct ScreenContainer<Content: View>: View {

    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            AppBackground()
            content
        }
    }
}
