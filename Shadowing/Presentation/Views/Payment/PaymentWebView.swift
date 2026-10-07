import SwiftUI
@preconcurrency import WebKit

struct PaymentWebView: View {
    let url: URL
    let onDismiss: () async -> Void
    let onFailure: (Error) -> Void

    @Environment(\.dismiss) private var dismiss

    /// Guards `close()` so the Done button and the automatic close after the
    /// "payment done" page can't both run `onDismiss`.
    @State private var isClosing = false

    var body: some View {
        NavigationStack {
            PaymobWebViewRepresentable(
                url: url,
                onFinished: { handleFinished() },
                onFailure: onFailure
            )
            .navigationTitle("Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        close()
                    }
                }
            }
        }
    }

    // MARK: - Closing

    private func close() {
        guard !isClosing else { return }
        isClosing = true
        dismiss()
        Task { await onDismiss() }
    }

    /// Called when the backend's "payment done" page has finished loading
    /// (Paymob redirects there after the customer pays). Gives the customer a
    /// moment to read the confirmation, then closes the sheet. The caller's
    /// `onDismiss` then asks the server to re-check the payment.
    private func handleFinished() {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.5))
            close()
        }
    }
}

/// Hosts Paymob's checkout page and keeps its authentication windows in the
/// same checkout session. Paymob can open 3-D Secure or OTP verification in a
/// new browser window; a default `WKWebView` drops those windows entirely.
private struct PaymobWebViewRepresentable: UIViewRepresentable {
    let url: URL
    let onFinished: () -> Void
    let onFailure: (Error) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinished: onFinished, onFailure: onFailure)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        private let onFinished: () -> Void
        private let onFailure: (Error) -> Void
        private var didReportFinished = false

        init(onFinished: @escaping () -> Void, onFailure: @escaping (Error) -> Void) {
            self.onFinished = onFinished
            self.onFailure = onFailure
        }

        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            guard navigationAction.targetFrame == nil else {
                return nil
            }

            webView.load(navigationAction.request)
            return nil
        }

        /// Paymob redirects the customer to the backend's `/pay/done` page
        /// after paying. Seeing that page finish loading means the checkout
        /// is over (the page itself also makes the backend re-check Paymob).
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard !didReportFinished,
                  let url = webView.url,
                  url.path.hasSuffix("/pay/done")
            else { return }

            didReportFinished = true
            onFinished()
        }

        func webView(
            _ webView: WKWebView,
            didFailProvisionalNavigation navigation: WKNavigation?,
            withError error: Error
        ) {
            guard !Self.isIgnorable(error) else { return }
            onFailure(error)
        }

        func webView(
            _ webView: WKWebView,
            didFail navigation: WKNavigation?,
            withError error: Error
        ) {
            guard !Self.isIgnorable(error) else { return }
            onFailure(error)
        }

        /// Redirects (e.g. into 3-D Secure) routinely cancel the navigation
        /// that was in flight (`NSURLErrorCancelled`, WebKit error 102
        /// "Frame load interrupted"). Those aren't real failures and must not
        /// tear the checkout down mid-payment.
        private static func isIgnorable(_ error: Error) -> Bool {
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain, nsError.code == NSURLErrorCancelled {
                return true
            }
            if nsError.domain == "WebKitErrorDomain", nsError.code == 102 {
                return true
            }
            return false
        }
    }
}
