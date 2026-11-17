import CommonCrypto
import Foundation

enum HLSDemuxer {
    static func tryM3u8ToMp3Url(_ urlString: String) -> URL? {
        let parts = urlString.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false)
        let pathPart = String(parts[0])
        let queryPart = parts.count > 1 ? String(parts[1]) : nil

        guard pathPart.hasSuffix("/index.m3u8") else { return nil }

        let mp3Path: String
        if let audiosRange = pathPart.range(of: "/audios/") {
            let beforeAudios = String(pathPart[..<audiosRange.lowerBound])
            let afterAudios = String(pathPart[audiosRange.lowerBound...])
            guard let segSlash = beforeAudios.lastIndex(of: "/"),
                  afterAudios.hasSuffix("/index.m3u8") else {
                return nil
            }
            let prefix = String(beforeAudios[..<segSlash])
            let trimmedAfter = String(afterAudios.dropLast("/index.m3u8".count))
            mp3Path = prefix + trimmedAfter + ".mp3"
        } else {
            let withoutIndex = String(pathPart.dropLast("/index.m3u8".count))
            guard let hashSlash = withoutIndex.lastIndex(of: "/") else { return nil }
            mp3Path = String(withoutIndex[..<hashSlash]) + ".mp3"
        }

        let full = queryPart.map { "\(mp3Path)?\($0)" } ?? mp3Path
        return URL(string: full)
    }

    static func fetchHLSAsAAC(from m3u8URL: URL, session: URLSession, userAgent: String) async throws -> Data {
        try await fetchHLSInner(url: m3u8URL, session: session, userAgent: userAgent, depth: 0)
    }

    private static func fetchHLSInner(url: URL, session: URLSession, userAgent: String, depth: Int) async throws -> Data {
        guard depth <= 2 else {
            throw NSError(domain: "HLSDemuxer", code: -1, userInfo: [NSLocalizedDescriptionKey: "Слишком глубокий m3u8 плейлист"])
        }

        let playlistData = try await fetchData(url: url, session: session, userAgent: userAgent)
        guard let playlistText = String(data: playlistData, encoding: .utf8) else {
            throw NSError(domain: "HLSDemuxer", code: -2, userInfo: [NSLocalizedDescriptionKey: "Неверный формат m3u8"])
        }

        var mediaSeq: UInt64 = 0
        var keyCache: [String: Data] = [:]
        var currentKeyURL: URL?
        var currentIV: Data?
        var segIdx: UInt64 = 0
        var outAAC = Data()

        let lines = playlistText.components(separatedBy: .newlines)
        for rawLine in lines {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty { continue }

            if line.hasPrefix("#EXT-X-MEDIA-SEQUENCE:") {
                let val = line.replacingOccurrences(of: "#EXT-X-MEDIA-SEQUENCE:", with: "").trimmingCharacters(in: .whitespaces)
                mediaSeq = UInt64(val) ?? 0
                continue
            }

            if line.hasPrefix("#EXT-X-KEY:") {
                if line.contains("METHOD=NONE") {
                    currentKeyURL = nil
                    currentIV = nil
                } else if line.contains("METHOD=AES-128") {
                    if let uri = extractAttribute(line, prefix: "URI=\"", suffix: "\"") {
                        currentKeyURL = URL(string: uri, relativeTo: url)?.absoluteURL
                    }
                    if let ivHex = extractAttribute(line, prefix: "IV=0x", suffix: ",")
                        ?? line.components(separatedBy: "IV=0x").dropFirst().first {
                        currentIV = parseHexIV(ivHex)
                    }
                }
                continue
            }

            if line.hasPrefix("#") { continue }

            let cleanPath = line.split(separator: "?", maxSplits: 1).first.map(String.init) ?? line
            if cleanPath.hasSuffix(".m3u8") || line.contains(".m3u8?") {
                if let subURL = URL(string: line, relativeTo: url)?.absoluteURL {
                    return try await fetchHLSInner(url: subURL, session: session, userAgent: userAgent, depth: depth + 1)
                }
            }

            guard let segURL = URL(string: line, relativeTo: url)?.absoluteURL else { continue }
            var segBytes = try await fetchData(url: segURL, session: session, userAgent: userAgent)

            if let keyURL = currentKeyURL {
                let keyData: Data
                if let cached = keyCache[keyURL.absoluteString] {
                    keyData = cached
                } else {
                    let fetched = try await fetchData(url: keyURL, session: session, userAgent: userAgent)
                    keyCache[keyURL.absoluteString] = fetched
                    keyData = fetched
                }

                let ivData: Data
                if let iv = currentIV {
                    ivData = iv
                } else {
                    var bytes = [UInt8](repeating: 0, count: 16)
                    var bigEndianSeq = (mediaSeq + segIdx).bigEndian
                    withUnsafeBytes(of: &bigEndianSeq) { ptr in
                        for idx in 0..<8 {
                            bytes[8 + idx] = ptr[idx]
                        }
                    }
                    ivData = Data(bytes)
                }

                if keyData.count == kCCKeySizeAES128 && !segBytes.isEmpty {
                    segBytes = try decryptAES128CBC(data: segBytes, key: keyData, iv: ivData)
                }
            }

            demuxTSAudio(tsData: segBytes, into: &outAAC)
            segIdx += 1
        }

        if outAAC.isEmpty {
            throw NSError(domain: "HLSDemuxer", code: -3, userInfo: [NSLocalizedDescriptionKey: "Не удалось извлечь аудио из HLS"])
        }
        return outAAC
    }

    private static func fetchData(url: URL, session: URLSession, userAgent: String) async throws -> Data {
        var req = URLRequest(url: url)
        req.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        let (data, resp) = try await session.data(for: req)
        if let http = resp as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw NSError(domain: "HLSDemuxer", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode)"])
        }
        return data
    }

    private static func extractAttribute(_ line: String, prefix: String, suffix: String) -> String? {
        guard let startRange = line.range(of: prefix) else { return nil }
        let rest = line[startRange.upperBound...]
        if let endRange = rest.range(of: suffix) {
            return String(rest[..<endRange.lowerBound])
        }
        return String(rest)
    }

    private static func parseHexIV(_ hex: String) -> Data? {
        let clean = String(hex.prefix { $0.isHexDigit })
        guard clean.count == 32 else { return nil }
        var bytes: [UInt8] = []
        bytes.reserveCapacity(16)
        var idx = clean.startIndex
        for _ in 0..<16 {
            let nextIdx = clean.index(idx, offsetBy: 2)
            guard let b = UInt8(clean[idx..<nextIdx], radix: 16) else { return nil }
            bytes.append(b)
            idx = nextIdx
        }
        return Data(bytes)
    }

    private static func decryptAES128CBC(data: Data, key: Data, iv: Data) throws -> Data {
        let outLength = data.count + kCCBlockSizeAES128
        var outData = Data(count: outLength)
        var numBytesDecrypted: size_t = 0

        let status = outData.withUnsafeMutableBytes { outBytes in
            data.withUnsafeBytes { inBytes in
                key.withUnsafeBytes { keyBytes in
                    iv.withUnsafeBytes { ivBytes in
                        CCCrypt(
                            CCOperation(kCCDecrypt),
                            CCAlgorithm(kCCAlgorithmAES),
                            CCOptions(kCCOptionPKCS7Padding),
                            keyBytes.baseAddress, kCCKeySizeAES128,
                            ivBytes.baseAddress,
                            inBytes.baseAddress, data.count,
                            outBytes.baseAddress, outLength,
                            &numBytesDecrypted
                        )
                    }
                }
            }
        }

        guard status == CCCryptorStatus(kCCSuccess) else {
            throw NSError(domain: "HLSDemuxer", code: Int(status), userInfo: [NSLocalizedDescriptionKey: "AES decrypt err \(status)"])
        }
        outData.removeSubrange(numBytesDecrypted..<outData.count)
        return outData
    }

    private static func demuxTSAudio(tsData: Data, into out: inout Data) {
        let bytes = [UInt8](tsData)
        var audioPID: UInt16?
        var i = 0
        while i < bytes.count && bytes[i] != 0x47 {
            i += 1
        }
        while i + 188 <= bytes.count {
            let pkt = bytes[i..<(i + 188)]
            i += 188
            let base = pkt.startIndex
            guard pkt[base] == 0x47 else { continue }

            let pusi = (pkt[base + 1] & 0x40) != 0
            let pid = (UInt16(pkt[base + 1] & 0x1F) << 8) | UInt16(pkt[base + 2])
            let afc = (pkt[base + 3] >> 4) & 0x03
            if afc == 0 || afc == 2 { continue }

            var offset = 4
            if afc == 3 {
                offset = 5 + Int(pkt[base + 4])
            }
            if offset >= 188 { continue }

            let payloadStart = base + offset
            let payloadLen = (base + 188) - payloadStart

            if pusi && payloadLen >= 9 && pkt[payloadStart] == 0 && pkt[payloadStart + 1] == 0 && pkt[payloadStart + 2] == 1 {
                let streamId = pkt[payloadStart + 3]
                if (0xC0...0xDF).contains(streamId) {
                    audioPID = pid
                    let pesHeaderLen = 9 + Int(pkt[payloadStart + 8])
                    if pesHeaderLen < payloadLen {
                        out.append(contentsOf: pkt[(payloadStart + pesHeaderLen)..<(base + 188)])
                    }
                }
            } else if pid == audioPID {
                out.append(contentsOf: pkt[payloadStart..<(base + 188)])
            }
        }
    }
}
