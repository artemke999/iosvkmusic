import AVFoundation
import Foundation
import MediaPlayer
import UIKit

@MainActor
final class AudioPlayerManager: ObservableObject {
    @Published var currentTrack: VKTrack?
    @Published var isPlaying: Bool = false
    @Published var isBuffering: Bool = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var shuffle: Bool = false
    @Published var repeatMode: RepeatMode = .none
    @Published var volume: Float = 1.0
    @Published var isMuted: Bool = false
    @Published var crossfadeSecs: Int = 1

    private var player: AVPlayer?
    private var fadingPlayer: AVPlayer?
    private var fadingStartDate: Date?
    private var fadeInStartDate: Date?
    private var activeFadeDuration: Double = 0
    private var crossfadeTimer: Timer?

    private var timeObserver: Any?
    private var endObserver: NSObjectProtocol?
    private weak var vkClient: VKAPIClient?

    private var queue: [VKTrack] = []
    private var currentIndex: Int?
    private var history: [Int] = []
    private var cachedArtwork: (String, UIImage)?

    private var loadTask: Task<Void, Never>?
    private var prefetchTask: Task<Void, Never>?
    private var loadGeneration: UInt64 = 0
    private var plannedNextIndex: Int?
    private var prefetchedNext: (trackId: String, fileURL: URL, track: VKTrack)?
    private var didTriggerTransitionForCurrent: Bool = false

    private enum Keys {
        static let shuffle = "player_shuffle"
        static let repeatMode = "player_repeat"
        static let volume = "player_volume"
        static let crossfade = "player_crossfade_secs"
    }

    init() {
        let defaults = UserDefaults.standard
        self.shuffle = defaults.bool(forKey: Keys.shuffle)
        if let rawRep = defaults.string(forKey: Keys.repeatMode),
           let mode = RepeatMode(rawValue: rawRep) {
            self.repeatMode = mode
        }
        if defaults.object(forKey: Keys.volume) != nil {
            self.volume = max(0, min(1, defaults.float(forKey: Keys.volume)))
        } else {
            self.volume = 1.0
        }
        if defaults.object(forKey: Keys.crossfade) != nil {
            let savedCf = defaults.integer(forKey: Keys.crossfade)
            self.crossfadeSecs = [0, 1, 2, 3, 5].contains(savedCf) ? savedCf : 1
        } else {
            self.crossfadeSecs = 1
        }
        setupAudioSession()
        setupRemoteCommands()
    }

    func configure(vkClient: VKAPIClient) {
        self.vkClient = vkClient
    }

    var effectiveVolume: Float {
        if isMuted || volume <= 0.0001 {
            return 0
        }
        let clamped = max(0, min(1, volume))
        return clamped * clamped * clamped
    }

    func setVolume(_ newVolume: Float) {
        let clamped = max(0, min(1, newVolume))
        volume = clamped
        if clamped > 0 && isMuted {
            isMuted = false
        }
        UserDefaults.standard.set(clamped, forKey: Keys.volume)
        applyCurrentVolume()
    }

    func adjustVolume(by delta: Float) {
        setVolume(volume + delta)
    }

    func toggleMute() {
        isMuted.toggle()
        applyCurrentVolume()
    }

    func cycleCrossfade() {
        switch crossfadeSecs {
        case 0: crossfadeSecs = 1
        case 1: crossfadeSecs = 2
        case 2: crossfadeSecs = 3
        case 3: crossfadeSecs = 5
        default: crossfadeSecs = 0
        }
        UserDefaults.standard.set(crossfadeSecs, forKey: Keys.crossfade)
        prepareNextTrack()
    }

    private func currentFadeInFactor() -> Float {
        guard let start = fadeInStartDate, activeFadeDuration > 0 else { return 1.0 }
        let elapsed = Date().timeIntervalSince(start)
        return Float(max(0.0, min(1.0, elapsed / activeFadeDuration)))
    }

    private func applyCurrentVolume() {
        player?.volume = effectiveVolume * currentFadeInFactor()
        if isMuted {
            fadingPlayer?.volume = 0
        }
    }

    private func setupAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default)
        try? session.setActive(true)
    }

    private func setupRemoteCommands() {
        let cc = MPRemoteCommandCenter.shared()
        cc.playCommand.isEnabled = true
        cc.playCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.resume() }
            return .success
        }

        cc.pauseCommand.isEnabled = true
        cc.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.pause() }
            return .success
        }

        cc.togglePlayPauseCommand.isEnabled = true
        cc.togglePlayPauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.togglePlayPause() }
            return .success
        }

        cc.nextTrackCommand.isEnabled = true
        cc.nextTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.nextTrack(manual: true) }
            return .success
        }

        cc.previousTrackCommand.isEnabled = true
        cc.previousTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.previousTrack() }
            return .success
        }

        cc.changePlaybackPositionCommand.isEnabled = true
        cc.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let posEvent = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            Task { @MainActor in self?.seek(to: posEvent.positionTime) }
            return .success
        }
    }

    func playFromList(_ list: [VKTrack], index: Int) {
        guard index >= 0 && index < list.count else { return }
        if let current = currentTrack, current.fullId == list[index].fullId {
            togglePlayPause()
            return
        }
        self.queue = list
        self.history.removeAll()
        self.plannedNextIndex = nil
        self.prefetchedNext = nil
        playQueueIndex(index, pushHistory: false)
    }

    func toggleShuffle() {
        shuffle.toggle()
        UserDefaults.standard.set(shuffle, forKey: Keys.shuffle)
        plannedNextIndex = nil
        prefetchedNext = nil
        prepareNextTrack()
    }

    func cycleRepeatMode() {
        switch repeatMode {
        case .none: repeatMode = .all
        case .all: repeatMode = .one
        case .one: repeatMode = .none
        }
        UserDefaults.standard.set(repeatMode.rawValue, forKey: Keys.repeatMode)
        plannedNextIndex = nil
        prefetchedNext = nil
        prepareNextTrack()
    }

    func togglePlayPause() {
        guard let player else {
            if !queue.isEmpty {
                playQueueIndex(0, pushHistory: false)
            }
            return
        }
        if isPlaying {
            pause()
        } else {
            if duration > 0 && currentTime >= max(0, duration - 0.35) {
                seek(to: 0)
            }
            resume()
        }
    }

    func pause() {
        player?.pause()
        fadingPlayer?.pause()
        isPlaying = false
        updateNowPlayingInfo()
    }

    func resume() {
        try? AVAudioSession.sharedInstance().setActive(true)
        player?.play()
        fadingPlayer?.play()
        isPlaying = true
        updateNowPlayingInfo()
    }

    func seek(to seconds: Double) {
        let clamped = max(0, min(duration > 0 ? duration : seconds, seconds))
        let cmTime = CMTime(seconds: clamped, preferredTimescale: 600)
        player?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
            Task { @MainActor in
                self?.currentTime = clamped
                self?.updateNowPlayingInfo()
            }
        }
    }

    private func computeNextIndex() -> Int? {
        guard !queue.isEmpty else { return nil }
        if repeatMode == .one {
            return currentIndex
        }
        if shuffle {
            if let planned = plannedNextIndex,
               planned >= 0,
               planned < queue.count,
               (queue.count == 1 || planned != currentIndex) {
                return planned
            }
            let nextIdx: Int
            if queue.count == 1 {
                nextIdx = 0
            } else {
                var candidate = Int.random(in: 0..<queue.count)
                while candidate == currentIndex {
                    candidate = Int.random(in: 0..<queue.count)
                }
                nextIdx = candidate
            }
            plannedNextIndex = nextIdx
            return nextIdx
        }
        let cur = currentIndex ?? 0
        let nxt = cur + 1
        if nxt < queue.count {
            return nxt
        } else if repeatMode == .all {
            return 0
        } else {
            return nil
        }
    }

    func nextTrack(manual: Bool = true) {
        guard !queue.isEmpty else { return }
        if repeatMode == .one && !manual, let idx = currentIndex {
            playQueueIndex(idx, pushHistory: false)
            return
        }
        if shuffle {
            let nextIdx = computeNextIndex() ?? 0
            playQueueIndex(nextIdx, pushHistory: true)
            return
        }

        let cur = currentIndex ?? 0
        let nxt = cur + 1
        if nxt >= queue.count {
            if repeatMode == .all || manual {
                playQueueIndex(0, pushHistory: true)
            } else {
                pause()
                seek(to: 0)
            }
        } else {
            playQueueIndex(nxt, pushHistory: true)
        }
    }

    func previousTrack() {
        guard !queue.isEmpty else { return }
        if currentTime > 3.0 {
            seek(to: 0)
            return
        }
        if let prevIdx = history.popLast(), prevIdx >= 0 && prevIdx < queue.count {
            playQueueIndex(prevIdx, pushHistory: false)
            return
        }
        let cur = currentIndex ?? 0
        let prev = cur == 0 ? queue.count - 1 : cur - 1
        playQueueIndex(prev, pushHistory: false)
    }

    private func playQueueIndex(_ index: Int, pushHistory: Bool) {
        guard index >= 0 && index < queue.count else { return }
        if pushHistory, let prev = currentIndex, prev != index {
            history.append(prev)
            if history.count > 200 {
                history.removeFirst()
            }
        }

        loadTask?.cancel()
        prefetchTask?.cancel()
        stopCrossfadeImmediate()
        cleanupObservers()
        player?.pause()
        player = nil

        let track = queue[index]
        self.currentIndex = index
        self.currentTrack = track
        self.plannedNextIndex = nil
        self.didTriggerTransitionForCurrent = false
        self.currentTime = 0
        self.duration = Double(max(0, track.duration))
        self.loadGeneration &+= 1
        let gen = self.loadGeneration

        vkClient?.recordPlayedTrack(track)
        fetchArtworkIfNeeded(for: track)

        if let pref = prefetchedNext,
           pref.trackId == track.fullId,
           FileManager.default.fileExists(atPath: pref.fileURL.path) {
            self.prefetchedNext = nil
            self.isBuffering = false
            startPlayback(fileOrStreamURL: pref.fileURL, track: pref.track, crossfadeInDuration: 0)
            prepareNextTrack()
            return
        }

        if let localURL = LocalStorage.findDownloadedFile(for: track)
            ?? LocalStorage.findCachedAudioFile(for: track) {
            self.isBuffering = false
            startPlayback(fileOrStreamURL: localURL, track: track, crossfadeInDuration: 0)
            prepareNextTrack()
            return
        }

        if track.url.hasPrefix("file://"), let fileURL = URL(string: track.url) {
            self.isBuffering = false
            startPlayback(fileOrStreamURL: fileURL, track: track, crossfadeInDuration: 0)
            prepareNextTrack()
            return
        }

        self.isBuffering = true
        self.isPlaying = false
        vkClient?.statusText = "Буферизация: \(track.artist) — \(track.title)"

        loadTask = Task { [weak self] in
            guard let self else { return }
            do {
                guard let vk = self.vkClient else { return }
                let (resolvedURL, freshTrack) = try await vk.resolvePlayableFileURL(for: track)
                guard !Task.isCancelled, self.loadGeneration == gen else { return }
                let activeTrack = freshTrack ?? track
                if let freshTrack {
                    self.updateTrackMetadata(freshTrack)
                }
                self.isBuffering = false
                self.startPlayback(fileOrStreamURL: resolvedURL, track: activeTrack, crossfadeInDuration: 0)
                self.prepareNextTrack()
            } catch {
                guard !Task.isCancelled, self.loadGeneration == gen else { return }
                self.isBuffering = false
                if let fallbackURL = URL(string: track.url), !track.url.isEmpty {
                    self.startPlayback(fileOrStreamURL: fallbackURL, track: track, crossfadeInDuration: 0)
                    self.prepareNextTrack()
                } else {
                    self.vkClient?.statusText = "Ошибка: \(error.localizedDescription)"
                }
            }
        }
    }

    private func updateTrackMetadata(_ fresh: VKTrack) {
        if currentTrack?.fullId == fresh.fullId {
            currentTrack = fresh
        }
        if let idx = queue.firstIndex(where: { $0.fullId == fresh.fullId }) {
            queue[idx] = fresh
        }
    }

    private func startPlayback(fileOrStreamURL: URL, track: VKTrack, crossfadeInDuration: Double) {
        cleanupObservers()
        if crossfadeInDuration <= 0 {
            stopCrossfadeImmediate()
            player?.pause()
            player = nil
        }

        try? AVAudioSession.sharedInstance().setActive(true)
        let asset: AVURLAsset
        if fileOrStreamURL.isFileURL {
            asset = AVURLAsset(url: fileOrStreamURL)
        } else {
            asset = AVURLAsset(url: fileOrStreamURL, options: [
                "AVURLAssetHTTPHeaderFieldsKey": [
                    "User-Agent": VKAPIClient.desktopUserAgent
                ]
            ])
        }

        let item = AVPlayerItem(asset: asset)
        let newPlayer = AVPlayer(playerItem: item)
        self.player = newPlayer
        self.currentTime = 0
        self.duration = Double(max(0, track.duration))
        self.didTriggerTransitionForCurrent = false

        if crossfadeInDuration > 0 {
            newPlayer.volume = 0
            fadeInStartDate = Date()
            activeFadeDuration = crossfadeInDuration
            startCrossfadeTimerIfNeeded()
        } else {
            newPlayer.volume = effectiveVolume
        }

        timeObserver = newPlayer.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.1, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            Task { @MainActor in
                guard let self else { return }
                let secs = time.seconds
                if secs.isFinite {
                    self.currentTime = max(0, secs)
                }
                if self.duration <= 0,
                   let itemDur = self.player?.currentItem?.duration.seconds,
                   itemDur.isFinite,
                   itemDur > 0 {
                    self.duration = itemDur
                }
                self.checkCrossfadeTrigger()
            }
        }

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.nextTrack(manual: false)
            }
        }

        newPlayer.play()
        self.isPlaying = true
        let offlinePrefix = LocalStorage.findDownloadedFile(for: track) != nil ? "Оффлайн: " : ""
        vkClient?.statusText = "\(offlinePrefix)\(track.artist) — \(track.title)"
        updateNowPlayingInfo()
    }

    private func prepareNextTrack() {
        prefetchTask?.cancel()
        guard let nextIdx = computeNextIndex(), nextIdx < queue.count else {
            prefetchedNext = nil
            return
        }
        let nextTrack = queue[nextIdx]
        let afterIdx: Int? = (!shuffle && repeatMode != .one && queue.count > 2)
            ? (nextIdx + 1 < queue.count ? nextIdx + 1 : (repeatMode == .all ? 0 : nil))
            : nil
        let afterTrack = afterIdx.map { queue[$0] }

        if let pref = prefetchedNext,
           pref.trackId == nextTrack.fullId,
           FileManager.default.fileExists(atPath: pref.fileURL.path) {
            if let afterTrack {
                prefetchTask = Task { [weak self] in
                    _ = try? await self?.vkClient?.resolvePlayableFileURL(for: afterTrack)
                }
            }
            return
        }

        prefetchTask = Task { [weak self] in
            guard let self, let vk = self.vkClient else { return }
            if let (url, fresh) = try? await vk.resolvePlayableFileURL(for: nextTrack) {
                guard !Task.isCancelled else { return }
                let resolvedTrack = fresh ?? nextTrack
                if let fresh {
                    self.updateTrackMetadata(fresh)
                }
                self.prefetchedNext = (nextTrack.fullId, url, resolvedTrack)
            }
            if !Task.isCancelled, let afterTrack {
                _ = try? await vk.resolvePlayableFileURL(for: afterTrack)
            }
        }
    }

    private func checkCrossfadeTrigger() {
        guard crossfadeSecs > 0,
              isPlaying,
              !didTriggerTransitionForCurrent,
              duration > Double(crossfadeSecs) + 2.0 else {
            return
        }
        let remaining = duration - currentTime
        guard remaining <= Double(crossfadeSecs) else { return }
        guard let nextIdx = computeNextIndex(), nextIdx < queue.count else { return }
        let expectedId = queue[nextIdx].fullId
        guard let pref = prefetchedNext,
              pref.trackId == expectedId,
              FileManager.default.fileExists(atPath: pref.fileURL.path) else {
            return
        }
        startCrossfadeTransition(to: nextIdx, prefetched: pref)
    }

    private func startCrossfadeTransition(
        to nextIdx: Int,
        prefetched: (trackId: String, fileURL: URL, track: VKTrack)
    ) {
        didTriggerTransitionForCurrent = true
        cleanupObservers()
        fadingPlayer?.pause()
        fadingPlayer = player
        fadingStartDate = Date()
        player = nil

        if let prev = currentIndex, prev != nextIdx {
            history.append(prev)
            if history.count > 200 {
                history.removeFirst()
            }
        }

        self.currentIndex = nextIdx
        self.currentTrack = prefetched.track
        self.plannedNextIndex = nil
        self.prefetchedNext = nil
        self.loadGeneration &+= 1

        vkClient?.recordPlayedTrack(prefetched.track)
        fetchArtworkIfNeeded(for: prefetched.track)

        let cfDur = Double(crossfadeSecs)
        startPlayback(fileOrStreamURL: prefetched.fileURL, track: prefetched.track, crossfadeInDuration: cfDur)
        prepareNextTrack()
    }

    private func startCrossfadeTimerIfNeeded() {
        crossfadeTimer?.invalidate()
        crossfadeTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateCrossfadeEnvelopes()
            }
        }
    }

    private func updateCrossfadeEnvelopes() {
        let baseGain = effectiveVolume
        let dur = max(0.1, activeFadeDuration)

        if let fading = fadingPlayer, let fStart = fadingStartDate {
            let t = min(1.0, max(0.0, Date().timeIntervalSince(fStart) / dur))
            if t >= 1.0 {
                fading.pause()
                fadingPlayer = nil
                fadingStartDate = nil
            } else {
                fading.volume = isMuted ? 0 : Float(1.0 - t) * baseGain
            }
        }

        if let inStart = fadeInStartDate {
            let t = min(1.0, max(0.0, Date().timeIntervalSince(inStart) / dur))
            player?.volume = Float(t) * baseGain
            if t >= 1.0 {
                fadeInStartDate = nil
                player?.volume = baseGain
            }
        }

        if fadingPlayer == nil && fadeInStartDate == nil {
            crossfadeTimer?.invalidate()
            crossfadeTimer = nil
        }
    }

    private func stopCrossfadeImmediate() {
        crossfadeTimer?.invalidate()
        crossfadeTimer = nil
        fadingPlayer?.pause()
        fadingPlayer = nil
        fadingStartDate = nil
        fadeInStartDate = nil
        activeFadeDuration = 0
    }

    private func cleanupObservers() {
        if let obs = timeObserver, let player {
            player.removeTimeObserver(obs)
        }
        timeObserver = nil
        if let endObs = endObserver {
            NotificationCenter.default.removeObserver(endObs)
        }
        endObserver = nil
    }

    private func fetchArtworkIfNeeded(for track: VKTrack) {
        guard !track.coverUrl.isEmpty, let url = URL(string: track.coverUrl) else { return }
        if cachedArtwork?.0 == track.coverUrl {
            updateNowPlayingInfo()
            return
        }
        let coverStr = track.coverUrl
        Task.detached(priority: .utility) { [weak self] in
            guard let (data, _) = try? await URLSession.shared.data(from: url),
                  let image = UIImage(data: data) else { return }
            await MainActor.run {
                guard let self else { return }
                self.cachedArtwork = (coverStr, image)
                if self.currentTrack?.coverUrl == coverStr {
                    self.updateNowPlayingInfo()
                }
            }
        }
    }

    private func updateNowPlayingInfo() {
        guard let track = currentTrack else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: track.title,
            MPMediaItemPropertyArtist: track.artist,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]
        if !track.albumTitle.isEmpty {
            info[MPMediaItemPropertyAlbumTitle] = track.albumTitle
        }
        if let (url, img) = cachedArtwork, url == track.coverUrl {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: img.size) { _ in img }
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}
