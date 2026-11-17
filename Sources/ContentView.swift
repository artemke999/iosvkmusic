import SwiftUI

private enum StudioPalette {
    static let canvas = Color(red: 10 / 255, green: 10 / 255, blue: 12 / 255)
    static let deck = Color(red: 19 / 255, green: 19 / 255, blue: 23 / 255)
    static let surface = Color(red: 24 / 255, green: 24 / 255, blue: 29 / 255)
    static let surfaceActive = Color(red: 36 / 255, green: 36 / 255, blue: 44 / 255)
    static let borderHairline = Color(red: 35 / 255, green: 35 / 255, blue: 42 / 255)
    static let borderActive = Color(red: 56 / 255, green: 56 / 255, blue: 68 / 255)
    static let textPrimary = Color(red: 242 / 255, green: 242 / 255, blue: 243 / 255)
    static let textSecondary = Color(red: 142 / 255, green: 142 / 255, blue: 152 / 255)
    static let textMuted = Color(red: 90 / 255, green: 90 / 255, blue: 100 / 255)
    static let accentSaved = Color(red: 48 / 255, green: 209 / 255, blue: 88 / 255)
}

struct ContentView: View {
    @EnvironmentObject var vkClient: VKAPIClient
    @EnvironmentObject var player: AudioPlayerManager

    @State private var searchText: String = ""
    @State private var showAuthSheet: Bool = false
    @State private var showNowPlayingSheet: Bool = false
    @State private var showPlaylistsSheet: Bool = false

    private var filteredTracks: [VKTrack] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return vkClient.tracks }
        return vkClient.tracks.filter {
            $0.title.lowercased().contains(q)
                || $0.artist.lowercased().contains(q)
                || $0.albumTitle.lowercased().contains(q)
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            StudioPalette.canvas.ignoresSafeArea()

            VStack(spacing: 0) {
                headerView
                sectionStrip
                actionBar
                Divider().overlay(StudioPalette.borderHairline)
                trackListView
            }

            if player.currentTrack != nil {
                miniPlayerBar
            }
        }
        .sheet(isPresented: $showAuthSheet) {
            VKWebAuthSheet()
        }
        .sheet(isPresented: $showNowPlayingSheet) {
            NowPlayingSheet()
        }
        .sheet(isPresented: $showPlaylistsSheet) {
            PlaylistsSheet(
                playlists: vkClient.playlists,
                onSelect: { pl in
                    showPlaylistsSheet = false
                    Task { await vkClient.loadSection(.playlist(pl)) }
                }
            )
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("VK Music")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(StudioPalette.textPrimary)
                    Text("Studio")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(StudioPalette.textMuted)
                }

                Spacer()

                Button {
                    showAuthSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(vkClient.user != nil ? StudioPalette.accentSaved : StudioPalette.textMuted)
                            .frame(width: 7, height: 7)
                        Text(vkClient.user?.name ?? "Войти в VK")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(StudioPalette.textPrimary)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(StudioPalette.surface)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(StudioPalette.borderHairline, lineWidth: 1)
                    )
                }
            }

            // Search / Filter Input
            HStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 13))
                        .foregroundColor(StudioPalette.textMuted)

                    TextField("Фильтр или поиск в VK...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14))
                        .foregroundColor(StudioPalette.textPrimary)
                        .submitLabel(.search)
                        .onSubmit {
                            let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !q.isEmpty {
                                Task { await vkClient.loadSection(.search(q)) }
                            }
                        }

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(StudioPalette.textMuted)
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(StudioPalette.surface)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(StudioPalette.borderHairline, lineWidth: 1)
                )

                Button {
                    let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !q.isEmpty {
                        Task { await vkClient.loadSection(.search(q)) }
                    } else {
                        Task { await vkClient.loadSection(vkClient.currentSection) }
                    }
                } label: {
                    Image(systemName: searchText.isEmpty ? "arrow.clockwise" : "arrow.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(StudioPalette.textPrimary)
                        .frame(width: 34, height: 34)
                        .background(StudioPalette.surface)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(StudioPalette.borderHairline, lineWidth: 1)
                        )
                }
            }

            Text(vkClient.statusText)
                .font(.system(size: 11.5))
                .foregroundColor(StudioPalette.textSecondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 8)
    }

    // MARK: - Section Pills

    private var sectionStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                sectionPill("Моя музыка", active: vkClient.currentSection == .myMusic) {
                    Task { await vkClient.loadSection(.myMusic) }
                }
                sectionPill("Рекомендации", active: vkClient.currentSection == .recommendations) {
                    Task { await vkClient.loadSection(.recommendations) }
                }
                sectionPill("Популярное", active: vkClient.currentSection == .popular) {
                    Task { await vkClient.loadSection(.popular) }
                }
                sectionPill(
                    playlistsLabel,
                    active: isPlaylistActive
                ) {
                    showPlaylistsSheet = true
                }
                sectionPill("На диске", active: vkClient.currentSection == .downloaded) {
                    Task { await vkClient.loadSection(.downloaded) }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
    }

    private var isPlaylistActive: Bool {
        if case .playlist = vkClient.currentSection { return true }
        return false
    }

    private var playlistsLabel: String {
        if case .playlist(let pl) = vkClient.currentSection {
            return pl.title
        }
        return vkClient.playlists.isEmpty ? "Плейлисты" : "Плейлисты (\(vkClient.playlists.count))"
    }

    private func sectionPill(_ title: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: active ? .semibold : .regular))
                .foregroundColor(active ? StudioPalette.textPrimary : StudioPalette.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(active ? StudioPalette.surfaceActive : StudioPalette.surface)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(active ? StudioPalette.borderActive : StudioPalette.borderHairline, lineWidth: 1)
                )
        }
    }

    // MARK: - Batch Actions

    private var actionBar: some View {
        HStack(spacing: 8) {
            Button {
                let list = filteredTracks
                if !list.isEmpty {
                    player.playFromList(list, index: 0)
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 11))
                    Text("Слушать")
                        .font(.system(size: 12.5, weight: .semibold))
                }
                .foregroundColor(StudioPalette.canvas)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(StudioPalette.textPrimary)
                .cornerRadius(8)
            }

            Button {
                let list = filteredTracks
                if !list.isEmpty {
                    if !player.shuffle { player.toggleShuffle() }
                    let idx = Int.random(in: 0..<list.count)
                    player.playFromList(list, index: idx)
                }
            } label: {
                Text("Перемешать")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundColor(StudioPalette.textPrimary)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 7)
                    .background(StudioPalette.surface)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(StudioPalette.borderHairline, lineWidth: 1)
                    )
            }

            Button {
                let list = filteredTracks
                if !list.isEmpty {
                    Task { await vkClient.downloadAll(list) }
                }
            } label: {
                Text(vkClient.batchDownloading ? "Загрузка..." : "↓ Скачать все")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundColor(StudioPalette.textPrimary)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 7)
                    .background(StudioPalette.surface)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(StudioPalette.borderHairline, lineWidth: 1)
                    )
            }
            .disabled(vkClient.batchDownloading)

            Spacer()

            Text("\(filteredTracks.count)")
                .font(.system(size: 11.5, design: .monospaced))
                .foregroundColor(StudioPalette.textMuted)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Track List

    private var trackListView: some View {
        Group {
            if vkClient.isLoading && vkClient.tracks.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    ProgressView()
                        .tint(StudioPalette.textPrimary)
                    Text("Загрузка медиатеки...")
                        .font(.system(size: 13))
                        .foregroundColor(StudioPalette.textSecondary)
                    Spacer()
                }
            } else if filteredTracks.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Text(vkClient.hasSavedSession ? "Треки не найдены" : "Подключите аккаунт VK")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(StudioPalette.textSecondary)
                    if !vkClient.hasSavedSession {
                        Button("Войти через браузер VK") {
                            showAuthSheet = true
                        }
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundColor(StudioPalette.canvas)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(StudioPalette.textPrimary)
                        .cornerRadius(8)
                    }
                    Spacer()
                }
            } else {
                let list = filteredTracks
                let showAdd = vkClient.currentSection != .myMusic && vkClient.currentSection != .downloaded

                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(Array(list.enumerated()), id: \.element.fullId) { index, track in
                            let isCurrent = player.currentTrack?.fullId == track.fullId
                            let isSaved = vkClient.downloadedIds.contains(track.fullId)
                            let isDownloading = vkClient.downloadingIds.contains(track.fullId)

                            TrackRowView(
                                index: index,
                                track: track,
                                isCurrent: isCurrent,
                                isPlaying: isCurrent && player.isPlaying,
                                isSaved: isSaved,
                                isDownloading: isDownloading,
                                showAddButton: showAdd,
                                onTap: {
                                    player.playFromList(list, index: index)
                                },
                                onAdd: {
                                    Task { await vkClient.addAudio(track: track) }
                                },
                                onDownload: {
                                    Task { await vkClient.downloadTrack(track) }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 6)
                    .padding(.bottom, player.currentTrack != nil ? 96 : 20)
                }
            }
        }
    }

    // MARK: - Bottom Mini-Player

    private var miniPlayerBar: some View {
        Group {
            if let track = player.currentTrack {
                VStack(spacing: 0) {
                    GeometryReader { geo in
                        let progress = player.duration > 0 ? min(1, max(0, player.currentTime / player.duration)) : 0
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(StudioPalette.borderHairline)
                            Rectangle()
                                .fill(StudioPalette.textPrimary)
                                .frame(width: geo.size.width * progress)
                        }
                    }
                    .frame(height: 2)

                    HStack(spacing: 12) {
                        CoverThumb(urlString: track.coverUrl, size: 42, radius: 6)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(track.title)
                                .font(.system(size: 13.5, weight: .semibold))
                                .foregroundColor(StudioPalette.textPrimary)
                                .lineLimit(1)
                            Text(track.artist)
                                .font(.system(size: 12))
                                .foregroundColor(StudioPalette.textSecondary)
                                .lineLimit(1)
                        }

                        Spacer()

                        Button {
                            player.previousTrack()
                        } label: {
                            Image(systemName: "backward.end.fill")
                                .font(.system(size: 15))
                                .foregroundColor(StudioPalette.textSecondary)
                                .frame(width: 32, height: 32)
                        }

                        Button {
                            player.togglePlayPause()
                        } label: {
                            Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 15))
                                .foregroundColor(StudioPalette.canvas)
                                .frame(width: 34, height: 34)
                                .background(StudioPalette.textPrimary)
                                .clipShape(Circle())
                        }

                        Button {
                            player.nextTrack(manual: true)
                        } label: {
                            Image(systemName: "forward.end.fill")
                                .font(.system(size: 15))
                                .foregroundColor(StudioPalette.textSecondary)
                                .frame(width: 32, height: 32)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .background(StudioPalette.deck)
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(StudioPalette.borderHairline),
                    alignment: .top
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    showNowPlayingSheet = true
                }
            }
        }
    }
}

// MARK: - Subviews

private struct TrackRowView: View {
    let index: Int
    let track: VKTrack
    let isCurrent: Bool
    let isPlaying: Bool
    let isSaved: Bool
    let isDownloading: Bool
    let showAddButton: Bool
    let onTap: () -> Void
    let onAdd: () -> Void
    let onDownload: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Group {
                if isCurrent {
                    HStack(spacing: 2) {
                        Capsule().frame(width: 2.5, height: isPlaying ? 8 : 4)
                        Capsule().frame(width: 2.5, height: isPlaying ? 14 : 4)
                        Capsule().frame(width: 2.5, height: isPlaying ? 10 : 4)
                    }
                    .foregroundColor(StudioPalette.textPrimary)
                } else {
                    Text(String(format: "%02d", index + 1))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(StudioPalette.textMuted)
                }
            }
            .frame(width: 24)

            CoverThumb(urlString: track.coverUrl, size: 42, radius: 6)

            VStack(alignment: .leading, spacing: 2) {
                Text(track.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(StudioPalette.textPrimary)
                    .lineLimit(1)
                Text(track.artist)
                    .font(.system(size: 12))
                    .foregroundColor(StudioPalette.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 6)

            if showAddButton {
                Button(action: onAdd) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(StudioPalette.textSecondary)
                        .frame(width: 28, height: 28)
                        .background(StudioPalette.surface)
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(StudioPalette.borderHairline, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }

            Button(action: onDownload) {
                Group {
                    if isDownloading {
                        ProgressView()
                            .scaleEffect(0.7)
                            .tint(StudioPalette.textSecondary)
                    } else if isSaved {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(StudioPalette.accentSaved)
                    } else {
                        Image(systemName: "arrow.down")
                            .font(.system(size: 11.5, weight: .semibold))
                            .foregroundColor(StudioPalette.textSecondary)
                    }
                }
                .frame(width: 28, height: 28)
                .background(StudioPalette.surface)
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(StudioPalette.borderHairline, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            Text(track.durationText)
                .font(.system(size: 11.5, design: .monospaced))
                .foregroundColor(StudioPalette.textMuted)
                .frame(width: 38, alignment: .trailing)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(isCurrent ? StudioPalette.surfaceActive : Color.clear)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isCurrent ? StudioPalette.borderActive : Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

private struct CoverThumb: View {
    let urlString: String
    let size: CGFloat
    let radius: CGFloat

    var body: some View {
        Group {
            if let url = URL(string: urlString), !urlString.isEmpty {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .cornerRadius(radius)
        .clipped()
    }

    private var placeholder: some View {
        ZStack {
            StudioPalette.surface
            Image(systemName: "music.note")
                .font(.system(size: size * 0.35))
                .foregroundColor(StudioPalette.textMuted)
        }
    }
}

private struct PlaylistsSheet: View {
    let playlists: [VKPlaylist]
    let onSelect: (VKPlaylist) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                StudioPalette.canvas.ignoresSafeArea()
                if playlists.isEmpty {
                    Text("Плейлисты не найдены")
                        .foregroundColor(StudioPalette.textSecondary)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 6) {
                            ForEach(playlists) { pl in
                                Button {
                                    onSelect(pl)
                                } label: {
                                    HStack {
                                        Text(pl.title)
                                            .font(.system(size: 14.5, weight: .medium))
                                            .foregroundColor(StudioPalette.textPrimary)
                                            .lineLimit(1)
                                        Spacer()
                                        Text("\(pl.count)")
                                            .font(.system(size: 12, design: .monospaced))
                                            .foregroundColor(StudioPalette.textMuted)
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                    .background(StudioPalette.surface)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(StudioPalette.borderHairline, lineWidth: 1)
                                    )
                                }
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Плейлисты")
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

private struct NowPlayingSheet: View {
    @EnvironmentObject var vkClient: VKAPIClient
    @EnvironmentObject var player: AudioPlayerManager
    @Environment(\.dismiss) private var dismiss

    @State private var isDragging: Bool = false
    @State private var dragValue: Double = 0

    var body: some View {
        ZStack {
            StudioPalette.canvas.ignoresSafeArea()

            if let track = player.currentTrack {
                VStack(spacing: 24) {
                    Capsule()
                        .fill(StudioPalette.borderActive)
                        .frame(width: 38, height: 4)
                        .padding(.top, 10)

                    Spacer()

                    CoverThumb(urlString: track.coverUrl, size: 280, radius: 12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(StudioPalette.borderHairline, lineWidth: 1)
                        )

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(track.title)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(StudioPalette.textPrimary)
                                .lineLimit(2)
                            Text(track.artist)
                                .font(.system(size: 15))
                                .foregroundColor(StudioPalette.textSecondary)
                                .lineLimit(1)
                        }
                        Spacer()

                        let isSaved = vkClient.downloadedIds.contains(track.fullId)
                        let isDownloading = vkClient.downloadingIds.contains(track.fullId)
                        Button {
                            Task { await vkClient.downloadTrack(track) }
                        } label: {
                            Group {
                                if isDownloading {
                                    ProgressView().tint(StudioPalette.textPrimary)
                                } else if isSaved {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(StudioPalette.accentSaved)
                                } else {
                                    Image(systemName: "arrow.down")
                                        .foregroundColor(StudioPalette.textPrimary)
                                }
                            }
                            .frame(width: 38, height: 38)
                            .background(StudioPalette.surface)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(StudioPalette.borderHairline, lineWidth: 1)
                            )
                        }
                    }

                    // Seek Slider
                    VStack(spacing: 6) {
                        let maxDur = max(1.0, player.duration)
                        Slider(
                            value: Binding(
                                get: { isDragging ? dragValue : min(player.currentTime, maxDur) },
                                set: { newVal in
                                    isDragging = true
                                    dragValue = newVal
                                }
                            ),
                            in: 0...maxDur,
                            onEditingChanged: { editing in
                                if !editing {
                                    player.seek(to: dragValue)
                                    isDragging = false
                                }
                            }
                        )
                        .tint(StudioPalette.textPrimary)

                        HStack {
                            Text(formatTime(isDragging ? dragValue : player.currentTime))
                            Spacer()
                            Text(formatTime(player.duration))
                        }
                        .font(.system(size: 11.5, design: .monospaced))
                        .foregroundColor(StudioPalette.textMuted)
                    }

                    // Transport Controls
                    HStack(spacing: 28) {
                        Button {
                            player.toggleShuffle()
                        } label: {
                            Image(systemName: "shuffle")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(player.shuffle ? StudioPalette.textPrimary : StudioPalette.textMuted)
                        }

                        Button {
                            player.previousTrack()
                        } label: {
                            Image(systemName: "backward.end.fill")
                                .font(.system(size: 24))
                                .foregroundColor(StudioPalette.textPrimary)
                        }

                        Button {
                            player.togglePlayPause()
                        } label: {
                            Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 26))
                                .foregroundColor(StudioPalette.canvas)
                                .frame(width: 64, height: 64)
                                .background(StudioPalette.textPrimary)
                                .clipShape(Circle())
                        }

                        Button {
                            player.nextTrack(manual: true)
                        } label: {
                            Image(systemName: "forward.end.fill")
                                .font(.system(size: 24))
                                .foregroundColor(StudioPalette.textPrimary)
                        }

                        Button {
                            player.cycleRepeatMode()
                        } label: {
                            Image(systemName: player.repeatMode == .one ? "repeat.1" : "repeat")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(player.repeatMode != .none ? StudioPalette.textPrimary : StudioPalette.textMuted)
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal, 24)
            } else {
                Button("Закрыть") { dismiss() }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func formatTime(_ secs: Double) -> String {
        let total = max(0, Int(secs))
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
