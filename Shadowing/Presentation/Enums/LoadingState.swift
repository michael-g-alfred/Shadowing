import SwiftUI

enum LoadingState {
    case initializing
    case loading(
        title: LocalizedStringResource = "Fetching your data",
        subtitle: LocalizedStringResource = "Loading..."
    )
    case error(message: String)
    
    @ViewBuilder
    var view: some View {
        switch self {
            case .initializing:
                ProgressView()
                
            case let .loading(title, subtitle):
                ContentUnavailableView {
                    ProgressView()
                        .controlSize(.large)
                    Text(title)
                        .bold()
                } description: {
                    Text(subtitle)
                }
                
            case let .error(message):
                ContentUnavailableView(
                    "Something Went Wrong",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
        }
    }
}
