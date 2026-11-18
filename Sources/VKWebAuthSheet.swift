import SwiftUI
import WebKit

struct VKWebAuthSheet: View {
    @EnvironmentObject var vkClient: VKAPIClient
    @Environment(\.dismiss) private var dismiss

    @AppStorage("ui_theme") private var rawTheme: String = AppThemeKind.skyShards.rawValue
    @State private var statusMessage: String = "Войдите в аккаунт VK ниже"
    @State private var isExchanging: Bool = false
    @State private var showManualToken: Bool = false
    @State private var manualTokenInput: String = ""

    private var themeKind: AppThemeKind {
        AppThemeKind(rawValue: rawTheme) ?? .skyShards
    }

    private var palette: ThemePalette {
        ThemePalette(themeKind)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(isExchanging ? Color.green : palette.accent)
                        .frame(width: 7, height: 7)
                    Text(statusMessage)
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundColor(palette.textSecondary)
                        .lineLimit(1)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(palette.surface)
                .overlay(
                    Rectangle()
                        .fill(palette.border)
                        .frame(height: 1),
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
                        Text(showManualToken ? "Скрыть ручной ввод" : "Или вставить токен вручную")
                            .font(.system(size: 11.5, weight: .semibold))
                            .foregroundColor(palette.textSecondary)
                    }

                    if showManualToken {
                        HStack(spacing: 8) {
                            TextField("vk1.a...", text: $manualTokenInput)
                                .textFieldStyle(.plain)
                                .font(.system(size: 12.5).monospaced())
                                .foregroundColor(palette.textPrimary)
                                .padding(9)
                                .background(palette.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 9))
                                .overlay(RoundedRectangle(cornerRadius: 9).stroke(palette.border, lineWidth: 1))

                            Button("Войти") {
                                vkClient.updateManualToken(manualTokenInput)
                                dismiss()
                            }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(palette.pillText)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(palette.pillBg)
                            .clipShape(Capsule())
                        }
                    }
                }
                .padding(12)
                .background(palette.bgBottom)
                .overlay(
                    Rectangle()
                        .fill(palette.border)
                        .frame(height: 1),
                    alignment: .top
                )
            }
            .background(palette.bgTop)
            .navigationTitle("Вход в VK")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
        .preferredColorScheme(themeKind.colorScheme)
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
