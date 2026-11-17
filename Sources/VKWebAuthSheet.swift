import SwiftUI
import WebKit

struct VKWebAuthSheet: View {
    @EnvironmentObject var vkClient: VKAPIClient
    @Environment(\.dismiss) private var dismiss

    @State private var statusMessage: String = "Войдите в аккаунт VK ниже"
    @State private var isExchanging: Bool = false
    @State private var showManualToken: Bool = false
    @State private var manualTokenInput: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Circle()
                        .fill(isExchanging ? Color(red: 0.19, green: 0.82, blue: 0.35) : Color.gray.opacity(0.6))
                        .frame(width: 8, height: 8)
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundColor(Color(red: 0.56, green: 0.56, blue: 0.60))
                        .lineLimit(1)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(red: 0.075, green: 0.075, blue: 0.09))

                VKLoginWebView(
                    onCookiesFound: { cookies in
                        guard !isExchanging else { return }
                        isExchanging = true
                        statusMessage = "Сессия получена, подключаем медиатеку..."
                        Task {
                            do {
                                try await vkClient.finishWebLogin(cookies: cookies)
                                dismiss()
                            } catch {
                                isExchanging = false
                                statusMessage = error.localizedDescription
                            }
                        }
                    }
                )
                .ignoresSafeArea(edges: .bottom)

                VStack(spacing: 8) {
                    Button {
                        withAnimation { showManualToken.toggle() }
                    } label: {
                        Text(showManualToken ? "Скрыть ручной ввод" : "Или вставить токен вручную")
                            .font(.caption)
                            .foregroundColor(Color(red: 0.56, green: 0.56, blue: 0.60))
                    }

                    if showManualToken {
                        HStack(spacing: 8) {
                            TextField("vk1.a...", text: $manualTokenInput)
                                .textFieldStyle(.plain)
                                .font(.system(size: 13, design: .monospaced))
                                .padding(10)
                                .background(Color(red: 0.094, green: 0.094, blue: 0.114))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(red: 0.14, green: 0.14, blue: 0.165), lineWidth: 1)
                                )

                            Button("Войти") {
                                vkClient.updateManualToken(manualTokenInput)
                                dismiss()
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color(red: 0.95, green: 0.95, blue: 0.953))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(12)
                .background(Color(red: 0.063, green: 0.063, blue: 0.075))
            }
            .background(Color(red: 0.04, green: 0.04, blue: 0.047))
            .navigationTitle("Вход в VK")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct VKLoginWebView: UIViewRepresentable {
    let onCookiesFound: ([String: String]) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onCookiesFound: onCookiesFound)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.customUserAgent = VKAPIClient.webUserAgent
        if let url = URL(string: "https://vk.ru/audios0") {
            webView.load(URLRequest(url: url))
        }
        context.coordinator.startPolling()
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        coordinator.stopPolling()
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        private let onCookiesFound: ([String: String]) -> Void
        private var timer: Timer?
        private var captured = false

        init(onCookiesFound: @escaping ([String: String]) -> Void) {
            self.onCookiesFound = onCookiesFound
        }

        func startPolling() {
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { [weak self] _ in
                self?.checkCookies()
            }
        }

        func stopPolling() {
            timer?.invalidate()
            timer = nil
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            checkCookies()
        }

        private func checkCookies() {
            guard !captured else { return }
            WKWebsiteDataStore.default().httpCookieStore.getAllCookies { [weak self] allCookies in
                let map = VKAPIClient.extractVKCookieMap(from: allCookies)
                let hasSid = map["remixsid"] != nil || map["remixnsid"] != nil
                let hasP = map["p"] != nil
                if hasSid && hasP {
                    DispatchQueue.main.async {
                        guard let self, !self.captured else { return }
                        self.captured = true
                        self.stopPolling()
                        self.onCookiesFound(map)
                    }
                }
            }
        }
    }
}
