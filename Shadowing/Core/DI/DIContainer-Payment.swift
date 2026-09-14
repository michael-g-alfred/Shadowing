import Foundation
import SwiftUI

    /// Factory methods for the "pay for this task" flow.
    ///
    /// A payment attempt is created fresh per use — like `makeRatingViewModel`
    /// or `makeUserViewModel` elsewhere in `DIContainer` — rather than held as
    /// a shared singleton, since (unlike `requesterViewModel` /
    /// `executorViewModel`) there's no state here worth persisting across
    /// screens.
extension DIContainer {
    
        /// The sheet that runs a single payment attempt for `task`: fetches a
        /// Paymob payment URL, then shows the payment WebView.
        ///
        /// - Parameter task: The task to pay for.
    func makePaymentView(for task: TaskModel) -> PaymentView {
        PaymentView(vm: makePaymentViewModel(for: task))
    }
    
        /// Creates a fresh view model for a single payment attempt on `task`.
        ///
        /// No `onDismiss` is wired here: `TaskDetailsView` presents this from
        /// `TaskDetailsViewModel.isPaymentSheetPresented` and refreshes the task
        /// itself via its own `.onChange` once the sheet closes — the same
        /// pattern it already uses for the applicants sheet and apply flow. If
        /// you present this from somewhere without that kind of reload hook,
        /// pass an `onDismiss` closure to `PaymentViewModel` directly instead of
        /// adding one back here, so this factory doesn't silently assume one
        /// particular caller.
        ///
        /// - Parameter task: The task to pay for.
    func makePaymentViewModel(for task: TaskModel) -> PaymentViewModel {
        PaymentViewModel(task: task, taskRepo: taskRepository)
    }
}
