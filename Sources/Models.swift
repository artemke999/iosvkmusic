import Foundation

enum RepeatMode: String, Codable, CaseIterable {
    case none
    case all
    case one
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

    static func saveOfflineMetadata(_ tracks: [VKTrack]) {
        guard let data = try? JSONEncoder().encode(tracks) else { return }
        try? data.write(to: offlineIndexFile, options: .atomic)
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
