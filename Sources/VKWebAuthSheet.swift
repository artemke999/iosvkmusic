import SwiftUI
import WebKit

struct VKWebAuthSheet: View {
    @EnvironmentObject var vkClient: VKAPIClient
    @Environment(\.dismiss) private var dismiss

    @AppStorage("sqwore_theme") private var rawTheme: String = SqworeThemeMode.evePaper.rawValue
    @State private var statusMessage: String = "Войдите в аккаунт VK ниже"
    @State private var isExchanging: Bool = false
    @State private var showManualToken: Bool = false
    @State private var manualTokenInput: String = ""

    private var themeMode: SqworeThemeMode {
        SqworeThemeMode(rawValue: rawTheme) ?? .evePaper
    }

    private var theme: ThemeColors {
        ThemeColors(themeMode)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(isExchanging ? theme.accentMint : theme.accentButter)
                        .frame(width: 7, height: 7)
                        .overlay(Circle().stroke(theme.ink, lineWidth: 1))
                    Text(statusMessage.uppercased())
                        .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                        .foregroundColor(theme.textSecondary)
                        .lineLimit(1)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(theme.skyPanel)
                .overlay(
                    Rectangle()
                        .fill(theme.ink)
                        .frame(height: 1.5),
                    alignment: .bottom
                )

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
                        Text(showManualToken ? "СКРЫТЬ РУЧНОЙ ВВОД" : "ИЛИ ВСТАВИТЬ ТОКЕН ВРУЧНУЮ")
                            .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                            .foregroundColor(theme.textSecondary)
                    }

                    if showManualToken {
                        HStack(spacing: 8) {
                            TextField("vk1.a...", text: $manualTokenInput)
                                .textFieldStyle(.plain)
                                .font(.system(size: 12.5, design: .monospaced))
                                .foregroundColor(theme.textPrimary)
                                .padding(9)
                                .background(theme.paper)
                                .overlay(Rectangle().stroke(theme.ink, lineWidth: 1.5))

                            Button("ВОЙТИ") {
                                vkClient.updateManualToken(manualTokenInput)
                                dismiss()
                            }
                            .font(.system(size: 11.5, weight: .black, design: .monospaced))
                            .foregroundColor(theme.buttonTextOnAccent)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background(theme.accentSky)
                            .overlay(Rectangle().stroke(theme.ink, lineWidth: 1.5))
                        }
                    }
                }
                .padding(12)
                .background(theme.canvas)
                .overlay(
                    Rectangle()
                        .fill(theme.ink)
                        .frame(height: 1.5),
                    alignment: .top
                )
            }
            .background(theme.canvas)
            .navigationTitle("Вход в VK")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
        .preferredColorScheme(themeMode.colorScheme)
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
