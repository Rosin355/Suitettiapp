import SwiftUI
import WebKit

/// In-app web view (WKWebView) with optional loading / error reporting.
///
/// Inline media playback is enabled so festival videos play within the app rather
/// than forcing full-screen. Pass `isLoading` / `loadError` bindings to drive a
/// SwiftUI loading spinner and error state; both are optional so the plain
/// `InAppWebView(url:)` call site keeps working unchanged.
struct InAppWebView: UIViewRepresentable {
    let url: URL
    var isLoading: Binding<Bool>? = nil
    var loadError: Binding<Error?>? = nil

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.allowsBackForwardNavigationGestures = true
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // Keep the coordinator's parent (and thus its bindings) current.
        context.coordinator.parent = self
        // Only (re)load when the target URL actually changes — avoids reload loops
        // from SwiftUI re-evaluating the representable.
        if context.coordinator.loadedURL != url {
            context.coordinator.loadedURL = url
            webView.load(URLRequest(url: url))
        }
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var parent: InAppWebView
        var loadedURL: URL?
        /// Set when we reject a 4xx/5xx main-frame response so the cancellation
        /// callback that follows doesn't overwrite the HTTP-status error.
        private var suppressNextFailure = false

        init(_ parent: InAppWebView) {
            self.parent = parent
            self.loadedURL = parent.url
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading?.wrappedValue = true
            parent.loadError?.wrappedValue = nil
        }

        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationResponse: WKNavigationResponse,
                     decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
            // Turn an HTTP 4xx/5xx on the main page into the app's graceful error
            // state instead of rendering the site's own 404/500 page inside the sheet.
            if navigationResponse.isForMainFrame,
               let http = navigationResponse.response as? HTTPURLResponse,
               http.statusCode >= 400 {
                suppressNextFailure = true
                parent.isLoading?.wrappedValue = false
                parent.loadError?.wrappedValue = NSError(
                    domain: "InAppWebView",
                    code: http.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: "Errore \(http.statusCode)"]
                )
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading?.wrappedValue = false
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            report(error)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            report(error)
        }

        private func report(_ error: Error) {
            // Swallow the cancellation that follows our deliberate 4xx/5xx rejection so
            // the specific HTTP-status error is preserved.
            if suppressNextFailure { suppressNextFailure = false; return }
            // A superseded navigation reports `NSURLErrorCancelled` — not a real failure,
            // so it must not flip the UI into the error state.
            if (error as NSError).code == NSURLErrorCancelled { return }
            parent.isLoading?.wrappedValue = false
            parent.loadError?.wrappedValue = error
        }
    }
}
