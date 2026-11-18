@preconcurrency import AVFoundation
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

    // Equalizer & AirPods 3 Audio Engine
    @Published var eqEnabled: Bool = true
    @Published var eqPreset: EQPreset = .airpodsHyperpop
    @Published var eqBands: [Float] = EQPreset.airpodsHyperpop.defaultGains
    @Published var preampDB: Float = 0.0
    @Published var airpods3Mode: Bool = true
    @Published var spatialStage: Float = 0.25
    @Published var audioRouteName: String = "Динамик"
    @Published var isAirPodsConnected: Bool = false

    // MARK: - AVAudioEngine Graph (Primary Playback + Real-Time DSP)
    private let engine = AVAudioEngine()
    private let playerNodeA = AVAudioPlayerNode()
    private let playerNodeB = AVAudioPlayerNode()
    private let trackMixerNode = AVAudioMixerNode()
    private let eqNode = AVAudioUnitEQ(numberOfBands: 8)
    private let spatialNode = AVAudioUnitReverb()
    private let graphFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!

    private var activeIsA: Bool = true
    private var activeFile: AVAudioFile?
    private var fadingFile: AVAudioFile?
    private var engineBaseSeconds: Double = 0
    private var mainEngineToken: UInt64 = 0
    private var engineTimer: Timer?
    private var usingEngine: Bool = false
    private var isEngineGraphConfigured: Bool = false

    // MARK: - AVPlayer Fallback (Remote Streams)
    private var player: AVPlayer?
    private var fadingPlayer: AVPlayer?
    private var timeObserver: Any?
    private var endObserver: NSObjectProtocol?

    // Crossfade Envelope State
    private var fadingStartDate: Date?
    private var fadeInStartDate: Date?
    private var activeFadeDuration: Double = 0
    private var crossfadeTimer: Timer?

    @Published private(set) var queue: [VKTrack] = []
    @Published private(set) var currentIndex: Int?

    private weak var vkClient: VKAPIClient?
    private var liveElapsedSeconds: Double = 0
    private var history: [Int] = []
    private var cachedArtwork: (String, UIImage)?

    private var loadTask: Task<Void, Never>?
    private var prefetchTask: Task<Void, Never>?
    private var loadGeneration: UInt64 = 0
    private var plannedNextIndex: Int?
    private var prefetchedNext: (trackId: String, fileURL: URL, track: VKTrack)?
    private var didTriggerTransitionForCurrent: Bool = false

    private var routeObserver: NSObjectProtocol?
    private var interruptionObserver: NSObjectProtocol?
    private var engineConfigObserver: NSObjectProtocol?

    private enum Keys {
        static let shuffle = "player_shuffle"
        static let repeatMode = "player_repeat"
        static let volume = "player_volume"
        static let crossfade = "player_crossfade_secs"
        static let eqEnabled = "eq_enabled"
        static let eqPreset = "eq_preset"
        static let eqBands = "eq_bands"
        static let preampDB = "eq_preamp_db"
        static let airpods3Mode = "eq_airpods3_mode"
        static let spatialStage = "eq_spatial_stage"
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

        if defaults.object(forKey: Keys.eqEnabled) != nil {
            self.eqEnabled = defaults.bool(forKey: Keys.eqEnabled)
        }
        if let rawPreset = defaults.string(forKey: Keys.eqPreset),
           let preset = EQPreset(rawValue: rawPreset) {
            self.eqPreset = preset
        }
        if let savedBands = defaults.array(forKey: Keys.eqBands) as? [Double],
           savedBands.count == 6 {
            self.eqBands = savedBands.map { Float(max(-12, min(12, $0))) }
        } else {
            self.eqBands = self.eqPreset.defaultGains
        }
        if defaults.object(forKey: Keys.preampDB) != nil {
            self.preampDB = max(-12, min(6, defaults.float(forKey: Keys.preampDB)))
        }
        if defaults.object(forKey: Keys.airpods3Mode) != nil {
            self.airpods3Mode = defaults.bool(forKey: Keys.airpods3Mode)
        }
        if defaults.object(forKey: Keys.spatialStage) != nil {
            self.spatialStage = max(0, min(1, defaults.float(forKey: Keys.spatialStage)))
        }

        setupAudioSession()
        configureEngineGraph()
        applyEQSettings()
        refreshAudioRoute()
        setupObservers()
        setupRemoteCommands()
    }

    func configure(vkClient: VKAPIClient) {
        self.vkClient = vkClient
    }

    private var activePlayerNode: AVAudioPlayerNode {
        activeIsA ? playerNodeA : playerNodeB
    }

    private var retiringPlayerNode: AVAudioPlayerNode {
        activeIsA ? playerNodeB : playerNodeA
    }

    // MARK: - Equalizer & AirPods 3 Controls

    func setEQEnabled(_ enabled: Bool) {
        eqEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: Keys.eqEnabled)
        applyEQSettings()
    }

    func applyEQPreset(_ preset: EQPreset) {
        eqPreset = preset
        if preset != .custom {
            eqBands = preset.defaultGains
        }
        eqEnabled = true
        if preset == .airpodsHyperpop || preset == .airpodsIdeal {
            airpods3Mode = true
            UserDefaults.standard.set(true, forKey: Keys.airpods3Mode)
        }
        UserDefaults.standard.set(true, forKey: Keys.eqEnabled)
        UserDefaults.standard.set(preset.rawValue, forKey: Keys.eqPreset)
        UserDefaults.standard.set(eqBands.map { Double($0) }, forKey: Keys.eqBands)
        applyEQSettings()
    }

    func setEQBandGain(index: Int, gain: Float) {
        guard index >= 0 && index < 6 else { return }
        let clamped = (max(-12.0, min(12.0, gain)) * 2.0).rounded() / 2.0
        eqBands[index] = clamped
        eqPreset = .custom
        if !eqEnabled {
            eqEnabled = true
            UserDefaults.standard.set(true, forKey: Keys.eqEnabled)
        }
        UserDefaults.standard.set(eqPreset.rawValue, forKey: Keys.eqPreset)
        UserDefaults.standard.set(eqBands.map { Double($0) }, forKey: Keys.eqBands)
        applyEQSettings()
    }

    func setPreamp(_ db: Float) {
        let clamped = (max(-12.0, min(6.0, db)) * 2.0).rounded() / 2.0
        preampDB = clamped
        UserDefaults.standard.set(clamped, forKey: Keys.preampDB)
        applyEQSettings()
    }

    func setAirPods3Mode(_ enabled: Bool) {
        airpods3Mode = enabled
        UserDefaults.standard.set(enabled, forKey: Keys.airpods3Mode)
        applyEQSettings()
    }

    func setSpatialStage(_ stage: Float) {
        let clamped = max(0.0, min(1.0, stage))
        spatialStage = clamped
        UserDefaults.standard.set(clamped, forKey: Keys.spatialStage)
        applyEQSettings()
    }

    func resetEQ() {
        preampDB = 0.0
        spatialStage = 0.25
        UserDefaults.standard.set(0.0, forKey: Keys.preampDB)
        UserDefaults.standard.set(0.25, forKey: Keys.spatialStage)
        applyEQPreset(.flat)
    }

    private func configureEngineGraph() {
        guard !isEngineGraphConfigured else { return }
        engine.attach(playerNodeA)
        engine.attach(playerNodeB)
        engine.attach(trackMixerNode)
        engine.attach(eqNode)
        engine.attach(spatialNode)

        spatialNode.loadFactoryPreset(.smallRoom)
        spatialNode.wetDryMix = 0

        engine.connect(playerNodeA, to: trackMixerNode, format: graphFormat)
        engine.connect(playerNodeB, to: trackMixerNode, format: graphFormat)
        engine.connect(trackMixerNode, to: eqNode, format: graphFormat)
        engine.connect(eqNode, to: spatialNode, format: graphFormat)
        engine.connect(spatialNode, to: engine.mainMixerNode, format: nil)

        for info in EQBandInfo.sixBands {
            let band = eqNode.bands[info.index]
            band.frequency = info.frequencyHz
            if info.index == 0 {
                band.filterType = .lowShelf
            } else if info.index == 5 {
                band.filterType = .highShelf
            } else {
                band.filterType = .parametric
                band.bandwidth = 1.0
            }
            band.bypass = false
        }

        // Band 6: AirPods 3 Open-Fit Sub-Bass Restore (55 Hz Low Shelf)
        let subAirPodsBand = eqNode.bands[6]
        subAirPodsBand.filterType = .lowShelf
        subAirPodsBand.frequency = 55
        subAirPodsBand.bypass = false

        // Band 7: AirPods 3 Upper-Bass Boxiness Tame (230 Hz Parametric)
        let mudAirPodsBand = eqNode.bands[7]
        mudAirPodsBand.filterType = .parametric
        mudAirPodsBand.frequency = 230
        mudAirPodsBand.bandwidth = 1.1
        mudAirPodsBand.bypass = false

        isEngineGraphConfigured = true
    }

    private func applyEQSettings() {
        for idx in 0..<6 {
            let band = eqNode.bands[idx]
            let g = eqEnabled ? eqBands[idx] : 0.0
            band.gain = max(-12.0, min(12.0, g))
            band.bypass = !eqEnabled
        }

        let applyAirPods = eqEnabled && airpods3Mode
        eqNode.bands[6].gain = applyAirPods ? 3.2 : 0.0
        eqNode.bands[6].bypass = !applyAirPods

        eqNode.bands[7].gain = applyAirPods ? -1.5 : 0.0
        eqNode.bands[7].bypass = !applyAirPods

        // Anti-clipping headroom protection so bass boosts stay clean on AirPods 3
        let maxUserBoost = eqBands.max() ?? 0.0
        let airpodsBoost: Float = applyAirPods ? 2.0 : 0.0
        let peakBoost = max(0.0, maxUserBoost + airpodsBoost * 0.5)
        let headroom = max(0.0, peakBoost * 0.32)
        eqNode.globalGain = eqEnabled ? max(-12.0, min(6.0, preampDB - headroom)) : 0.0

        spatialNode.wetDryMix = (eqEnabled || airpods3Mode)
            ? min(18.0, max(0.0, spatialStage) * 18.0)
            : 0.0
    }

    // MARK: - Volume & Crossfade

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

    func setCrossfadeSecs(_ secs: Int) {
        let valid = [0, 1, 2, 3, 5].contains(secs) ? secs : 1
        crossfadeSecs = valid
        UserDefaults.standard.set(valid, forKey: Keys.crossfade)
        prepareNextTrack()
    }

    func cycleCrossfade() {
        let next: Int
        switch crossfadeSecs {
        case 0: next = 1
        case 1: next = 2
        case 2: next = 3
        case 3: next = 5
        default: next = 0
        }
        setCrossfadeSecs(next)
    }

    private func currentFadeInFactor() -> Float {
        guard let start = fadeInStartDate, activeFadeDuration > 0 else { return 1.0 }
        let elapsed = Date().timeIntervalSince(start)
        return Float(max(0.0, min(1.0, elapsed / activeFadeDuration)))
    }

    private func applyCurrentVolume() {
        let target = effectiveVolume * currentFadeInFactor()
        if usingEngine {
            activePlayerNode.volume = target
            if isMuted {
                retiringPlayerNode.volume = 0
            }
        } else {
            player?.volume = target
            if isMuted {
                fadingPlayer?.volume = 0
            }
        }
    }

    // MARK: - Session, Routes & Remote Commands

    private func setupAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default)
        try? session.setActive(true)
    }

    private func refreshAudioRoute() {
        let outputs = AVAudioSession.sharedInstance().currentRoute.outputs
        if let first = outputs.first {
            let name = first.portName.trimmingCharacters(in: .whitespacesAndNewlines)
            audioRouteName = name.isEmpty ? "Динамик" : name
            let low = name.lowercased()
            isAirPodsConnected = low.contains("airpods")
                || first.portType == .bluetoothA2DP
                || first.portType == .bluetoothLE
                || first.portType == .bluetoothHFP
        } else {
            audioRouteName = "Динамик"
            isAirPodsConnected = false
        }
    }

    private func setupObservers() {
        routeObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refreshAudioRoute()
            }
        }

        engineConfigObserver = NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange,
            object: engine,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.refreshAudioRoute()
                if self.usingEngine && self.isPlaying {
                    try? self.ensureEngineStarted()
                    self.activePlayerNode.play()
                }
            }
        }

        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let info = note.userInfo,
                  let typeRaw = info[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeRaw) else { return }
            let optRaw = info[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            let options = AVAudioSession.InterruptionOptions(rawValue: optRaw)

            Task { @MainActor in
                guard let self else { return }
                switch type {
                case .began:
                    if self.isPlaying {
                        self.pause()
                    }
                case .ended:
                    if options.contains(.shouldResume) {
                        self.resume()
                    }
                @unknown default:
                    break
                }
            }
        }
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

    // MARK: - Queue & Playback Control

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
        if isBuffering {
            loadTask?.cancel()
            isBuffering = false
            vkClient?.statusText = "Загрузка отменена"
            return
        }
        if !usingEngine && player == nil {
            if !queue.isEmpty {
                playQueueIndex(0, pushHistory: false)
            }
            return
        }
        if usingEngine && activeFile == nil {
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
        if usingEngine {
            activePlayerNode.pause()
            retiringPlayerNode.pause()
        } else {
            player?.pause()
            fadingPlayer?.pause()
        }
        isPlaying = false
        updateNowPlayingInfo()
    }

    func resume() {
        try? AVAudioSession.sharedInstance().setActive(true)
        if usingEngine {
            try? ensureEngineStarted()
            activePlayerNode.play()
            if fadingStartDate != nil {
                retiringPlayerNode.play()
            }
        } else {
            player?.play()
            fadingPlayer?.play()
        }
        isPlaying = true
        updateNowPlayingInfo()
    }

    func seek(to seconds: Double) {
        let maxDur = duration > 0 ? duration : seconds
        let clamped = max(0, min(maxDur, seconds))

        if usingEngine, let file = activeFile {
            let sr = file.processingFormat.sampleRate
            guard sr > 0 && file.length > 0 else { return }

            mainEngineToken &+= 1
            let node = activePlayerNode
            node.stop()

            let targetFrame = min(file.length - 1, max(0, AVAudioFramePosition(clamped * sr)))
            let remaining = AVAudioFrameCount(max(1, file.length - targetFrame))
            engineBaseSeconds = Double(targetFrame) / sr
            liveElapsedSeconds = engineBaseSeconds
            currentTime = engineBaseSeconds
            didTriggerTransitionForCurrent = false

            scheduleSegment(node: node, file: file, startFrame: targetFrame, frameCount: remaining, token: mainEngineToken)
            if isPlaying {
                try? ensureEngineStarted()
                node.play()
            }
            updateNowPlayingInfo()
        } else {
            let cmTime = CMTime(seconds: clamped, preferredTimescale: 600)
            player?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
                Task { @MainActor in
                    self?.liveElapsedSeconds = clamped
                    self?.currentTime = clamped
                    self?.updateNowPlayingInfo()
                }
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

    func jumpToQueueIndex(_ index: Int) {
        guard queue.indices.contains(index) else { return }
        if index == currentIndex {
            togglePlayPause()
            return
        }
        plannedNextIndex = nil
        prefetchedNext = nil
        playQueueIndex(index, pushHistory: true)
    }

    func playNext(_ track: VKTrack) {
        if queue.isEmpty || currentTrack == nil {
            playFromList([track], index: 0)
            return
        }
        let insertIdx = min(queue.count, (currentIndex ?? 0) + 1)
        if queue.indices.contains(insertIdx) && queue[insertIdx].fullId == track.fullId {
            return
        }
        queue.insert(track, at: insertIdx)
        plannedNextIndex = nil
        prefetchedNext = nil
        prepareNextTrack()
        vkClient?.statusText = "Далее: \(track.artist) — \(track.title)"
    }

    func addToQueue(_ track: VKTrack) {
        if queue.isEmpty || currentTrack == nil {
            playFromList([track], index: 0)
            return
        }
        queue.append(track)
        plannedNextIndex = nil
        prepareNextTrack()
        vkClient?.statusText = "В очередь: \(track.artist) — \(track.title)"
    }

    func removeFromQueue(at index: Int) {
        guard queue.indices.contains(index), index != currentIndex else { return }
        queue.remove(at: index)
        if let cur = currentIndex, index < cur {
            currentIndex = cur - 1
        }
        history = history.compactMap { oldIdx in
            if oldIdx == index { return nil }
            return oldIdx > index ? oldIdx - 1 : oldIdx
        }
        plannedNextIndex = nil
        prefetchedNext = nil
        prepareNextTrack()
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
        stopAllPlaybackNodes()

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

    // MARK: - Unified Engine / AVPlayer Playback Startup

    private func ensureEngineStarted() throws {
        configureEngineGraph()
        if !engine.isRunning {
            engine.prepare()
            try engine.start()
        }
    }

    private func stopAllPlaybackNodes() {
        mainEngineToken &+= 1
        engineTimer?.invalidate()
        engineTimer = nil
        playerNodeA.stop()
        playerNodeB.stop()
        activeFile = nil
        fadingFile = nil

        cleanupAVPlayerObservers()
        player?.pause()
        player = nil
        fadingPlayer?.pause()
        fadingPlayer = nil
    }

    private func startPlayback(fileOrStreamURL: URL, track: VKTrack, crossfadeInDuration: Double) {
        if fileOrStreamURL.isFileURL,
           let audioFile = try? AVAudioFile(forReading: fileOrStreamURL),
           audioFile.length > 0,
           audioFile.processingFormat.sampleRate > 0 {
            do {
                try startEnginePlayback(file: audioFile, track: track, crossfadeInDuration: crossfadeInDuration)
                return
            } catch {
                // Fall through to AVPlayer fallback if AVAudioEngine setup fails on device
            }
        }
        startAVPlayerFallback(url: fileOrStreamURL, track: track, crossfadeInDuration: crossfadeInDuration)
    }

    private func startEnginePlayback(file: AVAudioFile, track: VKTrack, crossfadeInDuration: Double) throws {
        cleanupAVPlayerObservers()
        player?.pause()
        player = nil
        fadingPlayer?.pause()
        fadingPlayer = nil

        if crossfadeInDuration <= 0 {
            stopCrossfadeImmediate()
            playerNodeA.stop()
            playerNodeB.stop()
            fadingFile = nil
        }

        usingEngine = true
        configureEngineGraph()

        let node = activePlayerNode
        mainEngineToken &+= 1
        let token = mainEngineToken
        node.stop()

        let currentOutFmt = node.outputFormat(forBus: 0)
        let targetFmt = file.processingFormat
        if currentOutFmt.sampleRate != targetFmt.sampleRate || currentOutFmt.channelCount != targetFmt.channelCount {
            let resumeRetiring = (crossfadeInDuration > 0 && fadingFile != nil && retiringPlayerNode.isPlaying)
            if resumeRetiring {
                retiringPlayerNode.pause()
            }
            if engine.isRunning {
                engine.stop()
            }
            engine.disconnectNodeOutput(node)
            engine.connect(node, to: trackMixerNode, format: targetFmt)
            try ensureEngineStarted()
            if resumeRetiring {
                retiringPlayerNode.play()
            }
        } else {
            try ensureEngineStarted()
        }

        activeFile = file
        engineBaseSeconds = 0
        liveElapsedSeconds = 0
        currentTime = 0
        didTriggerTransitionForCurrent = false

        let fileDuration = Double(file.length) / file.processingFormat.sampleRate
        duration = fileDuration > 0 ? fileDuration : Double(max(0, track.duration))

        if crossfadeInDuration > 0 {
            node.volume = 0
            fadeInStartDate = Date()
            activeFadeDuration = crossfadeInDuration
            startCrossfadeTimerIfNeeded()
        } else {
            node.volume = effectiveVolume
        }

        let totalFrames = AVAudioFrameCount(file.length)
        scheduleSegment(node: node, file: file, startFrame: 0, frameCount: totalFrames, token: token)
        node.play()

        startEngineTimer()
        isPlaying = true
        let offlinePrefix = LocalStorage.findDownloadedFile(for: track) != nil ? "Оффлайн: " : ""
        vkClient?.statusText = "\(offlinePrefix)\(track.artist) — \(track.title)"
        updateNowPlayingInfo()
    }

    private func scheduleSegment(
        node: AVAudioPlayerNode,
        file: AVAudioFile,
        startFrame: AVAudioFramePosition,
        frameCount: AVAudioFrameCount,
        token: UInt64
    ) {
        let expectedIsA = (node === playerNodeA)
        node.scheduleSegment(
            file,
            startingFrame: startFrame,
            frameCount: frameCount,
            at: nil,
            completionCallbackType: .dataPlayedBack
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self,
                      self.usingEngine,
                      self.mainEngineToken == token,
                      self.activeIsA == expectedIsA,
                      self.isPlaying,
                      !self.didTriggerTransitionForCurrent else {
                    return
                }
                self.nextTrack(manual: false)
            }
        }
    }

    private func startEngineTimer() {
        engineTimer?.invalidate()
        engineTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateEngineProgress()
            }
        }
    }

    private func updateEngineProgress() {
        guard usingEngine, isPlaying else { return }
        let node = activePlayerNode
        guard node.isPlaying,
              let nodeTime = node.lastRenderTime,
              nodeTime.isSampleTimeValid,
              let playerTime = node.playerTime(forNodeTime: nodeTime),
              playerTime.sampleTime >= 0,
              playerTime.sampleRate > 0 else {
            return
        }
        let secs = engineBaseSeconds + Double(playerTime.sampleTime) / playerTime.sampleRate
        if secs.isFinite {
            let clamped = duration > 0 ? min(duration, max(0, secs)) : max(0, secs)
            liveElapsedSeconds = clamped
            if abs(clamped - currentTime) >= 0.25 {
                currentTime = clamped
            }
        }
        checkCrossfadeTrigger()
    }

    private func startAVPlayerFallback(url: URL, track: VKTrack, crossfadeInDuration: Double) {
        engineTimer?.invalidate()
        engineTimer = nil
        playerNodeA.stop()
        playerNodeB.stop()
        activeFile = nil
        fadingFile = nil
        usingEngine = false

        cleanupAVPlayerObservers()
        if crossfadeInDuration <= 0 {
            stopCrossfadeImmediate()
            player?.pause()
            player = nil
        }

        try? AVAudioSession.sharedInstance().setActive(true)
        let asset: AVURLAsset
        if url.isFileURL {
            asset = AVURLAsset(url: url)
        } else {
            asset = AVURLAsset(url: url, options: [
                "AVURLAssetHTTPHeaderFieldsKey": [
                    "User-Agent": VKAPIClient.desktopUserAgent
                ]
            ])
        }

        let item = AVPlayerItem(asset: asset)
        let newPlayer = AVPlayer(playerItem: item)
        self.player = newPlayer
        self.liveElapsedSeconds = 0
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
            forInterval: CMTime(seconds: 0.15, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            Task { @MainActor in
                guard let self else { return }
                let secs = time.seconds
                if secs.isFinite {
                    let clamped = max(0, secs)
                    self.liveElapsedSeconds = clamped
                    if abs(clamped - self.currentTime) >= 0.25 {
                        self.currentTime = clamped
                    }
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

    // MARK: - Prefetch & Crossfade

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
        let remaining = duration - liveElapsedSeconds
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

        if usingEngine {
            mainEngineToken &+= 1
            fadingFile = activeFile
            activeIsA.toggle()
            fadingStartDate = Date()
        } else {
            cleanupAVPlayerObservers()
            fadingPlayer?.pause()
            fadingPlayer = player
            fadingStartDate = Date()
            player = nil
        }

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

        if usingEngine {
            if fadingFile != nil, let fStart = fadingStartDate {
                let t = min(1.0, max(0.0, Date().timeIntervalSince(fStart) / dur))
                let fadingNode = retiringPlayerNode
                if t >= 1.0 {
                    fadingNode.stop()
                    fadingFile = nil
                    fadingStartDate = nil
                } else {
                    fadingNode.volume = isMuted ? 0 : Float(1.0 - t) * baseGain
                }
            }

            if let inStart = fadeInStartDate {
                let t = min(1.0, max(0.0, Date().timeIntervalSince(inStart) / dur))
                activePlayerNode.volume = Float(t) * baseGain
                if t >= 1.0 {
                    fadeInStartDate = nil
                    activePlayerNode.volume = baseGain
                }
            }

            if fadingFile == nil && fadeInStartDate == nil {
                crossfadeTimer?.invalidate()
                crossfadeTimer = nil
            }
        } else {
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
    }

    private func stopCrossfadeImmediate() {
        crossfadeTimer?.invalidate()
        crossfadeTimer = nil
        retiringPlayerNode.stop()
        fadingFile = nil
        fadingPlayer?.pause()
        fadingPlayer = nil
        fadingStartDate = nil
        fadeInStartDate = nil
        activeFadeDuration = 0
    }

    private func cleanupAVPlayerObservers() {
        if let obs = timeObserver, let player {
            player.removeTimeObserver(obs)
        }
        timeObserver = nil
        if let endObs = endObserver {
            NotificationCenter.default.removeObserver(endObs)
        }
        endObserver = nil
    }

    // MARK: - Artwork & Lock Screen Metadata

    private func fetchArtworkIfNeeded(for track: VKTrack) {
        guard !track.coverUrl.isEmpty else { return }
        if cachedArtwork?.0 == track.coverUrl {
            updateNowPlayingInfo()
            return
        }
        let coverStr = track.coverUrl
        Task { [weak self] in
            let image = await CoverImageCache.shared.image(for: coverStr)
            guard let self, let image else { return }
            self.cachedArtwork = (coverStr, image)
            if self.currentTrack?.coverUrl == coverStr {
                self.updateNowPlayingInfo()
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
