import Foundation

/// Drives a single "pay for this task" attempt: requests a Paymob payment
/// URL from the backend, then hands it to ``PaymentWebView`` for the
/// requester to complete the card payment.
///
/// Created fresh per attempt (see `DIContainer.makePaymentViewModel(for:)`)
/// rather than held as a shared singleton like `requesterViewModel` /
/// `executorViewModel` — a payment attempt is a short-lived, single-task
/// flow with no state worth persisting across screens.
@MainActor
@Observable
final class PaymentViewModel {

    /// The task this payment is for.
    let task: TaskModel

    var isLoading = false
    var errorMessage: String?

    /// The Paymob iframe URL, once obtained. Presenting ``PaymentWebView``
    /// with this is what actually shows the payment form.
    private(set) var paymentURL: URL?

    private let taskRepo: TaskRepositoryProtocol

    /// Called once the payment sheet closes, regardless of whether the
    /// payment actually succeeded.
    ///
    /// IMPORTANT: there is no synchronous "it worked" signal here — Paymob
    /// confirms asynchronously via a server-side webhook, which may not
    /// have landed yet by the time the user taps "Done". `onDismiss` is
    /// the hook for the caller to re-fetch the task so its `escrowStatus`
    /// reflects reality if the webhook *has* already landed; if it hasn't,
    /// the task will still show `not_paid` and the "Pay Now" action stays
    /// available for the requester to try again.
    private let onDismiss: (() async -> Void)?

    /// Creates a payment view model for a single task.
    ///
    /// - Parameters:
    ///   - task: The task being paid for.
    ///   - taskRepo: Repository used to request the Paymob payment URL.
    ///   - onDismiss: Called once the payment sheet closes, success or not.
    init(
        task: TaskModel,
        taskRepo: TaskRepositoryProtocol,
        onDismiss: (() async -> Void)? = nil
    ) {
        self.task = task
        self.taskRepo = taskRepo
        self.onDismiss = onDismiss
    }

    // MARK: - Start Payment

    /// Requests a fresh Paymob payment URL for `task`.
    ///
    /// Call this once, from the loading state's `.task` modifier — see
    /// ``PaymentView``. Guards against double-firing so it's harmless if
    /// SwiftUI ever re-invokes the `.task` it's attached to.
    func startPayment() async {
        guard !isLoading, paymentURL == nil else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            paymentURL = try await taskRepo.startPayment(taskId: task.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Clears the current error so the view falls back to its loading
    /// state, whose `.task` modifier re-attempts ``startPayment()``.
    ///
    /// Deliberately does NOT call `startPayment()` directly — that would
    /// double-fire alongside the loading state's own `.task`. Clearing the
    /// error and letting the view transition back to loading is the single
    /// source of truth for retrying.
    func retry() {
        errorMessage = nil
    }

    // MARK: - Dismiss

    /// Called when the payment WebView's "Done" button is tapped.
    func webViewDismissed() async {
        paymentURL = nil
        await onDismiss?()
    }
}
