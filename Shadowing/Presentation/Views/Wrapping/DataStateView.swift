import SwiftUI

struct DataStateView<Value, LoadedContent: View>: View {

    let state: ViewState<Value>
    var loadingState: LoadingState = .loading()
    let emptyState: EmptyState
    var retryAction: (() async -> Void)? = nil
    var clearFilterAction: (() -> Void)? = nil
    var settingsAction: (() -> Void)? = nil
    @ViewBuilder let loadedContent: (Value) -> LoadedContent

    var body: some View {
        switch state {
            case .loading:
                loadingState.view

            case .error(let message):
                LoadingState.error(message: message).view

            case .empty:
                emptyState.view(
                    retryAction: retryAction,
                    clearFilterAction: clearFilterAction,
                    settingsAction: settingsAction
                )

            case .loaded(let value):
                loadedContent(value)
        }
    }
}
