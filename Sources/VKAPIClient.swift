import Foundation
import WebKit

@MainActor
final class VKAPIClient: ObservableObject {
    nonisolated static let webAppId = "6287487"
    nonisolated static let webUserAgent =
        "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1"
    nonisolated static let desktopUserAgent =
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"

    @Published var user: VKUserInfo?
    @Published var playlists: [VKPlaylist] = []
    @Published var tracks: [VKTrack] = []
    @Published var currentSection: AppSection = .myMusic
    @Published var statusText: String = "Войдите в VK, чтобы загрузить музыку"
    @Published var isLoading: Bool = false
    @Published var downloadedIds: Set<String> = []
    @Published var downloadingIds: Set<String> = []
    @Published var batchDownloading: Bool = false

    private var token: String = ""
    private var cookies: [String: String] = [:]
    private var lastApiCall: Date = .distantPast
    private var isRefreshing: Bool = false

    private let session: URLSession

    private enum Keys {
        static let token = "vk_token"
        static let cookies = "vk_cookies"
        static let userId = "vk_user_id"
        static let userName = "vk_user_name"
    }

    init() {
        let cfg = URLSessionConfiguration.ephemeral
        cfg.timeoutIntervalForRequest = 20
        cfg.httpCookieAcceptPolicy = .never
        cfg.httpShouldSetCookies = false
        self.session = URLSession(configuration: cfg)

        let defaults = UserDefaults.standard
        self.token = defaults.string(forKey: Keys.token) ?? ""
        if let savedCookies = defaults.dictionary(forKey: Keys.cookies) as? [String: String] {
            self.cookies = savedCookies
        }
        let uid = defaults.object(forKey: Keys.userId) as? Int64 ?? 0
        let uname = defaults.string(forKey: Keys.userName) ?? ""
        if uid > 0 && !uname.isEmpty {
            self.user = VKUserInfo(id: uid, name: uname)
        }
    }

    var hasSavedSession: Bool {
        !token.isEmpty || !cookies.isEmpty
    }

    func saveSession(token: String, cookies: [String: String], user: VKUserInfo?) {
        self.token = token
        self.cookies = cookies
        let defaults = UserDefaults.standard
        defaults.set(token, forKey: Keys.token)
        defaults.set(cookies, forKey: Keys.cookies)
        if let user {
            self.user = user
            defaults.set(user.id, forKey: Keys.userId)
            defaults.set(user.name, forKey: Keys.userName)
        }
    }

    func updateManualToken(_ raw: String) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        var extracted = trimmed
        if let range = trimmed.range(of: "access_token=") {
            let after = trimmed[range.upperBound...]
            let end = after.firstIndex(where: { $0 == "&" || $0.isWhitespace }) ?? after.endIndex
            extracted = String(after[..<end])
        }
        guard !extracted.isEmpty else { return }
        self.token = extracted
        self.cookies = [:]
        self.user = nil
        let defaults = UserDefaults.standard
        defaults.set(extracted, forKey: Keys.token)
        defaults.removeObject(forKey: Keys.cookies)
        defaults.removeObject(forKey: Keys.userId)
        defaults.removeObject(forKey: Keys.userName)
        bootstrapSession()
    }

    func logout() {
        token = ""
        cookies = [:]
        user = nil
        playlists = []
        tracks = []
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: Keys.token)
        defaults.removeObject(forKey: Keys.cookies)
        defaults.removeObject(forKey: Keys.userId)
        defaults.removeObject(forKey: Keys.userName)
        statusText = "Вышли из аккаунта"
    }

    func bootstrapSession() {
        Task {
            isLoading = true
            statusText = "Подключение к VK..."
            do {
                if user == nil {
                    let info = try await verifyUser()
                    saveSession(token: token, cookies: cookies, user: info)
                }
                await loadSection(.myMusic)
                self.playlists = (try? await fetchPlaylists()) ?? []
            } catch {
                statusText = error.localizedDescription
            }
            isLoading = false
        }
    }

    func finishWebLogin(cookies newCookies: [String: String]) async throws {
        var mutable = newCookies
        let (freshToken, uid) = try await tryExchangeCookies(cookies: &mutable)
        self.token = freshToken
        self.cookies = mutable
        if uid > 0 && self.user == nil {
            self.user = VKUserInfo(id: uid, name: "VK #\(uid)")
        }
        let info = try await verifyUser()
        saveSession(token: self.token, cookies: self.cookies, user: info)
        self.playlists = (try? await fetchPlaylists()) ?? []
        await loadSection(.myMusic)
    }

    func loadSection(_ section: AppSection) async {
        currentSection = section
        if section == .downloaded {
            let offline = LocalStorage.loadOfflineTracks()
            self.tracks = offline
            refreshDownloadedSet()
            statusText = "\(offline.count) на диске"
            return
        }

        guard hasSavedSession else {
            statusText = "Войдите в VK, чтобы загрузить музыку"
            return
        }

        isLoading = true
        statusText = "Загрузка треков..."
        do {
            let loaded: [VKTrack]
            switch section {
            case .myMusic:
                loaded = try await fetchMyAudio(count: 250)
            case .recommendations:
                loaded = try await fetchRecommendations(count: 100)
            case .popular:
                loaded = try await fetchPopular(count: 100)
            case .playlist(let pl):
                loaded = try await fetchPlaylistAudio(ownerId: pl.ownerId, playlistId: pl.id, accessKey: pl.accessKey, count: 200)
            case .search(let query):
                loaded = try await searchAudio(query: query, count: 100)
            case .downloaded:
                loaded = LocalStorage.loadOfflineTracks()
            }
            self.tracks = loaded
            refreshDownloadedSet()
            statusText = "\(loaded.count) треков"
        } catch {
            statusText = error.localizedDescription
        }
        isLoading = false
    }

    func refreshDownloadedSet() {
        var set = Set<String>()
        for tr in tracks where LocalStorage.findDownloadedFile(for: tr) != nil {
            set.insert(tr.fullId)
        }
        downloadedIds = set
    }

    // MARK: - Token Refresh via Persistent Cookies & WKHTTPCookieStore

    func tryExchangeCookies(cookies: inout [String: String]) async throws -> (String, Int64) {
        guard !cookies.isEmpty else {
            throw apiError("Нет сохранённых кук сессии VK")
        }

        let cookieHeader = cookies.map { "\($0.key)=\($0.value)" }.joined(separator: "; ")
        let endpoints = [
            ("https://login.vk.ru/?act=web_token", "https://vk.ru", "https://vk.ru/"),
            ("https://login.vk.com/?act=web_token", "https://vk.com", "https://vk.com/")
        ]

        var lastMessage = "Не удалось обновить сессию VK"

        for (urlStr, origin, referer) in endpoints {
            guard let url = URL(string: urlStr) else { continue }
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue(Self.desktopUserAgent, forHTTPHeaderField: "User-Agent")
            req.setValue(origin, forHTTPHeaderField: "Origin")
            req.setValue(referer, forHTTPHeaderField: "Referer")
            req.setValue(cookieHeader, forHTTPHeaderField: "Cookie")
            req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            req.httpBody = "version=1&app_id=\(Self.webAppId)".data(using: .utf8)

            do {
                let (data, response) = try await session.data(for: req)
                if let http = response as? HTTPURLResponse {
                    mergeSetCookies(from: http, into: &cookies)
                }
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if (json["type"] as? String) == "okay",
                       let dataObj = json["data"] as? [String: Any],
                       let accessToken = dataObj["access_token"] as? String {
                        let uid = (dataObj["user_id"] as? NSNumber)?.int64Value ?? 0
                        return (accessToken, uid)
                    }
                    let info = (json["error_info"] as? String) ?? "unauthorized"
                    lastMessage = "Сессия VK недействительна (\(info)). Войдите заново."
                }
            } catch {
                lastMessage = "Ошибка сети: \(error.localizedDescription)"
            }
        }

        throw apiError(lastMessage)
    }

    private func mergeSetCookies(from response: HTTPURLResponse, into cookies: inout [String: String]) {
        guard let url = response.url else { return }
        var headers: [String: String] = [:]
        for (k, v) in response.allHeaderFields {
            if let ks = k as? String, let vs = v as? String {
                headers[ks] = vs
            }
        }
        let parsed = HTTPCookie.cookies(withResponseHeaderFields: headers, for: url)
        for c in parsed {
            if !c.value.isEmpty && c.value.uppercased() != "DELETED" {
                cookies[c.name] = c.value
            }
        }
    }

    func refreshWebToken() async throws -> String {
        while isRefreshing {
            try await Task.sleep(nanoseconds: 150_000_000)
        }
        isRefreshing = true
        defer { isRefreshing = false }

        var cookieCopy = self.cookies
        if !cookieCopy.isEmpty {
            if let (freshTok, uid) = try? await tryExchangeCookies(cookies: &cookieCopy) {
                let updatedUser = uid > 0 ? VKUserInfo(id: uid, name: self.user?.name ?? "VK #\(uid)") : self.user
                saveSession(token: freshTok, cookies: cookieCopy, user: updatedUser)
                return freshTok
            }
        }

        // Fallback: read latest cookies from WKWebsiteDataStore
        let storeCookies = await Self.readWKCookies()
        if !storeCookies.isEmpty {
            var mutableStore = storeCookies
            let (freshTok, uid) = try await tryExchangeCookies(cookies: &mutableStore)
            let updatedUser = uid > 0 ? VKUserInfo(id: uid, name: self.user?.name ?? "VK #\(uid)") : self.user
            saveSession(token: freshTok, cookies: mutableStore, user: updatedUser)
            return freshTok
        }

        throw apiError("Токен истёк. Нажмите «Войти через VK» для обновления сессии.")
    }

    static func readWKCookies() async -> [String: String] {
        let all: [HTTPCookie] = await withCheckedContinuation { cont in
            WKWebsiteDataStore.default().httpCookieStore.getAllCookies { cookies in
                cont.resume(returning: cookies)
            }
        }
        return extractVKCookieMap(from: all)
    }

    nonisolated static func extractVKCookieMap(from list: [HTTPCookie]) -> [String: String] {
        var general: [String: String] = [:]
        var loginSpecific: [String: String] = [:]
        for c in list {
            let domain = c.domain.lowercased()
            guard domain.contains("vk.ru") || domain.contains("vk.com") else { continue }
            guard !c.name.isEmpty, !c.value.isEmpty else { continue }
            if domain.contains("login.vk.") {
                loginSpecific[c.name] = c.value
            } else {
                general[c.name] = c.value
            }
        }
        for (k, v) in loginSpecific {
            general[k] = v
        }
        return general
    }

    // MARK: - VK API Transport

    private func waitRateLimit() async {
        let elapsed = Date().timeIntervalSince(lastApiCall)
        if elapsed < 0.6 {
            let waitNs = UInt64((0.6 - elapsed) * 1_000_000_000)
            try? await Task.sleep(nanoseconds: waitNs)
        }
        lastApiCall = Date()
    }

    private func callAPI(method: String, params: [String: String]) async throws -> Any {
        var activeToken = self.token
        if activeToken.isEmpty && !cookies.isEmpty {
            activeToken = try await refreshWebToken()
        }
        guard !activeToken.isEmpty else {
            throw apiError("Не выполнена авторизация VK")
        }

        guard let url = URL(string: "https://api.vk.com/method/\(method)") else {
            throw apiError("Некорректный метод VK API")
        }

        for attempt in 0..<2 {
            await waitRateLimit()

            var formParams = params
            formParams["access_token"] = activeToken
            formParams["v"] = "5.131"

            var components = URLComponents()
            components.queryItems = formParams.map { URLQueryItem(name: $0.key, value: $0.value) }
            let bodyString = components.percentEncodedQuery ?? ""

            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue(Self.desktopUserAgent, forHTTPHeaderField: "User-Agent")
            req.setValue("https://vk.ru", forHTTPHeaderField: "Origin")
            req.setValue("https://vk.ru/", forHTTPHeaderField: "Referer")
            req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            req.httpBody = bodyString.data(using: .utf8)

            let (data, _) = try await session.data(for: req)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw apiError("Некорректный ответ VK API")
            }

            if let errObj = json["error"] as? [String: Any] {
                let code = (errObj["error_code"] as? NSNumber)?.intValue ?? -1
                let msg = (errObj["error_msg"] as? String) ?? "Unknown error"

                if code == 5 && attempt == 0 {
                    activeToken = try await refreshWebToken()
                    continue
                }
                if (code == 6 || code == 9) && attempt == 0 {
                    try? await Task.sleep(nanoseconds: code == 6 ? 1_200_000_000 : 2_200_000_000)
                    continue
                }
                if code == 9 {
                    throw apiError("VK ограничил частые запросы (Flood control). Подождите 1–2 минуты.")
                }
                throw apiError("VK API [\(code)]: \(msg)")
            }

            if let response = json["response"] {
                return response
            }
            throw apiError("Пустой ответ VK API")
        }

        throw apiError("Не удалось выполнить запрос к VK")
    }

    // MARK: - Audio Endpoints

    func verifyUser() async throws -> VKUserInfo {
        let res = try await callAPI(method: "users.get", params: [:])
        guard let arr = res as? [[String: Any]], let first = arr.first else {
            throw apiError("Не удалось получить профиль")
        }
        let id = (first["id"] as? NSNumber)?.int64Value ?? 0
        let firstName = first["first_name"] as? String ?? ""
        let lastName = first["last_name"] as? String ?? ""
        let fullName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        return VKUserInfo(id: id, name: fullName.isEmpty ? "VK #\(id)" : fullName)
    }

    func fetchMyAudio(count: Int) async throws -> [VKTrack] {
        var params = ["count": "\(count)"]
        if let uid = user?.id, uid > 0 {
            params["owner_id"] = "\(uid)"
        }
        let res = try await callAPI(method: "audio.get", params: params)
        let items = (res as? [String: Any])?["items"] as? [[String: Any]] ?? []
        return parseTracks(items)
    }

    func fetchPlaylists(count: Int = 50) async throws -> [VKPlaylist] {
        guard let uid = user?.id, uid > 0 else { return [] }
        let res = try await callAPI(method: "audio.getPlaylists", params: [
            "owner_id": "\(uid)",
            "count": "\(count)"
        ])
        let items = (res as? [String: Any])?["items"] as? [[String: Any]] ?? []
        return items.map { it in
            VKPlaylist(
                id: (it["id"] as? NSNumber)?.int64Value ?? 0,
                ownerId: (it["owner_id"] as? NSNumber)?.int64Value ?? 0,
                title: (it["title"] as? String) ?? "Без названия",
                count: (it["count"] as? NSNumber)?.intValue ?? 0,
                accessKey: (it["access_key"] as? String) ?? ""
            )
        }
    }

    func fetchPlaylistAudio(ownerId: Int64, playlistId: Int64, accessKey: String, count: Int) async throws -> [VKTrack] {
        var params = [
            "owner_id": "\(ownerId)",
            "album_id": "\(playlistId)",
            "count": "\(count)"
        ]
        if !accessKey.isEmpty {
            params["access_key"] = accessKey
        }
        let res = try await callAPI(method: "audio.get", params: params)
        let items = (res as? [String: Any])?["items"] as? [[String: Any]] ?? []
        return parseTracks(items)
    }

    func searchAudio(query: String, count: Int) async throws -> [VKTrack] {
        let res = try await callAPI(method: "audio.search", params: [
            "q": query,
            "count": "\(count)",
            "auto_complete": "1",
            "sort": "2"
        ])
        let items = (res as? [String: Any])?["items"] as? [[String: Any]] ?? []
        return parseTracks(items)
    }

    func fetchRecommendations(count: Int) async throws -> [VKTrack] {
        var params = ["count": "\(count)"]
        if let uid = user?.id, uid > 0 {
            params["user_id"] = "\(uid)"
        }
        let res = try await callAPI(method: "audio.getRecommendations", params: params)
        let items = (res as? [String: Any])?["items"] as? [[String: Any]] ?? []
        return parseTracks(items)
    }

    func fetchPopular(count: Int) async throws -> [VKTrack] {
        let res = try await callAPI(method: "audio.getPopular", params: [
            "count": "\(count)",
            "only_eng": "0"
        ])
        let items = (res as? [[String: Any]])
            ?? ((res as? [String: Any])?["items"] as? [[String: Any]])
            ?? []
        return parseTracks(items)
    }

    func addAudio(track: VKTrack) async {
        do {
            _ = try await callAPI(method: "audio.add", params: [
                "owner_id": "\(track.ownerId)",
                "audio_id": "\(track.id)"
            ])
            statusText = "Добавлено: \(track.artist) — \(track.title)"
        } catch {
            statusText = "Ошибка добавления: \(error.localizedDescription)"
        }
    }

    // MARK: - Offline Downloading

    func downloadTrack(_ track: VKTrack) async {
        let fid = track.fullId
        if LocalStorage.findDownloadedFile(for: track) != nil {
            downloadedIds.insert(fid)
            return
        }
        guard !downloadingIds.contains(fid) else { return }
        downloadingIds.insert(fid)
        statusText = "Скачивание: \(track.artist) — \(track.title)..."
        defer { downloadingIds.remove(fid) }

        do {
            let savedURL = try await performDownload(track: track)
            downloadedIds.insert(fid)
            saveTrackToOfflineIndex(track)
            statusText = "Сохранено: \(savedURL.lastPathComponent)"
        } catch {
            statusText = "Ошибка скачивания: \(error.localizedDescription)"
        }
    }

    func downloadAll(_ list: [VKTrack]) async {
        guard !batchDownloading else { return }
        let pending = list.filter { LocalStorage.findDownloadedFile(for: $0) == nil }
        guard !pending.isEmpty else {
            statusText = "Все треки уже на диске"
            return
        }
        batchDownloading = true
        defer { batchDownloading = false }

        let total = pending.count
        var done = 0
        statusText = "Скачано 0 / \(total)..."

        for tr in pending {
            let fid = tr.fullId
            downloadingIds.insert(fid)
            if (try? await performDownload(track: tr)) != nil {
                downloadedIds.insert(fid)
                saveTrackToOfflineIndex(tr)
            }
            downloadingIds.remove(fid)
            done += 1
            statusText = done == total ? "Скачано \(done) / \(total) — готово" : "Скачано \(done) / \(total)..."
        }
    }

    private func performDownload(track: VKTrack) async throws -> URL {
        guard let url = URL(string: track.url) else {
            throw apiError("Неверная ссылка трека")
        }

        let fileData: Data
        let ext: String

        if track.url.contains(".m3u8") {
            if let mp3URL = HLSDemuxer.tryM3u8ToMp3Url(track.url),
               let (candidateData, resp) = try? await fetchRaw(url: mp3URL),
               (resp as? HTTPURLResponse)?.statusCode == 200,
               looksLikeMP3(candidateData) {
                fileData = candidateData
                ext = "mp3"
            } else {
                fileData = try await HLSDemuxer.fetchHLSAsAAC(from: url, session: session, userAgent: Self.desktopUserAgent)
                ext = "aac"
            }
        } else {
            let (data, resp) = try await fetchRaw(url: url)
            if let http = resp as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                throw apiError("HTTP \(http.statusCode)")
            }
            fileData = data
            ext = "mp3"
        }

        let targetURL = LocalStorage.downloadsDirectory.appendingPathComponent("\(track.safeFilenameBase).\(ext)")
        try fileData.write(to: targetURL, options: .atomic)
        return targetURL
    }

    private func fetchRaw(url: URL) async throws -> (Data, URLResponse) {
        var req = URLRequest(url: url)
        req.setValue(Self.desktopUserAgent, forHTTPHeaderField: "User-Agent")
        return try await session.data(for: req)
    }

    private func looksLikeMP3(_ data: Data) -> Bool {
        guard data.count > 16 else { return false }
        if data.prefix(3) == Data("ID3".utf8) { return true }
        return data[0] == 0xFF && (data[1] & 0xE0) == 0xE0
    }

    private func saveTrackToOfflineIndex(_ track: VKTrack) {
        var current = LocalStorage.loadOfflineTracks()
        if !current.contains(where: { $0.fullId == track.fullId }) {
            current.insert(track, at: 0)
            LocalStorage.saveOfflineMetadata(current)
        }
    }

    private func parseTracks(_ items: [[String: Any]]) -> [VKTrack] {
        items.compactMap { it in
            let url = (it["url"] as? String) ?? ""
            guard !url.isEmpty else { return nil }
            let album = it["album"] as? [String: Any]
            let thumb = album?["thumb"] as? [String: Any]
            let cover = (thumb?["photo_300"] as? String)
                ?? (thumb?["photo_270"] as? String)
                ?? (thumb?["photo_135"] as? String)
                ?? (thumb?["photo_68"] as? String)
                ?? ""

            return VKTrack(
                id: (it["id"] as? NSNumber)?.int64Value ?? 0,
                ownerId: (it["owner_id"] as? NSNumber)?.int64Value ?? 0,
                artist: (it["artist"] as? String) ?? "Unknown Artist",
                title: (it["title"] as? String) ?? "Untitled",
                albumTitle: (album?["title"] as? String) ?? "",
                duration: (it["duration"] as? NSNumber)?.intValue ?? 0,
                url: url,
                coverUrl: cover
            )
        }
    }

    private func apiError(_ message: String) -> NSError {
        NSError(domain: "VKAPIClient", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
    }
}
