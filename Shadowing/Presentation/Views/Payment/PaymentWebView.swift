import SwiftUI
@preconcurrency import WebKit

struct PaymentWebView: View {
    let url: URL
    let onDismiss: () async -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            WebViewRepresentable(url: url)
                .navigationTitle("Payment")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            dismiss()
                            Task { await onDismiss() }
                        }
                    }
                }
        }
    }
}

private struct WebViewRepresentable: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.load(URLRequest(url: url))
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
