import AVFoundation
import Foundation
import MediaPlayer
import UIKit

@MainActor
final class AudioPlayerManager: ObservableObject {
    @Published var currentTrack: VKTrack?
    @Published var isPlaying: Bool = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var shuffle: Bool = false
    @Published var repeatMode: RepeatMode = .none

    private var player: AVPlayer?
    private var timeObserver: Any?
    private var endObserver: NSObjectProtocol?
    private weak var vkClient: VKAPIClient?

    private var queue: [VKTrack] = []
    private var currentIndex: Int?
    private var history: [Int] = []
    private var cachedArtwork: (String, UIImage)?

    init() {
        let defaults = UserDefaults.standard
        self.shuffle = defaults.bool(forKey: "player_shuffle")
        if let rawRep = defaults.string(forKey: "player_repeat"),
           let mode = RepeatMode(rawValue: rawRep) {
            self.repeatMode = mode
        }
        setupAudioSession()
        setupRemoteCommands()
    }

    func configure(vkClient: VKAPIClient) {
        self.vkClient = vkClient
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
        playQueueIndex(index, pushHistory: false)
    }

    func toggleShuffle() {
        shuffle.toggle()
        UserDefaults.standard.set(shuffle, forKey: "player_shuffle")
    }

    func cycleRepeatMode() {
        switch repeatMode {
        case .none: repeatMode = .all
        case .all: repeatMode = .one
        case .one: repeatMode = .none
        }
        UserDefaults.standard.set(repeatMode.rawValue, forKey: "player_repeat")
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
            resume()
        }
    }

    func pause() {
        player?.pause()
        isPlaying = false
        updateNowPlayingInfo()
    }

    func resume() {
        try? AVAudioSession.sharedInstance().setActive(true)
        player?.play()
        isPlaying = true
        updateNowPlayingInfo()
    }

    func seek(to seconds: Double) {
        let clamped = max(0, min(duration > 0 ? duration : seconds, seconds))
        let cmTime = CMTime(seconds: clamped, preferredTimescale: 600)
        player?.seek(to: cmTime) { [weak self] _ in
            Task { @MainActor in
                self?.currentTime = clamped
                self?.updateNowPlayingInfo()
            }
        }
    }

    func nextTrack(manual: Bool = true) {
        guard !queue.isEmpty else { return }
        if repeatMode == .one && !manual, let idx = currentIndex {
            playQueueIndex(idx, pushHistory: false)
            return
        }
        if shuffle {
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

        cleanupObservers()

        let track = queue[index]
        self.currentIndex = index
        self.currentTrack = track
        self.currentTime = 0
        self.duration = Double(max(0, track.duration))

        let playbackURL: URL?
        if let localURL = LocalStorage.findDownloadedFile(for: track) {
            playbackURL = localURL
        } else if track.url.hasPrefix("file://") {
            playbackURL = URL(string: track.url)
        } else {
            playbackURL = URL(string: track.url)
        }

        guard let url = playbackURL else {
            vkClient?.statusText = "Нет ссылки для трека: \(track.title)"
            return
        }

        try? AVAudioSession.sharedInstance().setActive(true)
        let asset = AVURLAsset(url: url, options: [
            "AVURLAssetHTTPHeaderFieldsKey": [
                "User-Agent": VKAPIClient.desktopUserAgent
            ]
        ])
        let item = AVPlayerItem(asset: asset)
        let newPlayer = AVPlayer(playerItem: item)
        self.player = newPlayer

        timeObserver = newPlayer.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.25, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            Task { @MainActor in
                guard let self else { return }
                let secs = time.seconds
                if secs.isFinite {
                    self.currentTime = max(0, secs)
                }
                if let itemDur = self.player?.currentItem?.duration.seconds,
                   itemDur.isFinite,
                   itemDur > 0 {
                    self.duration = itemDur
                }
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
        vkClient?.statusText = "\(track.artist) — \(track.title)"
        updateNowPlayingInfo()
        fetchArtworkIfNeeded(for: track)
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
