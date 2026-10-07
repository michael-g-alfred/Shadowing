import Foundation
import SwiftUI

/// Presents a single "pay for this task" attempt as a sheet.
///
/// Present this directly as a `.sheet` from wherever the "Pay Now" action
/// lives (e.g. a future button on `TaskDetailsView`), via
/// `DIContainer.makePaymentView(for:)`:
///
/// ```swift
/// .sheet(isPresented: $showPayment) {
///     diContainer.makePaymentView(for: task)
/// }
/// ```
///
/// Internally this just sequences three states: loading (fetching the
/// payment URL), the existing ``PaymentWebView`` once the URL is ready, or
/// an error with a retry button if the request failed.
struct PaymentView: View {

    let vm: PaymentViewModel

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        if let url = vm.paymentURL {
            // PaymentWebView brings its own NavigationStack + toolbar, so it
            // is shown directly rather than nested inside another one below.
            PaymentWebView(
                url: url,
                onDismiss: {
                    await vm.webViewDismissed()
                },
                onFailure: { error in
                    vm.webViewFailed(error)
                }
            )
        } else {
            NavigationStack {
                statusContent
                    .navigationTitle("Payment")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { dismiss() }
                        }
                    }
            }
        }
    }

    @ViewBuilder
    private var statusContent: some View {
        if let errorMessage = vm.errorMessage {
            errorState(errorMessage)
        } else {
            loadingState
        }
    }

    // MARK: - Loading

    private var loadingState: some View {
        VStack(spacing: 16) {
            Image(systemName: "creditcard")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            ProgressView()
            Text(preparingMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        // The sole trigger for startPayment() — see the note on
        // PaymentViewModel.retry() for why retry doesn't also call it.
        .task {
            await vm.startPayment()
        }
    }

    private var preparingMessage: LocalizedStringResource {
        "Preparing your \(formattedAmount) payment for \"\(vm.task.title)\"…"
    }

    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0

        let amount = formatter.string(
            from: NSNumber(value: vm.task.budget)
        ) ?? String(format: "%.2f", vm.task.budget)

        return "\(amount) \(vm.task.currency)"
    }

    // MARK: - Error

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Try Again") {
                vm.retry()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
