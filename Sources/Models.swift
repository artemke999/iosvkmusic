import CryptoKit
import Foundation
import UIKit

enum RepeatMode: String, Codable, CaseIterable {
    case none
    case all
    case one
}

struct EQBandInfo: Identifiable {
    let index: Int
    let frequencyHz: Float
    let shortLabel: String
    let roleLabel: String

    var id: Int { index }

    static let sixBands: [EQBandInfo] = [
        EQBandInfo(index: 0, frequencyHz: 60, shortLabel: "60 Гц", roleLabel: "Саб / 808"),
        EQBandInfo(index: 1, frequencyHz: 150, shortLabel: "150 Гц", roleLabel: "Панч"),
        EQBandInfo(index: 2, frequencyHz: 400, shortLabel: "400 Гц", roleLabel: "Тепло / муть"),
        EQBandInfo(index: 3, frequencyHz: 1000, shortLabel: "1 кГц", roleLabel: "Вокал"),
        EQBandInfo(index: 4, frequencyHz: 3200, shortLabel: "3.2 кГц", roleLabel: "Атака / снейр"),
        EQBandInfo(index: 5, frequencyHz: 10000, shortLabel: "10 кГц", roleLabel: "Воздух / глитч")
    ]
}

enum EQPreset: String, CaseIterable, Codable, Identifiable {
    case airpodsHyperpop
    case sqworeHyperpop
    case antipopGlitch
    case airpodsIdeal
    case bass808
    case dream17Night
    case flat
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .airpodsHyperpop: return "AirPods 3 × Hyperpop"
        case .sqworeHyperpop: return "Sqwore Hyperpop"
        case .antipopGlitch: return "Antipop / Glitch"
        case .airpodsIdeal: return "AirPods 3 · Ориг"
        case .bass808: return "808 Bass Boost"
        case .dream17Night: return "Dream 17 Night"
        case .flat: return "Flat (0 dB)"
        case .custom: return "Свой"
        }
    }

    var subtitle: String {
        switch self {
        case .airpodsHyperpop: return "+саб и яркие синты специально под вкладыши AirPods 3"
        case .sqworeHyperpop: return "Плотнее 808, чистая середина и воздушные верха"
        case .antipopGlitch: return "Хрустящая атака, поджатый 400 Гц, резкий верх"
        case .airpodsIdeal: return "Выравнивает открытую посадку AirPods 3 (оригинал)"
        case .bass808: return "Максимальный упор на низ и саб-бас без каши"
        case .dream17Night: return "Мягкий ночной баланс, без режущей середины"
        case .flat: return "Нулевая кривая без окраса (0 дБ)"
        case .custom: return "Ручная настройка полос"
        }
    }

    var defaultGains: [Float] {
        switch self {
        case .airpodsHyperpop: return [6.0, 2.0, -2.0, 1.0, 2.5, 4.5]
        case .sqworeHyperpop: return [5.5, 2.5, -2.0, 0.5, 3.0, 4.5]
        case .antipopGlitch: return [4.5, 1.0, -2.5, 1.5, 3.5, 3.5]
        case .airpodsIdeal: return [4.0, 1.0, -1.5, 0.5, 1.5, 3.0]
        case .bass808: return [7.5, 4.0, -1.5, 0.0, 1.0, 2.0]
        case .dream17Night: return [3.5, 2.0, 0.0, -1.0, 1.0, 3.5]
        case .flat: return [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        case .custom: return [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        }
    }

    static var selectablePresets: [EQPreset] {
        [.airpodsHyperpop, .sqworeHyperpop, .antipopGlitch, .airpodsIdeal, .bass808, .dream17Night, .flat]
    }
}

struct VKTrack: Identifiable, Hashable, Codable {
    let id: Int64
    let ownerId: Int64
    let artist: String
    let title: String
    let albumTitle: String
    let duration: Int
    let url: String
    let coverUrl: String

    var fullId: String { "\(ownerId)_\(id)" }

    var durationText: String {
        let m = max(0, duration) / 60
        let s = max(0, duration) % 60
        return String(format: "%d:%02d", m, s)
    }

    var safeFilenameBase: String {
        LocalStorage.sanitizeFilename("\(artist) - \(title)")
    }
}

struct VKPlaylist: Identifiable, Hashable, Codable {
    let id: Int64
    let ownerId: Int64
    let title: String
    let count: Int
    let accessKey: String
    var coverUrl: String

    var fullId: String { "\(ownerId)_\(id)" }

    init(
        id: Int64,
        ownerId: Int64,
        title: String,
        count: Int,
        accessKey: String,
        coverUrl: String = ""
    ) {
        self.id = id
        self.ownerId = ownerId
        self.title = title
        self.count = count
        self.accessKey = accessKey
        self.coverUrl = coverUrl
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(Int64.self, forKey: .id)
        self.ownerId = try c.decode(Int64.self, forKey: .ownerId)
        self.title = try c.decode(String.self, forKey: .title)
        self.count = try c.decode(Int.self, forKey: .count)
        self.accessKey = try c.decodeIfPresent(String.self, forKey: .accessKey) ?? ""
        self.coverUrl = try c.decodeIfPresent(String.self, forKey: .coverUrl) ?? ""
    }
}

struct VKOfflinePlaylist: Identifiable, Hashable, Codable {
    var playlist: VKPlaylist
    var tracks: [VKTrack]
    var updatedAt: Date

    var id: String { playlist.fullId }
}

struct VKUserInfo: Codable {
    let id: Int64
    let name: String
}

enum AppSection: Hashable {
    case myMusic
    case recentlyPlayed
    case recommendations
    case popular
    case downloaded
    case playlist(VKPlaylist)
    case search(String)

    var title: String {
        switch self {
        case .myMusic: return "Моя музыка"
        case .recentlyPlayed: return "Недавно"
        case .recommendations: return "Рекомендации"
        case .popular: return "Популярное"
        case .downloaded: return "На диске"
        case .playlist(let pl): return pl.title
        case .search(let q): return "Поиск: \(q)"
        }
    }
}

enum LocalStorage {
    static var downloadsDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Downloads", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    static var offlineIndexFile: URL {
        downloadsDirectory.appendingPathComponent(".tracks_index.json")
    }

    static var cachedPlaylistsFile: URL {
        downloadsDirectory.appendingPathComponent(".cached_playlists.json")
    }

    static var offlinePlaylistsFile: URL {
        downloadsDirectory.appendingPathComponent(".offline_playlists.json")
    }

    static var coversCacheDirectory: URL {
        let dir = downloadsDirectory.appendingPathComponent(".covers", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    static var recentTracksFile: URL {
        downloadsDirectory.appendingPathComponent(".recent_tracks.json")
    }

    static var audioCacheDirectory: URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("vk_audio_cache", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    static func sanitizeFilename(_ raw: String) -> String {
        let invalid = CharacterSet(charactersIn: "\\/*?:\"<>|\r\n\t")
        let replaced = raw.unicodeScalars.map { invalid.contains($0) ? "_" : String($0) }.joined()
        let collapsed = replaced.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
        let trimmed = collapsed.trimmingCharacters(in: CharacterSet(charactersIn: ". "))
        let truncated = String(trimmed.prefix(140)).trimmingCharacters(in: CharacterSet(charactersIn: ". "))
        return truncated.isEmpty ? "track" : truncated
    }

    static func findDownloadedFile(for track: VKTrack) -> URL? {
        let base = track.safeFilenameBase
        let dir = downloadsDirectory
        for ext in ["mp3", "aac"] {
            let candidate = dir.appendingPathComponent("\(base).\(ext)")
            if let attrs = try? FileManager.default.attributesOfItem(atPath: candidate.path),
               let size = attrs[.size] as? NSNumber,
               size.intValue > 0 {
                return candidate
            }
        }
        return nil
    }

    static func downloadedFilenamesSet() -> Set<String> {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: downloadsDirectory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }
        var set = Set<String>()
        for f in files where ["mp3", "aac"].contains(f.pathExtension.lowercased()) {
            set.insert(f.lastPathComponent)
        }
        return set
    }

    static func hasDownloadedFile(for track: VKTrack, in filenames: Set<String>) -> Bool {
        let base = track.safeFilenameBase
        return filenames.contains("\(base).mp3") || filenames.contains("\(base).aac")
    }

    static func saveOfflineMetadata(_ tracks: [VKTrack]) {
        guard let data = try? JSONEncoder().encode(tracks) else { return }
        try? data.write(to: offlineIndexFile, options: .atomic)
    }

    static func saveCachedPlaylists(_ playlists: [VKPlaylist]) {
        guard let data = try? JSONEncoder().encode(playlists) else { return }
        try? data.write(to: cachedPlaylistsFile, options: .atomic)
    }

    static func loadCachedPlaylists() -> [VKPlaylist] {
        guard let data = try? Data(contentsOf: cachedPlaylistsFile),
              let decoded = try? JSONDecoder().decode([VKPlaylist].self, from: data) else {
            return []
        }
        return decoded
    }

    static func loadAllSavedPlaylistRecords() -> [VKOfflinePlaylist] {
        guard let data = try? Data(contentsOf: offlinePlaylistsFile),
              let decoded = try? JSONDecoder().decode([VKOfflinePlaylist].self, from: data) else {
            return []
        }
        return decoded
    }

    static func savePlaylistTracks(playlist: VKPlaylist, tracks: [VKTrack]) {
        var all = loadAllSavedPlaylistRecords()
        var plToSave = playlist
        if plToSave.coverUrl.isEmpty,
           let firstCover = tracks.first(where: { !$0.coverUrl.isEmpty })?.coverUrl {
            plToSave.coverUrl = firstCover
        }
        let record = VKOfflinePlaylist(playlist: plToSave, tracks: tracks, updatedAt: Date())
        if let idx = all.firstIndex(where: { $0.id == record.id }) {
            all[idx] = record
        } else {
            all.insert(record, at: 0)
        }
        if let data = try? JSONEncoder().encode(all) {
            try? data.write(to: offlinePlaylistsFile, options: .atomic)
        }
    }

    static func loadPlaylistTracks(playlistFullId: String) -> [VKTrack]? {
        loadAllSavedPlaylistRecords().first(where: { $0.id == playlistFullId })?.tracks
    }

    static func loadOfflinePlaylistsWithAvailableFiles() -> [VKOfflinePlaylist] {
        let filenames = downloadedFilenamesSet()
        guard !filenames.isEmpty else { return [] }

        var groups: [VKOfflinePlaylist] = []
        var groupedTrackIds = Set<String>()
        var existingTitles = Set<String>()

        for rec in loadAllSavedPlaylistRecords() {
            let available = rec.tracks.filter { hasDownloadedFile(for: $0, in: filenames) }
            if !available.isEmpty {
                var pl = rec.playlist
                if pl.coverUrl.isEmpty, let fc = available.first(where: { !$0.coverUrl.isEmpty })?.coverUrl {
                    pl.coverUrl = fc
                }
                groups.append(VKOfflinePlaylist(playlist: pl, tracks: available, updatedAt: rec.updatedAt))
                existingTitles.insert(pl.title.lowercased())
                for t in available { groupedTrackIds.insert(t.fullId) }
            }
        }

        // Also group individually downloaded album tracks by albumTitle if not already in a playlist
        let offlineTracks = loadOfflineTracks()
        var byAlbum: [String: [VKTrack]] = [:]
        var albumOrder: [String] = []
        for tr in offlineTracks where !groupedTrackIds.contains(tr.fullId) {
            let alb = tr.albumTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !alb.isEmpty, !existingTitles.contains(alb.lowercased()) else { continue }
            if byAlbum[alb] == nil {
                albumOrder.append(alb)
                byAlbum[alb] = []
            }
            byAlbum[alb]?.append(tr)
        }

        for alb in albumOrder {
            guard let items = byAlbum[alb], items.count >= 2 else { continue }
            let cover = items.first(where: { !$0.coverUrl.isEmpty })?.coverUrl ?? ""
            let synthId = -Int64(abs(alb.hashValue) + 1)
            let pl = VKPlaylist(
                id: synthId,
                ownerId: 0,
                title: alb,
                count: items.count,
                accessKey: "",
                coverUrl: cover
            )
            groups.append(VKOfflinePlaylist(playlist: pl, tracks: items, updatedAt: Date()))
        }

        return groups
    }

    static func loadOfflineTracks() -> [VKTrack] {
        var result: [VKTrack] = []
        var seenFiles = Set<String>()

        if let data = try? Data(contentsOf: offlineIndexFile),
           let indexed = try? JSONDecoder().decode([VKTrack].self, from: data) {
            for tr in indexed {
                if let url = findDownloadedFile(for: tr) {
                    seenFiles.insert(url.lastPathComponent)
                    result.append(tr)
                }
            }
        }

        // Also pick up any manually placed mp3/aac files inside Documents/Downloads
        if let files = try? FileManager.default.contentsOfDirectory(at: downloadsDirectory, includingPropertiesForKeys: nil) {
            for file in files where ["mp3", "aac"].contains(file.pathExtension.lowercased()) {
                if seenFiles.contains(file.lastPathComponent) { continue }
                let stem = file.deletingPathExtension().lastPathComponent
                let parts = stem.components(separatedBy: " - ")
                let artist = parts.count >= 2 ? parts[0] : "Локальный файл"
                let title = parts.count >= 2 ? parts.dropFirst().joined(separator: " - ") : stem
                let fakeId = Int64(abs(file.lastPathComponent.hashValue))
                result.append(VKTrack(
                    id: fakeId,
                    ownerId: 0,
                    artist: artist,
                    title: title,
                    albumTitle: "",
                    duration: 0,
                    url: file.absoluteString,
                    coverUrl: ""
                ))
            }
        }
        return result
    }

    static func loadRecentTracks() -> [VKTrack] {
        guard let data = try? Data(contentsOf: recentTracksFile),
              let decoded = try? JSONDecoder().decode([VKTrack].self, from: data) else {
            return []
        }
        return decoded
    }

    static func saveRecentTracks(_ tracks: [VKTrack]) {
        guard let data = try? JSONEncoder().encode(tracks) else { return }
        try? data.write(to: recentTracksFile, options: .atomic)
    }

    static func recordRecentTrack(_ track: VKTrack) -> [VKTrack] {
        var list = loadRecentTracks()
        list.removeAll { $0.fullId == track.fullId }
        list.insert(track, at: 0)
        if list.count > 200 {
            list = Array(list.prefix(200))
        }
        saveRecentTracks(list)
        return list
    }

    static func clearRecentTracks() {
        try? FileManager.default.removeItem(at: recentTracksFile)
    }

    static func findCachedAudioFile(for track: VKTrack) -> URL? {
        let dir = audioCacheDirectory
        for ext in ["mp3", "aac"] {
            let candidate = dir.appendingPathComponent("\(track.fullId).\(ext)")
            if let attrs = try? FileManager.default.attributesOfItem(atPath: candidate.path),
               let size = attrs[.size] as? NSNumber,
               size.intValue > 0 {
                return candidate
            }
        }
        return nil
    }

    static func storeCachedAudioFile(data: Data, for track: VKTrack, ext: String) throws -> URL {
        let dir = audioCacheDirectory
        for oldExt in ["mp3", "aac"] where oldExt != ext {
            let stale = dir.appendingPathComponent("\(track.fullId).\(oldExt)")
            try? FileManager.default.removeItem(at: stale)
        }
        let target = dir.appendingPathComponent("\(track.fullId).\(ext)")
        try data.write(to: target, options: .atomic)
        trimCacheIfNeeded(in: dir, maxFiles: 12)
        return target
    }

    private static func trimCacheIfNeeded(in dir: URL, maxFiles: Int) {
        let keys: [URLResourceKey] = [.contentModificationDateKey]
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles]
        ), files.count > maxFiles else {
            return
        }
        let sorted = files.sorted { lhs, rhs in
            let lDate = (try? lhs.resourceValues(forKeys: Set(keys)).contentModificationDate) ?? .distantPast
            let rDate = (try? rhs.resourceValues(forKeys: Set(keys)).contentModificationDate) ?? .distantPast
            return lDate < rDate
        }
        let excess = sorted.count - maxFiles
        for file in sorted.prefix(excess) {
            try? FileManager.default.removeItem(at: file)
        }
    }
}

@MainActor
final class CoverImageCache {
    static let shared = CoverImageCache()

    private let memory = NSCache<NSString, UIImage>()
    private var inFlight: [String: Task<UIImage?, Never>] = [:]
    private let session: URLSession

    private init() {
        memory.countLimit = 400
        memory.totalCostLimit = 48 * 1024 * 1024
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 12
        cfg.httpMaximumConnectionsPerHost = 6
        self.session = URLSession(configuration: cfg)
    }

    private func diskFileURL(for urlString: String) -> URL {
        let digest = SHA256.hash(data: Data(urlString.utf8))
        let hex = digest.map { String(format: "%02x", $0) }.joined()
        return LocalStorage.coversCacheDirectory.appendingPathComponent("\(hex).img")
    }

    func cachedImage(for urlString: String) -> UIImage? {
        guard !urlString.isEmpty else { return nil }
        if let hit = memory.object(forKey: urlString as NSString) {
            return hit
        }
        let diskURL = diskFileURL(for: urlString)
        if let data = try? Data(contentsOf: diskURL),
           let img = UIImage(data: data) {
            let cost = Int(img.size.width * img.size.height * img.scale * 4)
            memory.setObject(img, forKey: urlString as NSString, cost: max(1, cost))
            return img
        }
        return nil
    }

    func image(for urlString: String) async -> UIImage? {
        guard !urlString.isEmpty else { return nil }
        if let hit = cachedImage(for: urlString) {
            return hit
        }
        if let existingTask = inFlight[urlString] {
            return await existingTask.value
        }
        guard let url = URL(string: urlString) else { return nil }

        let diskURL = diskFileURL(for: urlString)
        let session = self.session
        let task = Task<UIImage?, Never> {
            let loaded: (UIImage, Data)? = await Task.detached(priority: .utility) {
                var req = URLRequest(url: url)
                req.setValue(
                    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
                    forHTTPHeaderField: "User-Agent"
                )
                guard let (data, resp) = try? await session.data(for: req) else { return nil }
                if let http = resp as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                    return nil
                }
                guard let img = UIImage(data: data) else { return nil }
                try? data.write(to: diskURL, options: .atomic)
                return (img, data)
            }.value

            guard let (img, _) = loaded else { return nil }
            let cost = Int(img.size.width * img.size.height * img.scale * 4)
            self.memory.setObject(img, forKey: urlString as NSString, cost: max(1, cost))
            return img
        }

        inFlight[urlString] = task
        let result = await task.value
        inFlight.removeValue(forKey: urlString)
        return result
    }
}
