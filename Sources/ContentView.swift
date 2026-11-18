import SwiftUI

// MARK: - Themes & Layout Models

enum AppThemeKind: String, CaseIterable, Identifiable {
    case skyShards = "sky-shards"
    case airpodsProBlack = "airpods-pro-black"

    var id: String { rawValue }

    var toggled: AppThemeKind {
        self == .skyShards ? .airpodsProBlack : .skyShards
    }

    var colorScheme: ColorScheme {
        self == .skyShards ? .light : .dark
    }

    var subtitleTag: String {
        self == .skyShards ? "SKY SHARDS" : "OBSIDIAN PRO"
    }
}

enum NowPlayingTab: String, CaseIterable {
    case player
    case queue
    case equalizer
}

struct ThemePalette {
    let kind: AppThemeKind
    let bgTop: Color
    let bgBottom: Color
    let surface: Color
    let surfaceMuted: Color
    let surfaceActive: Color
    let border: Color
    let strongBorder: Color
    let textPrimary: Color
    let textSecondary: Color
    let textMuted: Color
    let accent: Color
    let accentSoft: Color
    let accentText: Color
    let pillBg: Color
    let pillText: Color
    let miniBg: Color
    let savedGreen: Color
    let isDark: Bool

    init(_ kind: AppThemeKind) {
        self.kind = kind
        self.savedGreen = Color(red: 48 / 255, green: 209 / 255, blue: 88 / 255)

        switch kind {
        case .skyShards:
            self.isDark = false
            self.bgTop = Color(red: 223 / 255, green: 240 / 255, blue: 251 / 255)
            self.bgBottom = Color(red: 242 / 255, green: 247 / 255, blue: 252 / 255)
            self.surface = Color.white.opacity(0.80)
            self.surfaceMuted = Color(red: 217 / 255, green: 236 / 255, blue: 252 / 255).opacity(0.68)
            self.surfaceActive = Color(red: 111 / 255, green: 176 / 255, blue: 236 / 255).opacity(0.24)
            self.border = Color(red: 88 / 255, green: 136 / 255, blue: 178 / 255).opacity(0.22)
            self.strongBorder = Color(red: 34 / 255, green: 62 / 255, blue: 92 / 255).opacity(0.32)
            self.textPrimary = Color(red: 22 / 255, green: 34 / 255, blue: 48 / 255)
            self.textSecondary = Color(red: 75 / 255, green: 97 / 255, blue: 120 / 255)
            self.textMuted = Color(red: 125 / 255, green: 146 / 255, blue: 168 / 255)
            self.accent = Color(red: 76 / 255, green: 143 / 255, blue: 214 / 255)
            self.accentSoft = Color(red: 111 / 255, green: 176 / 255, blue: 236 / 255).opacity(0.24)
            self.accentText = Color(red: 18 / 255, green: 62 / 255, blue: 107 / 255)
            self.pillBg = Color(red: 30 / 255, green: 53 / 255, blue: 77 / 255)
            self.pillText = Color(red: 245 / 255, green: 250 / 255, blue: 255 / 255)
            self.miniBg = Color.white.opacity(0.90)

        case .airpodsProBlack:
            // Minimalist Apple Obsidian / Titanium palette matching PC version
            self.isDark = true
            self.bgTop = Color(red: 10 / 255, green: 10 / 255, blue: 12 / 255)
            self.bgBottom = Color(red: 16 / 255, green: 16 / 255, blue: 19 / 255)
            self.surface = Color(red: 24 / 255, green: 24 / 255, blue: 29 / 255)
            self.surfaceMuted = Color(red: 32 / 255, green: 32 / 255, blue: 39 / 255)
            self.surfaceActive = Color(red: 36 / 255, green: 36 / 255, blue: 44 / 255)
            self.border = Color(red: 38 / 255, green: 38 / 255, blue: 46 / 255)
            self.strongBorder = Color(red: 58 / 255, green: 58 / 255, blue: 68 / 255)
            self.textPrimary = Color(red: 242 / 255, green: 242 / 255, blue: 243 / 255)
            self.textSecondary = Color(red: 142 / 255, green: 142 / 255, blue: 152 / 255)
            self.textMuted = Color(red: 90 / 255, green: 90 / 255, blue: 100 / 255)
            self.accent = Color(red: 229 / 255, green: 229 / 255, blue: 234 / 255)
            self.accentSoft = Color(red: 44 / 255, green: 44 / 255, blue: 54 / 255)
            self.accentText = Color(red: 242 / 255, green: 242 / 255, blue: 243 / 255)
            self.pillBg = Color(red: 242 / 255, green: 242 / 255, blue: 243 / 255)
            self.pillText = Color(red: 10 / 255, green: 10 / 255, blue: 12 / 255)
            self.miniBg = Color(red: 19 / 255, green: 19 / 255, blue: 23 / 255).opacity(0.95)
        }
    }
}

// MARK: - Ambient Backdrop

private struct AppBackdropView: View {
    let palette: ThemePalette

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [palette.bgTop, palette.bgBottom],
                startPoint: .top,
                endPoint: .bottom
            )

            if palette.kind == .skyShards {
                RadialGradient(
                    colors: [Color(red: 133 / 255, green: 192 / 255, blue: 238 / 255).opacity(0.45), .clear],
                    center: .topLeading,
                    startRadius: 10,
                    endRadius: 320
                )
                RadialGradient(
                    colors: [Color(red: 164 / 255, green: 214 / 255, blue: 160 / 255).opacity(0.18), .clear],
                    center: .bottomTrailing,
                    startRadius: 10,
                    endRadius: 280
                )
            } else {
                RadialGradient(
                    colors: [Color.white.opacity(0.045), .clear],
                    center: .top,
                    startRadius: 10,
                    endRadius: 320
                )
            }
        }
        .ignoresSafeArea()
    }
}

private struct SkyShardShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.width * 0.35, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height * 0.12))
        path.addLine(to: CGPoint(x: rect.width * 0.74, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height * 0.64))
        path.closeSubpath()
        return path
    }
}

// MARK: - Main Screen

struct ContentView: View {
    @EnvironmentObject var vkClient: VKAPIClient
    @EnvironmentObject var player: AudioPlayerManager

    @AppStorage("ui_theme") private var rawTheme: String = AppThemeKind.skyShards.rawValue

    @State private var searchText: String = ""
    @State private var browsingPlaylists: Bool = false
    @State private var activeOfflineGroup: VKOfflinePlaylist?
    @State private var showAuthSheet: Bool = false
    @State private var showNowPlayingSheet: Bool = false
    @State private var nowPlayingTab: NowPlayingTab = .player

    private var themeKind: AppThemeKind {
        AppThemeKind(rawValue: rawTheme) ?? .skyShards
    }

    private var palette: ThemePalette {
        ThemePalette(themeKind)
    }

    private var currentTracksSource: [VKTrack] {
        if vkClient.currentSection == .downloaded, let group = activeOfflineGroup {
            return group.tracks
        }
        return vkClient.tracks
    }

    private var filteredTracks: [VKTrack] {
        let base = currentTracksSource
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return base }
        if case .search(let searchedQ) = vkClient.currentSection,
           q == searchedQ.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
            return base
        }
        let words = q.split(whereSeparator: { $0.isWhitespace }).map(String.init)
        return base.filter { track in
            let titleLow = track.title.lowercased()
            let artistLow = track.artist.lowercased()
            let albumLow = track.albumTitle.lowercased()
            return words.allSatisfy { w in
                titleLow.contains(w) || artistLow.contains(w) || albumLow.contains(w)
            }
        }
    }

    private var hasActiveTrack: Bool {
        player.currentTrack != nil
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppBackdropView(palette: palette)

            VStack(spacing: 0) {
                headerArea
                sectionTabsStrip
                mainContentArea
            }

            if hasActiveTrack {
                MiniPlayerBar(
                    player: player,
                    palette: palette,
                    onTapBar: {
                        nowPlayingTab = .player
                        showNowPlayingSheet = true
                    },
                    onTapQueue: {
                        nowPlayingTab = .queue
                        showNowPlayingSheet = true
                    }
                )
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
            }
        }
        .preferredColorScheme(themeKind.colorScheme)
        .sheet(isPresented: $showAuthSheet) {
            VKWebAuthSheet()
        }
        .sheet(isPresented: $showNowPlayingSheet) {
            NowPlayingSheet(
                selectedTab: $nowPlayingTab,
                palette: palette,
                onToggleTheme: toggleTheme
            )
        }
    }

    private func toggleTheme() {
        withAnimation(.easeInOut(duration: 0.2)) {
            rawTheme = themeKind.toggled.rawValue
        }
    }

    // MARK: - Header & Search

    private var headerArea: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("VK Music")
                        .font(.system(size: 17, weight: .heavy))
                        .tracking(-0.3)
                        .foregroundColor(palette.textPrimary)

                    Text(headerSubtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(palette.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 4)

                headerActionButtons
            }
            .padding(.horizontal, 12)
            .frame(height: 60)
            .background(
                GeometryReader { geo in
                    ZStack(alignment: .trailing) {
                        palette.surface

                        if themeKind == .skyShards {
                            Image("Art2Sky")
                                .resizable()
                                .scaledToFill()
                                .frame(width: geo.size.width, height: geo.size.height)
                                .opacity(0.36)

                            LinearGradient(
                                colors: [palette.surface.opacity(0.74), palette.surface.opacity(0.28)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )

                            SkyShardShape()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.55), Color(red: 140 / 255, green: 200 / 255, blue: 245 / 255).opacity(0.22)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 112, height: 108)
                                .offset(x: 16, y: -12)
                        } else {
                            LinearGradient(
                                colors: [
                                    Color(red: 28 / 255, green: 28 / 255, blue: 34 / 255).opacity(0.65),
                                    Color(red: 16 / 255, green: 16 / 255, blue: 20 / 255).opacity(0.95)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        }
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(palette.border, lineWidth: 1)
            )

            // Search bar
            HStack(spacing: 7) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(palette.textMuted)

                TextField("Поиск треков и артистов...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13.5))
                    .foregroundColor(palette.textPrimary)
                    .submitLabel(.search)
                    .onSubmit {
                        submitSearchOrReload()
                    }

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(palette.textMuted)
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    submitSearchOrReload()
                } label: {
                    Image(systemName: searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "arrow.clockwise" : "arrow.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(palette.accentText)
                        .frame(width: 24, height: 24)
                        .background(palette.accentSoft)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 10)
            .frame(height: 36)
            .background(palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(palette.border, lineWidth: 1)
            )
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .padding(.bottom, 8)
    }

    private var headerActionButtons: some View {
        let chipBg = palette.isDark ? palette.surfaceMuted : Color.white.opacity(0.65)
        let chipStroke = palette.border

        return HStack(spacing: 5) {
            Button {
                nowPlayingTab = .queue
                showNowPlayingSheet = true
            } label: {
                Image(systemName: "list.bullet")
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundColor(palette.textPrimary)
                    .frame(width: 28, height: 27)
                    .background(chipBg)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(chipStroke, lineWidth: 1))
            }
            .buttonStyle(.plain)

            Button {
                nowPlayingTab = .equalizer
                showNowPlayingSheet = true
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: player.isAirPodsConnected ? "airpods.gen3" : "slider.horizontal.3")
                        .font(.system(size: 10.5, weight: .bold))
                    Text("EQ")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(player.eqEnabled ? palette.accentText : palette.textPrimary)
                .padding(.horizontal, 8)
                .frame(height: 27)
                .background(player.eqEnabled ? palette.accentSoft : chipBg)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(player.eqEnabled ? palette.strongBorder : chipStroke, lineWidth: 1))
            }
            .buttonStyle(.plain)

            Button(action: toggleTheme) {
                Text("✦")
                    .font(.system(size: 12.5, weight: .bold))
                    .foregroundColor(palette.textPrimary)
                    .frame(width: 28, height: 27)
                    .background(chipBg)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(chipStroke, lineWidth: 1))
            }
            .buttonStyle(.plain)

            Button {
                showAuthSheet = true
            } label: {
                HStack(spacing: 4) {
                    Circle()
                        .fill(vkClient.user != nil ? palette.savedGreen : Color.orange)
                        .frame(width: 6, height: 6)
                    Text(vkClient.user?.name ?? "Войти")
                        .font(.system(size: 11, weight: .semibold))
                        .lineLimit(1)
                }
                .foregroundColor(palette.textPrimary)
                .frame(maxWidth: 78)
                .padding(.horizontal, 7)
                .frame(height: 27)
                .background(chipBg)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(chipStroke, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    private var headerSubtitle: String {
        if player.isAirPodsConnected {
            return "🎧 \(player.audioRouteName) · \(player.eqPreset.title)"
        }
        if vkClient.isLoading {
            return vkClient.statusText
        }
        if !vkClient.statusText.isEmpty && (vkClient.batchDownloading || vkClient.downloadingPlaylistId != nil) {
            return vkClient.statusText
        }
        return "\(themeKind.subtitleTag) · \(filteredTracks.count) треков"
    }

    private func submitSearchOrReload() {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        browsingPlaylists = false
        activeOfflineGroup = nil
        if !q.isEmpty {
            Task { await vkClient.loadSection(.search(q)) }
        } else {
            Task { await vkClient.loadSection(vkClient.currentSection) }
        }
    }

    // MARK: - Section Tabs Strip

    private var sectionTabsStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                sectionPill("Моя музыка", active: !browsingPlaylists && vkClient.currentSection == .myMusic) {
                    browsingPlaylists = false
                    activeOfflineGroup = nil
                    Task { await vkClient.loadSection(.myMusic) }
                }
                sectionPill("Недавно", active: !browsingPlaylists && vkClient.currentSection == .recentlyPlayed) {
                    browsingPlaylists = false
                    activeOfflineGroup = nil
                    Task { await vkClient.loadSection(.recentlyPlayed) }
                }
                sectionPill(playlistsTabTitle, active: browsingPlaylists || isPlaylistSection) {
                    browsingPlaylists = true
                    activeOfflineGroup = nil
                }
                sectionPill("Рекомендации", active: !browsingPlaylists && vkClient.currentSection == .recommendations) {
                    browsingPlaylists = false
                    activeOfflineGroup = nil
                    Task { await vkClient.loadSection(.recommendations) }
                }
                sectionPill("Популярное", active: !browsingPlaylists && vkClient.currentSection == .popular) {
                    browsingPlaylists = false
                    activeOfflineGroup = nil
                    Task { await vkClient.loadSection(.popular) }
                }
                sectionPill("На диске", active: !browsingPlaylists && vkClient.currentSection == .downloaded) {
                    browsingPlaylists = false
                    activeOfflineGroup = nil
                    Task { await vkClient.loadSection(.downloaded) }
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
    }

    private var isPlaylistSection: Bool {
        if case .playlist = vkClient.currentSection { return true }
        return false
    }

    private var playlistsTabTitle: String {
        if !browsingPlaylists, case .playlist(let pl) = vkClient.currentSection {
            return pl.title
        }
        return vkClient.playlists.isEmpty ? "Плейлисты" : "Плейлисты (\(vkClient.playlists.count))"
    }

    private func sectionPill(_ title: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(active ? palette.pillText : palette.textSecondary)
                .padding(.horizontal, 12)
                .frame(height: 30)
                .background(active ? palette.pillBg : palette.surface)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(active ? Color.clear : palette.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Main Content Area

    @ViewBuilder
    private var mainContentArea: some View {
        if browsingPlaylists {
            playlistsListView
        } else {
            trackListView
        }
    }

    private var playlistsListView: some View {
        let offlineGroupsById = Dictionary(uniqueKeysWithValues: vkClient.offlinePlaylistGroups.map { ($0.id, $0) })
        let virtualAlbums = vkClient.offlinePlaylistGroups.filter { $0.playlist.id < 0 }

        return Group {
            if vkClient.playlists.isEmpty && virtualAlbums.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Text(vkClient.hasSavedSession ? "Плейлисты не найдены" : "Подключите аккаунт VK")
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundColor(palette.textSecondary)
                    if !vkClient.hasSavedSession {
                        Button {
                            showAuthSheet = true
                        } label: {
                            Text("Войти через VK")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(palette.pillText)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 10)
                                .background(palette.pillBg)
                                .clipShape(Capsule())
                        }
                    }
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(Array(vkClient.playlists.enumerated()), id: \.element.fullId) { idx, pl in
                            let offlineRec = offlineGroupsById[pl.fullId]
                            let isBusy = vkClient.downloadingPlaylistId == pl.fullId
                            playlistCardRow(
                                playlist: pl,
                                fallbackIndex: idx,
                                offlineCount: offlineRec?.tracks.count ?? 0,
                                isDownloadingPlaylist: isBusy,
                                onOpen: {
                                    browsingPlaylists = false
                                    Task { await vkClient.loadSection(.playlist(pl)) }
                                },
                                onDownload: {
                                    Task { await vkClient.downloadPlaylist(pl) }
                                }
                            )
                        }

                        if !virtualAlbums.isEmpty {
                            HStack {
                                Text("СОХРАНЁННЫЕ АЛЬБОМЫ")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(palette.textMuted)
                                Spacer()
                            }
                            .padding(.top, 6)

                            ForEach(Array(virtualAlbums.enumerated()), id: \.element.id) { idx, group in
                                playlistCardRow(
                                    playlist: group.playlist,
                                    fallbackIndex: idx + 1,
                                    offlineCount: group.tracks.count,
                                    isDownloadingPlaylist: false,
                                    onOpen: {
                                        browsingPlaylists = false
                                        Task { await vkClient.loadSection(.playlist(group.playlist)) }
                                    },
                                    onDownload: nil
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 2)
                    .padding(.bottom, hasActiveTrack ? 86 : 16)
                }
            }
        }
    }

    private func playlistCardRow(
        playlist: VKPlaylist,
        fallbackIndex: Int,
        offlineCount: Int,
        isDownloadingPlaylist: Bool,
        onOpen: @escaping () -> Void,
        onDownload: (() -> Void)?
    ) -> some View {
        HStack(spacing: 10) {
            PlaylistCoverView(playlist: playlist, fallbackIndex: fallbackIndex, size: 48, radius: 10, palette: palette)

            VStack(alignment: .leading, spacing: 2.5) {
                Text(playlist.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(palette.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text("\(playlist.count) треков")
                        .font(.system(size: 11.5))
                        .foregroundColor(palette.textSecondary)

                    if offlineCount > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 10))
                            Text("\(offlineCount) оффлайн")
                                .font(.system(size: 10.5, weight: .semibold))
                        }
                        .foregroundColor(palette.savedGreen)
                    }
                }
            }

            Spacer()

            if let onDownload {
                let fullyOffline = playlist.count > 0 && offlineCount >= playlist.count
                Button(action: onDownload) {
                    Group {
                        if isDownloadingPlaylist {
                            ProgressView()
                                .scaleEffect(0.65)
                                .tint(palette.accent)
                        } else if fullyOffline {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: "arrow.down")
                                .font(.system(size: 11.5, weight: .bold))
                                .foregroundColor(palette.textSecondary)
                        }
                    }
                    .frame(width: 28, height: 28)
                    .background(fullyOffline ? palette.savedGreen : palette.surfaceMuted)
                    .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(isDownloadingPlaylist || vkClient.batchDownloading)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(palette.textMuted)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(palette.border, lineWidth: 1))
        .contentShape(Rectangle())
        .onTapGesture(perform: onOpen)
    }

    private var trackListView: some View {
        Group {
            if vkClient.isLoading && currentTracksSource.isEmpty {
                VStack(spacing: 10) {
                    Spacer()
                    ProgressView()
                        .tint(palette.accent)
                    Text("Загрузка треков...")
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundColor(palette.textSecondary)
                    Spacer()
                }
            } else if filteredTracks.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Text(emptyMessage)
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundColor(palette.textSecondary)
                    if !vkClient.hasSavedSession && vkClient.currentSection != .recentlyPlayed && vkClient.currentSection != .downloaded {
                        Button {
                            showAuthSheet = true
                        } label: {
                            Text("Войти через VK")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(palette.pillText)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 10)
                                .background(palette.pillBg)
                                .clipShape(Capsule())
                        }
                    }
                    Spacer()
                }
            } else {
                let list = filteredTracks
                let showAdd = vkClient.currentSection != .myMusic && vkClient.currentSection != .downloaded

                ScrollView {
                    LazyVStack(spacing: 3) {
                        contextualListBar(list: list)

                        if vkClient.currentSection == .downloaded && activeOfflineGroup == nil && searchText.trimmingCharacters(in: .whitespaces).isEmpty && !vkClient.offlinePlaylistGroups.isEmpty {
                            offlineGroupsHeader
                        }

                        ForEach(Array(list.enumerated()), id: \.offset) { index, track in
                            let isCurrent = player.currentTrack?.fullId == track.fullId
                            let isSaved = vkClient.downloadedIds.contains(track.fullId)
                            let isDownloading = vkClient.downloadingIds.contains(track.fullId)
                            let isAdded = vkClient.addedIds.contains(track.fullId)

                            TrackRowView(
                                track: track,
                                palette: palette,
                                isCurrent: isCurrent,
                                isPlaying: isCurrent && player.isPlaying,
                                isSaved: isSaved,
                                isDownloading: isDownloading,
                                isAdded: isAdded,
                                showAddAction: showAdd,
                                onTap: {
                                    player.playFromList(list, index: index)
                                },
                                onPlayNext: {
                                    player.playNext(track)
                                },
                                onAddToQueue: {
                                    player.addToQueue(track)
                                },
                                onAddToMyMusic: {
                                    Task { await vkClient.addAudio(track: track) }
                                },
                                onDownload: {
                                    Task { await vkClient.downloadTrack(track) }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 2)
                    .padding(.bottom, hasActiveTrack ? 86 : 16)
                }
            }
        }
    }

    private var offlineGroupsHeader: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("ПЛЕЙЛИСТЫ И АЛЬБОМЫ НА ДИСКЕ")
                .font(.system(size: 10.5, weight: .bold))
                .foregroundColor(palette.textMuted)
                .padding(.top, 2)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(vkClient.offlinePlaylistGroups.enumerated()), id: \.element.id) { idx, group in
                        Button {
                            activeOfflineGroup = group
                        } label: {
                            VStack(alignment: .leading, spacing: 5) {
                                PlaylistCoverView(
                                    playlist: group.playlist,
                                    fallbackIndex: idx,
                                    size: 92,
                                    radius: 10,
                                    palette: palette
                                )
                                Text(group.playlist.title)
                                    .font(.system(size: 11.5, weight: .bold))
                                    .foregroundColor(palette.textPrimary)
                                    .lineLimit(1)
                                Text("\(group.tracks.count) треков")
                                    .font(.system(size: 10.5))
                                    .foregroundColor(palette.textSecondary)
                            }
                            .frame(width: 96, alignment: .leading)
                            .padding(6)
                            .background(palette.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(palette.border, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }

            Text("ВСЕ СКАЧАННЫЕ ТРЕКИ")
                .font(.system(size: 10.5, weight: .bold))
                .foregroundColor(palette.textMuted)
                .padding(.top, 4)
        }
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private func contextualListBar(list: [VKTrack]) -> some View {
        HStack(spacing: 7) {
            if vkClient.currentSection == .downloaded, let group = activeOfflineGroup {
                Button {
                    activeOfflineGroup = nil
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 10.5, weight: .bold))
                        Text(group.playlist.title)
                            .font(.system(size: 11.5, weight: .semibold))
                            .lineLimit(1)
                    }
                    .foregroundColor(palette.accentText)
                    .padding(.horizontal, 9)
                    .frame(height: 26)
                    .background(palette.accentSoft)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            } else if isPlaylistSection {
                Button {
                    browsingPlaylists = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 10.5, weight: .bold))
                        Text("Плейлисты")
                            .font(.system(size: 11.5, weight: .semibold))
                    }
                    .foregroundColor(palette.accentText)
                    .padding(.horizontal, 9)
                    .frame(height: 26)
                    .background(palette.accentSoft)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            Button {
                player.playFromList(list, index: 0)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 10))
                    Text("Слушать")
                        .font(.system(size: 11.5, weight: .semibold))
                }
                .foregroundColor(palette.pillText)
                .padding(.horizontal, 10)
                .frame(height: 26)
                .background(palette.pillBg)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            Button {
                if !player.shuffle { player.toggleShuffle() }
                let idx = Int.random(in: 0..<list.count)
                player.playFromList(list, index: idx)
            } label: {
                Image(systemName: "shuffle")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(player.shuffle ? palette.accentText : palette.textSecondary)
                    .frame(width: 28, height: 26)
                    .background(player.shuffle ? palette.accentSoft : palette.surface)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(palette.border, lineWidth: 1))
            }
            .buttonStyle(.plain)

            Spacer()

            if vkClient.currentSection == .recentlyPlayed && !vkClient.tracks.isEmpty {
                Button {
                    vkClient.clearRecentTracks()
                } label: {
                    Text("Очистить")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.red)
                        .padding(.horizontal, 9)
                        .frame(height: 26)
                        .background(Color.red.opacity(0.12))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            if vkClient.currentSection != .downloaded {
                Button {
                    Task {
                        if case .playlist(let pl) = vkClient.currentSection {
                            await vkClient.downloadPlaylist(pl)
                        } else {
                            await vkClient.downloadAll(list)
                        }
                    }
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: vkClient.batchDownloading ? "ellipsis" : "arrow.down.circle")
                            .font(.system(size: 11, weight: .semibold))
                        Text(vkClient.batchDownloading ? "Качаю..." : "Скачать")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(palette.textSecondary)
                    .padding(.horizontal, 9)
                    .frame(height: 26)
                    .background(palette.surface)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(palette.border, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .disabled(vkClient.batchDownloading)
            }
        }
        .padding(.bottom, 6)
    }

    private var emptyMessage: String {
        if vkClient.currentSection == .recentlyPlayed {
            return "История прослушивания пуста"
        }
        return vkClient.hasSavedSession ? "Ничего не найдено" : "Подключите аккаунт VK"
    }
}

// MARK: - Isolated Floating Mini-Player (Zero Tracklist Re-renders on Time Tick)

private struct MiniPlayerBar: View {
    @ObservedObject var player: AudioPlayerManager
    let palette: ThemePalette
    let onTapBar: () -> Void
    let onTapQueue: () -> Void

    var body: some View {
        if let track = player.currentTrack {
            let elapsedText = "\(formatTime(player.currentTime)) / \(formatTime(player.duration))"

            VStack(spacing: 0) {
                GeometryReader { geo in
                    let progress = player.duration > 0 ? min(1, max(0, player.currentTime / player.duration)) : 0
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(palette.surfaceMuted)
                        Rectangle()
                            .fill(palette.accent)
                            .frame(width: geo.size.width * progress)
                    }
                }
                .frame(height: 2.5)

                HStack(spacing: 9) {
                    TrackCoverView(track: track, size: 38, radius: 8, palette: palette)

                    VStack(alignment: .leading, spacing: 1.5) {
                        Text(track.title)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(palette.textPrimary)
                            .lineLimit(1)

                        HStack(spacing: 4) {
                            if player.isBuffering {
                                Text("BUF")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(palette.accentText)
                                    .padding(.horizontal, 4)
                                    .background(palette.accentSoft)
                                    .cornerRadius(4)
                            }
                            Text(player.isBuffering ? track.artist : "\(track.artist) · \(elapsedText)")
                                .font(.system(size: 11))
                                .foregroundColor(palette.textSecondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer(minLength: 4)

                    HStack(spacing: 5) {
                        Button(action: onTapQueue) {
                            Image(systemName: "list.bullet")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(palette.textSecondary)
                                .frame(width: 27, height: 27)
                                .background(palette.surfaceMuted)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(palette.border, lineWidth: 1))
                        }
                        .buttonStyle(.plain)

                        Button {
                            player.previousTrack()
                        } label: {
                            Image(systemName: "backward.end.fill")
                                .font(.system(size: 11))
                                .foregroundColor(palette.textPrimary)
                                .frame(width: 27, height: 27)
                                .background(palette.surfaceMuted)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(palette.border, lineWidth: 1))
                        }
                        .buttonStyle(.plain)

                        Button {
                            player.togglePlayPause()
                        } label: {
                            Group {
                                if player.isBuffering {
                                    ProgressView()
                                        .scaleEffect(0.6)
                                        .tint(palette.pillText)
                                } else {
                                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(palette.pillText)
                                }
                            }
                            .frame(width: 32, height: 32)
                            .background(palette.pillBg)
                            .clipShape(Circle())
                        }
                        .buttonStyle(.plain)

                        Button {
                            player.nextTrack(manual: true)
                        } label: {
                            Image(systemName: "forward.end.fill")
                                .font(.system(size: 11))
                                .foregroundColor(palette.textPrimary)
                                .frame(width: 27, height: 27)
                                .background(palette.surfaceMuted)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(palette.border, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
            }
            .background(palette.miniBg)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(palette.border, lineWidth: 1)
            )
            .shadow(
                color: Color.black.opacity(palette.isDark ? 0.45 : 0.14),
                radius: 16,
                x: 0,
                y: 8
            )
            .contentShape(Rectangle())
            .onTapGesture(perform: onTapBar)
        }
    }

    private func formatTime(_ secs: Double) -> String {
        let total = max(0, Int(secs))
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

// MARK: - Track Row (Real Album Covers Only, Zero Fake Art)

private struct TrackRowView: View {
    let track: VKTrack
    let palette: ThemePalette
    let isCurrent: Bool
    let isPlaying: Bool
    let isSaved: Bool
    let isDownloading: Bool
    let isAdded: Bool
    let showAddAction: Bool
    let onTap: () -> Void
    let onPlayNext: () -> Void
    let onAddToQueue: () -> Void
    let onAddToMyMusic: () -> Void
    let onDownload: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                TrackCoverView(track: track, size: 40, radius: 8, palette: palette)
                if isCurrent {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.42))
                        .frame(width: 40, height: 40)
                    HStack(spacing: 2) {
                        Capsule().frame(width: 2.5, height: isPlaying ? 8 : 4)
                        Capsule().frame(width: 2.5, height: isPlaying ? 14 : 4)
                        Capsule().frame(width: 2.5, height: isPlaying ? 10 : 4)
                    }
                    .foregroundColor(.white)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(track.title)
                    .font(.system(size: 13.5, weight: isCurrent ? .bold : .semibold))
                    .foregroundColor(isCurrent ? palette.accentText : palette.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    if isSaved {
                        Circle()
                            .fill(palette.savedGreen)
                            .frame(width: 6, height: 6)
                    }
                    Text(track.albumTitle.isEmpty ? track.artist : "\(track.artist) · \(track.albumTitle)")
                        .font(.system(size: 11.5))
                        .foregroundColor(palette.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 4)

            Button(action: onDownload) {
                Group {
                    if isDownloading {
                        ProgressView()
                            .scaleEffect(0.6)
                            .tint(palette.accent)
                    } else if isSaved {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10.5, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "arrow.down")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(palette.textSecondary)
                    }
                }
                .frame(width: 26, height: 26)
                .background(isSaved ? palette.savedGreen : palette.surfaceMuted)
                .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Menu {
                Button(action: onPlayNext) {
                    Label("Играть следующим", systemImage: "text.insert")
                }
                Button(action: onAddToQueue) {
                    Label("Добавить в конец очереди", systemImage: "text.append")
                }
                if showAddAction && !isAdded {
                    Button(action: onAddToMyMusic) {
                        Label("Добавить в Мою музыку", systemImage: "plus")
                    }
                }
                Button(action: onDownload) {
                    Label(isSaved ? "Уже на диске" : "Скачать на устройство", systemImage: isSaved ? "checkmark.circle" : "arrow.down.circle")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(palette.textMuted)
                    .frame(width: 22, height: 26)
            }
            .buttonStyle(.plain)

            Text(track.durationText)
                .font(.system(size: 11, weight: .medium).monospacedDigit())
                .foregroundColor(palette.textMuted)
                .frame(width: 34, alignment: .trailing)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .background(isCurrent ? palette.surfaceActive : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCurrent ? palette.strongBorder : Color.clear, lineWidth: isCurrent ? 1 : 0)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .contextMenu {
            Button(action: onPlayNext) {
                Label("Играть следующим", systemImage: "text.insert")
            }
            Button(action: onAddToQueue) {
                Label("В конец очереди", systemImage: "text.append")
            }
            if showAddAction && !isAdded {
                Button(action: onAddToMyMusic) {
                    Label("В Мою музыку", systemImage: "plus")
                }
            }
            Button(action: onDownload) {
                Label(isSaved ? "Сохранено" : "Скачать", systemImage: "arrow.down.circle")
            }
        }
    }
}

// MARK: - Cached Cover Views

private struct TrackCoverView: View {
    let track: VKTrack
    let size: CGFloat
    let radius: CGFloat
    let palette: ThemePalette

    @State private var loadedImage: UIImage?
    @State private var loadedKey: String = ""

    private var activeImage: UIImage? {
        guard !track.coverUrl.isEmpty else { return nil }
        if let hit = CoverImageCache.shared.cachedImage(for: track.coverUrl) {
            return hit
        }
        return loadedKey == track.coverUrl ? loadedImage : nil
    }

    var body: some View {
        Group {
            if let img = activeImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    palette.surfaceMuted
                    Image(systemName: "music.note")
                        .font(.system(size: size * 0.34, weight: .semibold))
                        .foregroundColor(palette.textMuted)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: radius))
        .overlay(
            RoundedRectangle(cornerRadius: radius)
                .stroke(palette.border, lineWidth: 1)
        )
        .task(id: track.coverUrl) {
            let key = track.coverUrl
            guard !key.isEmpty else {
                loadedKey = ""
                loadedImage = nil
                return
            }
            if let mem = CoverImageCache.shared.cachedImage(for: key) {
                loadedKey = key
                loadedImage = mem
                return
            }
            let fetched = await CoverImageCache.shared.image(for: key)
            loadedKey = key
            loadedImage = fetched
        }
    }
}

private struct PlaylistCoverView: View {
    let playlist: VKPlaylist
    let fallbackIndex: Int
    let size: CGFloat
    let radius: CGFloat
    let palette: ThemePalette

    @State private var loadedImage: UIImage?
    @State private var loadedKey: String = ""

    private var fallbackAssetName: String {
        let names = ["Art1Eve", "Art2Sky", "Art4Dream", "Art3City"]
        return names[abs(fallbackIndex) % names.count]
    }

    private var activeImage: UIImage? {
        guard !playlist.coverUrl.isEmpty else { return nil }
        if let hit = CoverImageCache.shared.cachedImage(for: playlist.coverUrl) {
            return hit
        }
        return loadedKey == playlist.coverUrl ? loadedImage : nil
    }

    var body: some View {
        Group {
            if let img = activeImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(fallbackAssetName)
                    .resizable()
                    .scaledToFill()
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: radius))
        .overlay(
            RoundedRectangle(cornerRadius: radius)
                .stroke(palette.border, lineWidth: 1)
        )
        .task(id: playlist.coverUrl) {
            let key = playlist.coverUrl
            guard !key.isEmpty else {
                loadedKey = ""
                loadedImage = nil
                return
            }
            if let mem = CoverImageCache.shared.cachedImage(for: key) {
                loadedKey = key
                loadedImage = mem
                return
            }
            let fetched = await CoverImageCache.shared.image(for: key)
            loadedKey = key
            loadedImage = fetched
        }
    }
}

// MARK: - Full Player + Queue + Equalizer & AirPods 3 Sheet

private struct NowPlayingSheet: View {
    @EnvironmentObject var vkClient: VKAPIClient
    @EnvironmentObject var player: AudioPlayerManager
    @Environment(\.dismiss) private var dismiss

    @Binding var selectedTab: NowPlayingTab
    let palette: ThemePalette
    let onToggleTheme: () -> Void

    @State private var isSeeking: Bool = false
    @State private var dragSeekSeconds: Double = 0
    @State private var isDraggingVolume: Bool = false
    @State private var dragVolume: Float = 1.0

    var body: some View {
        ZStack {
            AppBackdropView(palette: palette)

            VStack(spacing: 0) {
                topBar
                switch selectedTab {
                case .player:
                    playerBody
                case .queue:
                    queueBody
                case .equalizer:
                    equalizerBody
                }
            }
        }
        .preferredColorScheme(palette.kind.colorScheme)
    }

    private var topBar: some View {
        HStack(spacing: 6) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(palette.textPrimary)
                    .frame(width: 30, height: 30)
                    .background(palette.surface)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(palette.border, lineWidth: 1))
            }
            .buttonStyle(.plain)

            Spacer(minLength: 4)

            HStack(spacing: 2) {
                tabButton("Плеер", tab: .player)
                tabButton("Очередь", tab: .queue)
                tabButton("🎧 EQ", tab: .equalizer)
            }
            .padding(3)
            .background(palette.surface)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(palette.border, lineWidth: 1))

            Spacer(minLength: 4)

            Button(action: onToggleTheme) {
                Text("✦")
                    .font(.system(size: 12.5, weight: .bold))
                    .foregroundColor(palette.textPrimary)
                    .frame(width: 30, height: 30)
                    .background(palette.surface)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(palette.border, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private func tabButton(_ title: String, tab: NowPlayingTab) -> some View {
        let active = selectedTab == tab
        return Button {
            withAnimation(.easeInOut(duration: 0.16)) {
                selectedTab = tab
            }
        } label: {
            Text(title)
                .font(.system(size: 11.5, weight: .bold))
                .foregroundColor(active ? palette.pillText : palette.textSecondary)
                .padding(.horizontal, 11)
                .frame(height: 25)
                .background(active ? palette.pillBg : Color.clear)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Player Tab

    private var playerBody: some View {
        Group {
            if let track = player.currentTrack {
                ScrollView {
                    let effectiveVol = isDraggingVolume ? dragVolume : player.volume
                    let displayedPct = player.isMuted ? 0 : Int((effectiveVol * 100).rounded())
                    let fmtBadge = LocalStorage.findDownloadedFile(for: track)?.pathExtension.uppercased()
                        ?? (track.url.contains(".m3u8") ? "HLS" : "MP3")

                    VStack(spacing: 14) {
                        ZStack(alignment: .bottomTrailing) {
                            TrackCoverView(track: track, size: 214, radius: 16, palette: palette)
                                .shadow(color: Color.black.opacity(palette.isDark ? 0.5 : 0.22), radius: 22, x: 0, y: 12)

                            Text("\(fmtBadge) · \(player.crossfadeSecs)с")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(palette.pillText)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(palette.pillBg.opacity(0.9))
                                .clipShape(Capsule())
                                .padding(8)
                        }
                        .padding(.top, 4)

                        VStack(spacing: 4) {
                            Text(track.title)
                                .font(.system(size: 18, weight: .heavy))
                                .foregroundColor(palette.textPrimary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                            Text(track.albumTitle.isEmpty ? track.artist : "\(track.artist) — \(track.albumTitle)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(palette.textSecondary)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 16)

                        HStack(spacing: 8) {
                            Button {
                                selectedTab = .equalizer
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: player.isAirPodsConnected ? "airpods.gen3" : "waveform")
                                        .font(.system(size: 11, weight: .semibold))
                                    Text(player.eqEnabled ? "EQ: \(player.eqPreset.title)" : "EQ выкл")
                                        .font(.system(size: 11.5, weight: .semibold))
                                        .lineLimit(1)
                                }
                                .foregroundColor(player.eqEnabled ? palette.accentText : palette.textSecondary)
                                .padding(.horizontal, 10)
                                .frame(height: 28)
                                .background(player.eqEnabled ? palette.accentSoft : palette.surface)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(palette.border, lineWidth: 1))
                            }
                            .buttonStyle(.plain)

                            Button {
                                selectedTab = .queue
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "list.bullet")
                                        .font(.system(size: 11, weight: .semibold))
                                    Text("\(player.queue.count)")
                                        .font(.system(size: 11.5, weight: .bold).monospacedDigit())
                                }
                                .foregroundColor(palette.textPrimary)
                                .padding(.horizontal, 10)
                                .frame(height: 28)
                                .background(palette.surface)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(palette.border, lineWidth: 1))
                            }
                            .buttonStyle(.plain)

                            let isAdded = vkClient.addedIds.contains(track.fullId)
                            Button {
                                Task { await vkClient.addAudio(track: track) }
                            } label: {
                                Image(systemName: isAdded ? "checkmark" : "plus")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(isAdded ? .white : palette.textPrimary)
                                    .frame(width: 28, height: 28)
                                    .background(isAdded ? palette.savedGreen : palette.surface)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(palette.border, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                            .disabled(isAdded)

                            let isSaved = vkClient.downloadedIds.contains(track.fullId)
                            let isDownloading = vkClient.downloadingIds.contains(track.fullId)
                            Button {
                                Task { await vkClient.downloadTrack(track) }
                            } label: {
                                Group {
                                    if isDownloading {
                                        ProgressView().scaleEffect(0.65).tint(palette.accent)
                                    } else if isSaved {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 11.5, weight: .bold))
                                            .foregroundColor(.white)
                                    } else {
                                        Image(systemName: "arrow.down")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(palette.textPrimary)
                                    }
                                }
                                .frame(width: 28, height: 28)
                                .background(isSaved ? palette.savedGreen : palette.surface)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(palette.border, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }

                        // Scrubber
                        VStack(spacing: 4) {
                            let maxDur = max(1.0, player.duration)
                            let shownPos = isSeeking ? dragSeekSeconds : min(player.currentTime, maxDur)

                            Slider(
                                value: Binding(
                                    get: { shownPos },
                                    set: { newVal in
                                        isSeeking = true
                                        dragSeekSeconds = newVal
                                    }
                                ),
                                in: 0...maxDur,
                                onEditingChanged: { editing in
                                    if !editing {
                                        player.seek(to: dragSeekSeconds)
                                        isSeeking = false
                                    }
                                }
                            )
                            .tint(palette.accent)

                            HStack {
                                Text(formatTime(shownPos))
                                Spacer()
                                Text("-\(formatTime(max(0, maxDur - shownPos)))")
                            }
                            .font(.system(size: 11, weight: .medium).monospacedDigit())
                            .foregroundColor(palette.textMuted)
                        }
                        .padding(.horizontal, 16)

                        // Transport
                        HStack(spacing: 14) {
                            Button {
                                player.toggleShuffle()
                            } label: {
                                Image(systemName: "shuffle")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(player.shuffle ? palette.accentText : palette.textSecondary)
                                    .frame(width: 36, height: 36)
                                    .background(player.shuffle ? palette.accentSoft : palette.surface)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(player.shuffle ? palette.strongBorder : palette.border, lineWidth: 1))
                            }
                            .buttonStyle(.plain)

                            Button {
                                player.previousTrack()
                            } label: {
                                Image(systemName: "backward.end.fill")
                                    .font(.system(size: 17))
                                    .foregroundColor(palette.textPrimary)
                                    .frame(width: 44, height: 44)
                                    .background(palette.surface)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(palette.border, lineWidth: 1))
                            }
                            .buttonStyle(.plain)

                            Button {
                                player.togglePlayPause()
                            } label: {
                                Group {
                                    if player.isBuffering {
                                        ProgressView().tint(palette.pillText)
                                    } else {
                                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                                            .font(.system(size: 22))
                                            .foregroundColor(palette.pillText)
                                    }
                                }
                                .frame(width: 60, height: 60)
                                .background(palette.pillBg)
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.24), radius: 12, y: 6)
                            }
                            .buttonStyle(.plain)

                            Button {
                                player.nextTrack(manual: true)
                            } label: {
                                Image(systemName: "forward.end.fill")
                                    .font(.system(size: 17))
                                    .foregroundColor(palette.textPrimary)
                                    .frame(width: 44, height: 44)
                                    .background(palette.surface)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(palette.border, lineWidth: 1))
                            }
                            .buttonStyle(.plain)

                            Button {
                                player.cycleRepeatMode()
                            } label: {
                                Image(systemName: player.repeatMode == .one ? "repeat.1" : "repeat")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(player.repeatMode != .none ? palette.accentText : palette.textSecondary)
                                    .frame(width: 36, height: 36)
                                    .background(player.repeatMode != .none ? palette.accentSoft : palette.surface)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(player.repeatMode != .none ? palette.strongBorder : palette.border, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }

                        // Volume + Crossfade Card
                        VStack(spacing: 10) {
                            HStack {
                                Button {
                                    player.toggleMute()
                                } label: {
                                    Image(systemName: player.isMuted || effectiveVol <= 0.0001 ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                        .font(.system(size: 12.5))
                                        .foregroundColor(palette.textSecondary)
                                }
                                .buttonStyle(.plain)

                                Text("Громкость (кубическая)")
                                    .font(.system(size: 11.5, weight: .semibold))
                                    .foregroundColor(palette.textSecondary)
                                Spacer()
                                Text("\(displayedPct)%")
                                    .font(.system(size: 12, weight: .bold).monospacedDigit())
                                    .foregroundColor(palette.textPrimary)
                            }

                            HStack(spacing: 8) {
                                Button {
                                    player.adjustVolume(by: -0.01)
                                } label: {
                                    Text("−1%")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(palette.textPrimary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 5)
                                        .background(palette.surfaceMuted)
                                        .clipShape(RoundedRectangle(cornerRadius: 7))
                                }
                                .buttonStyle(.plain)

                                Slider(
                                    value: Binding(
                                        get: { Double(effectiveVol) },
                                        set: { v in
                                            isDraggingVolume = true
                                            dragVolume = Float(v)
                                            player.setVolume(Float(v))
                                        }
                                    ),
                                    in: 0...1,
                                    onEditingChanged: { editing in
                                        if !editing { isDraggingVolume = false }
                                    }
                                )
                                .tint(palette.accent)

                                Button {
                                    player.adjustVolume(by: 0.01)
                                } label: {
                                    Text("+1%")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(palette.textPrimary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 5)
                                        .background(palette.surfaceMuted)
                                        .clipShape(RoundedRectangle(cornerRadius: 7))
                                }
                                .buttonStyle(.plain)
                            }

                            HStack {
                                Text("Кроссфейд")
                                    .font(.system(size: 11.5, weight: .semibold))
                                    .foregroundColor(palette.textSecondary)
                                Spacer()
                                HStack(spacing: 4) {
                                    ForEach([0, 1, 2, 3, 5], id: \.self) { secs in
                                        let active = player.crossfadeSecs == secs
                                        Button {
                                            player.setCrossfadeSecs(secs)
                                        } label: {
                                            Text("\(secs)с")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(active ? palette.pillText : palette.textPrimary)
                                                .padding(.horizontal, 9)
                                                .padding(.vertical, 5)
                                                .background(active ? palette.pillBg : palette.surfaceMuted)
                                                .clipShape(RoundedRectangle(cornerRadius: 7))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        .padding(12)
                        .background(palette.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(palette.border, lineWidth: 1))
                        .padding(.horizontal, 14)
                        .padding(.bottom, 18)
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "waveform.circle")
                        .font(.system(size: 56))
                        .foregroundColor(palette.textMuted)
                    Text("Выбери трек из списка")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(palette.textPrimary)
                    Button {
                        selectedTab = .equalizer
                    } label: {
                        Text("Настроить EQ и AirPods 3")
                            .font(.system(size: 12.5, weight: .bold))
                            .foregroundColor(palette.pillText)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 9)
                            .background(palette.pillBg)
                            .clipShape(Capsule())
                    }
                    Spacer()
                }
            }
        }
    }

    // MARK: - Live Queue Tab

    private var queueBody: some View {
        Group {
            if player.queue.isEmpty {
                VStack(spacing: 10) {
                    Spacer()
                    Image(systemName: "list.bullet")
                        .font(.system(size: 42))
                        .foregroundColor(palette.textMuted)
                    Text("Очередь воспроизведения пуста")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(palette.textPrimary)
                    Text("Нажми на любой трек или выбери «Играть следующим» в меню ⋯")
                        .font(.system(size: 12))
                        .foregroundColor(palette.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        HStack {
                            let curHuman = (player.currentIndex ?? 0) + 1
                            Text("ОЧЕРЕДЬ · \(curHuman) / \(player.queue.count)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(palette.textMuted)
                            Spacer()
                            if player.shuffle {
                                Text("⇄ Случайный порядок")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(palette.accentText)
                            }
                        }
                        .padding(.horizontal, 4)
                        .padding(.bottom, 4)

                        ForEach(Array(player.queue.enumerated()), id: \.offset) { idx, tr in
                            let isCur = idx == player.currentIndex
                            HStack(spacing: 10) {
                                ZStack {
                                    TrackCoverView(track: tr, size: 38, radius: 7, palette: palette)
                                    if isCur {
                                        RoundedRectangle(cornerRadius: 7)
                                            .fill(Color.black.opacity(0.45))
                                            .frame(width: 38, height: 38)
                                        Image(systemName: player.isPlaying ? "waveform" : "pause.fill")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }

                                VStack(alignment: .leading, spacing: 1.5) {
                                    Text(tr.title)
                                        .font(.system(size: 13, weight: isCur ? .bold : .semibold))
                                        .foregroundColor(isCur ? palette.accentText : palette.textPrimary)
                                        .lineLimit(1)
                                    Text(tr.artist)
                                        .font(.system(size: 11.5))
                                        .foregroundColor(palette.textSecondary)
                                        .lineLimit(1)
                                }

                                Spacer()

                                if !isCur {
                                    Button {
                                        player.removeFromQueue(at: idx)
                                    } label: {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(palette.textMuted)
                                            .frame(width: 26, height: 26)
                                            .background(palette.surfaceMuted)
                                            .clipShape(Circle())
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    Text(tr.durationText)
                                        .font(.system(size: 11).monospacedDigit())
                                        .foregroundColor(palette.textMuted)
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(isCur ? palette.surfaceActive : palette.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 11))
                            .overlay(
                                RoundedRectangle(cornerRadius: 11)
                                    .stroke(isCur ? palette.strongBorder : palette.border, lineWidth: 1)
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                player.jumpToQueueIndex(idx)
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 22)
                }
            }
        }
    }

    // MARK: - Equalizer & AirPods 3 Tab

    private var equalizerBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: player.isAirPodsConnected ? "airpods.gen3" : "headphones")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(player.isAirPodsConnected ? palette.savedGreen : palette.accent)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(player.audioRouteName)
                                    .font(.system(size: 13.5, weight: .bold))
                                    .foregroundColor(palette.textPrimary)
                                    .lineLimit(1)
                                Text(player.isAirPodsConnected ? "Беспроводные наушники активны" : "Подключи AirPods 3 для автопрофиля")
                                    .font(.system(size: 11))
                                    .foregroundColor(palette.textSecondary)
                            }
                        }

                        Spacer()

                        Toggle("", isOn: Binding(
                            get: { player.eqEnabled },
                            set: { player.setEQEnabled($0) }
                        ))
                        .labelsHidden()
                        .tint(palette.savedGreen)
                    }

                    Divider().opacity(0.3)

                    Toggle(isOn: Binding(
                        get: { player.airpods3Mode },
                        set: { player.setAirPods3Mode($0) }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Профиль AirPods 3 (Ориг)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(palette.textPrimary)
                            Text("+3.2 дБ @ 55 Гц саб-бас · −1.5 дБ @ 230 Гц чище середина · анти-клип")
                                .font(.system(size: 10.5))
                                .foregroundColor(palette.textSecondary)
                        }
                    }
                    .tint(palette.savedGreen)

                    VStack(spacing: 4) {
                        HStack {
                            Text("Стерео-сцена AirPods 3")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(palette.textSecondary)
                            Spacer()
                            Text("\(Int((player.spatialStage * 100).rounded()))%")
                                .font(.system(size: 12, weight: .bold).monospacedDigit())
                                .foregroundColor(palette.textPrimary)
                        }
                        Slider(
                            value: Binding(
                                get: { Double(player.spatialStage) },
                                set: { player.setSpatialStage(Float($0)) }
                            ),
                            in: 0...1,
                            step: 0.05
                        )
                        .tint(palette.accent)
                    }
                }
                .padding(12)
                .background(palette.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(palette.border, lineWidth: 1))

                VStack(alignment: .leading, spacing: 8) {
                    Text("ПРЕСЕТЫ · АНТИПОП / ХАЙПЕРПОП / AIRPODS 3")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(palette.textMuted)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(EQPreset.selectablePresets) { preset in
                                let active = player.eqPreset == preset && player.eqEnabled
                                Button {
                                    player.applyEQPreset(preset)
                                } label: {
                                    Text(preset.title)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(active ? palette.pillText : palette.textPrimary)
                                        .padding(.horizontal, 11)
                                        .padding(.vertical, 7)
                                        .background(active ? palette.pillBg : palette.surface)
                                        .clipShape(Capsule())
                                        .overlay(Capsule().stroke(active ? Color.clear : palette.border, lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Text(player.eqPreset.subtitle)
                        .font(.system(size: 11.5))
                        .foregroundColor(palette.textSecondary)
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("КРИВАЯ ЭКВАЛАЙЗЕРА (6 ПОЛОС)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(palette.textMuted)
                        Spacer()
                        Button("Сброс") {
                            player.resetEQ()
                        }
                        .font(.system(size: 11.5, weight: .bold))
                        .foregroundColor(palette.accentText)
                    }

                    EQCurveCanvas(
                        gains: player.eqEnabled ? player.eqBands : [0, 0, 0, 0, 0, 0],
                        airpods3Compensation: player.eqEnabled && player.airpods3Mode,
                        palette: palette
                    )
                    .frame(height: 68)
                    .background(palette.surfaceMuted.opacity(0.65))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(palette.border, lineWidth: 1))

                    ForEach(EQBandInfo.sixBands) { band in
                        let gain = player.eqBands[band.index]
                        VStack(spacing: 3) {
                            HStack {
                                Text(band.shortLabel)
                                    .font(.system(size: 12, weight: .bold).monospacedDigit())
                                    .foregroundColor(palette.textPrimary)
                                    .frame(width: 58, alignment: .leading)
                                Text(band.roleLabel)
                                    .font(.system(size: 11))
                                    .foregroundColor(palette.textSecondary)
                                Spacer()
                                Text(String(format: "%+.1f дБ", gain))
                                    .font(.system(size: 11.5, weight: .bold).monospacedDigit())
                                    .foregroundColor(abs(gain) > 0.1 ? palette.accentText : palette.textMuted)
                            }
                            Slider(
                                value: Binding(
                                    get: { Double(player.eqBands[band.index]) },
                                    set: { player.setEQBandGain(index: band.index, gain: Float($0)) }
                                ),
                                in: -12...12,
                                step: 0.5
                            )
                            .tint(palette.accent)
                        }
                    }

                    Divider().opacity(0.3)

                    VStack(spacing: 3) {
                        HStack {
                            Text("Preamp")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(palette.textPrimary)
                            Text("общий запас громкости")
                                .font(.system(size: 11))
                                .foregroundColor(palette.textSecondary)
                            Spacer()
                            Text(String(format: "%+.1f дБ", player.preampDB))
                                .font(.system(size: 11.5, weight: .bold).monospacedDigit())
                                .foregroundColor(palette.textMuted)
                        }
                        Slider(
                            value: Binding(
                                get: { Double(player.preampDB) },
                                set: { player.setPreamp(Float($0)) }
                            ),
                            in: -12...6,
                            step: 0.5
                        )
                        .tint(palette.accent)
                    }
                }
                .padding(12)
                .background(palette.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(palette.border, lineWidth: 1))
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 22)
        }
    }

    private func formatTime(_ secs: Double) -> String {
        let total = max(0, Int(secs))
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

private struct EQCurveCanvas: View {
    let gains: [Float]
    let airpods3Compensation: Bool
    let palette: ThemePalette

    var body: some View {
        Canvas { ctx, size in
            let w = size.width
            let h = size.height
            let midY = h * 0.5

            var zeroLine = Path()
            zeroLine.move(to: CGPoint(x: 0, y: midY))
            zeroLine.addLine(to: CGPoint(x: w, y: midY))
            ctx.stroke(zeroLine, with: .color(palette.border), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))

            let points: [CGPoint] = gains.enumerated().map { idx, g in
                let x = w * (0.07 + 0.86 * (CGFloat(idx) / CGFloat(max(1, gains.count - 1))))
                let compBonus: Float = airpods3Compensation ? (idx == 0 ? 2.4 : (idx == 1 ? -0.6 : 0)) : 0
                let effective = max(-12, min(12, g + compBonus))
                let norm = CGFloat((effective + 12) / 24)
                let y = h - (norm * (h - 14) + 7)
                return CGPoint(x: x, y: y)
            }

            guard points.count >= 2 else { return }

            var curve = Path()
            curve.move(to: points[0])
            for i in 1..<points.count {
                let prev = points[i - 1]
                let cur = points[i]
                let midX = (prev.x + cur.x) * 0.5
                curve.addCurve(
                    to: cur,
                    control1: CGPoint(x: midX, y: prev.y),
                    control2: CGPoint(x: midX, y: cur.y)
                )
            }

            var fillPath = curve
            fillPath.addLine(to: CGPoint(x: points.last!.x, y: h))
            fillPath.addLine(to: CGPoint(x: points.first!.x, y: h))
            fillPath.closeSubpath()

            ctx.fill(
                fillPath,
                with: .linearGradient(
                    Gradient(colors: [palette.accent.opacity(0.28), palette.accent.opacity(0.02)]),
                    startPoint: CGPoint(x: 0, y: 0),
                    endPoint: CGPoint(x: 0, y: h)
                )
            )
            ctx.stroke(curve, with: .color(palette.accent), lineWidth: 2.2)

            for pt in points {
                let dot = Path(ellipseIn: CGRect(x: pt.x - 3, y: pt.y - 3, width: 6, height: 6))
                ctx.fill(dot, with: .color(palette.accent))
            }
        }
    }
}
