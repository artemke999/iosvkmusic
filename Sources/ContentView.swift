import SwiftUI

enum SqworeThemeMode: String, CaseIterable {
    case evePaper = "eve"
    case night17 = "17"

    var next: SqworeThemeMode {
        self == .evePaper ? .night17 : .evePaper
    }

    var badgeTitle: String {
        self == .evePaper ? "✦ EVE" : "✦ 17"
    }

    var deckTag: String {
        self == .evePaper ? "EVE // AUDIO" : "17 // AUDIO"
    }

    var colorScheme: ColorScheme {
        self == .evePaper ? .light : .dark
    }
}

struct ThemeColors {
    let mode: SqworeThemeMode
    let canvas: Color
    let paper: Color
    let skyPanel: Color
    let activePlate: Color
    let ink: Color
    let shadow: Color
    let textPrimary: Color
    let textSecondary: Color
    let textMuted: Color
    let accentSky: Color
    let accentRose: Color
    let accentButter: Color
    let accentMint: Color
    let gridLine: Color

    init(_ mode: SqworeThemeMode) {
        self.mode = mode
        switch mode {
        case .evePaper:
            self.canvas = Color(red: 245 / 255, green: 244 / 255, blue: 238 / 255)
            self.paper = Color(red: 251 / 255, green: 251 / 255, blue: 248 / 255)
            self.skyPanel = Color(red: 220 / 255, green: 235 / 255, blue: 247 / 255)
            self.activePlate = Color(red: 214 / 255, green: 233 / 255, blue: 248 / 255)
            self.ink = Color(red: 17 / 255, green: 17 / 255, blue: 20 / 255)
            self.shadow = Color(red: 17 / 255, green: 17 / 255, blue: 20 / 255)
            self.textPrimary = Color(red: 17 / 255, green: 17 / 255, blue: 20 / 255)
            self.textSecondary = Color(red: 74 / 255, green: 77 / 255, blue: 87 / 255)
            self.textMuted = Color(red: 123 / 255, green: 127 / 255, blue: 140 / 255)
            self.accentSky = Color(red: 111 / 255, green: 166 / 255, blue: 209 / 255)
            self.accentRose = Color(red: 242 / 255, green: 139 / 255, blue: 157 / 255)
            self.accentButter = Color(red: 246 / 255, green: 223 / 255, blue: 120 / 255)
            self.accentMint = Color(red: 123 / 255, green: 207 / 255, blue: 164 / 255)
            self.gridLine = Color(red: 17 / 255, green: 17 / 255, blue: 20 / 255).opacity(0.055)
        case .night17:
            self.canvas = Color(red: 13 / 255, green: 10 / 255, blue: 20 / 255)
            self.paper = Color(red: 23 / 255, green: 18 / 255, blue: 36 / 255)
            self.skyPanel = Color(red: 30 / 255, green: 25 / 255, blue: 48 / 255)
            self.activePlate = Color(red: 35 / 255, green: 27 / 255, blue: 56 / 255)
            self.ink = Color(red: 216 / 255, green: 212 / 255, blue: 242 / 255)
            self.shadow = Color(red: 0 / 255, green: 0 / 255, blue: 0 / 255)
            self.textPrimary = Color(red: 247 / 255, green: 245 / 255, blue: 255 / 255)
            self.textSecondary = Color(red: 171 / 255, green: 164 / 255, blue: 196 / 255)
            self.textMuted = Color(red: 110 / 255, green: 103 / 255, blue: 138 / 255)
            self.accentSky = Color(red: 108 / 255, green: 229 / 255, blue: 255 / 255)
            self.accentRose = Color(red: 255 / 255, green: 148 / 255, blue: 224 / 255)
            self.accentButter = Color(red: 255 / 255, green: 238 / 255, blue: 136 / 255)
            self.accentMint = Color(red: 92 / 255, green: 230 / 255, blue: 160 / 255)
            self.gridLine = Color(red: 216 / 255, green: 212 / 255, blue: 242 / 255).opacity(0.055)
        }
    }

    var buttonTextOnAccent: Color {
        Color(red: 17 / 255, green: 17 / 255, blue: 20 / 255)
    }

    var primaryKeyFill: Color {
        mode == .evePaper ? ink : textPrimary
    }

    var primaryKeyText: Color {
        mode == .evePaper ? paper : Color(red: 13 / 255, green: 10 / 255, blue: 20 / 255)
    }
}

private struct InkFrameModifier: ViewModifier {
    let theme: ThemeColors
    let fill: Color
    let radius: CGFloat
    let shadowOffset: CGFloat

    func body(content: Content) -> some View {
        content
            .background(fill)
            .cornerRadius(radius)
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(theme.ink, lineWidth: 1.5)
            )
            .background(
                RoundedRectangle(cornerRadius: radius)
                    .fill(theme.shadow)
                    .offset(x: shadowOffset, y: shadowOffset)
            )
    }
}

private extension View {
    func inkBox(_ theme: ThemeColors, fill: Color? = nil, radius: CGFloat = 3, shadow: CGFloat = 2) -> some View {
        modifier(InkFrameModifier(theme: theme, fill: fill ?? theme.paper, radius: radius, shadowOffset: shadow))
    }
}

private struct SketchbookGridBackground: View {
    let theme: ThemeColors

    var body: some View {
        ZStack {
            theme.canvas
            Canvas { ctx, size in
                let step: CGFloat = 24
                var path = Path()
                var x: CGFloat = 0
                while x <= size.width {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                    x += step
                }
                var y: CGFloat = 0
                while y <= size.height {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                    y += step
                }
                ctx.stroke(path, with: .color(theme.gridLine), lineWidth: 0.75)
            }
        }
        .ignoresSafeArea()
    }
}

struct ContentView: View {
    @EnvironmentObject var vkClient: VKAPIClient
    @EnvironmentObject var player: AudioPlayerManager

    @AppStorage("sqwore_theme") private var rawTheme: String = SqworeThemeMode.evePaper.rawValue
    @State private var searchText: String = ""
    @State private var showAuthSheet: Bool = false
    @State private var showNowPlayingSheet: Bool = false
    @State private var showPlaylistsSheet: Bool = false

    private var themeMode: SqworeThemeMode {
        SqworeThemeMode(rawValue: rawTheme) ?? .evePaper
    }

    private var theme: ThemeColors {
        ThemeColors(themeMode)
    }

    private var filteredTracks: [VKTrack] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return vkClient.tracks }
        if case .search(let searchedQ) = vkClient.currentSection,
           q == searchedQ.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
            return vkClient.tracks
        }
        let words = q.split(whereSeparator: { $0.isWhitespace }).map(String.init)
        return vkClient.tracks.filter { track in
            let titleLow = track.title.lowercased()
            let artistLow = track.artist.lowercased()
            let albumLow = track.albumTitle.lowercased()
            return words.allSatisfy { w in
                titleLow.contains(w) || artistLow.contains(w) || albumLow.contains(w)
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            SketchbookGridBackground(theme: theme)

            VStack(spacing: 0) {
                headerView
                sectionStrip
                actionBar
                Rectangle()
                    .fill(theme.ink)
                    .frame(height: 1.5)
                trackListView
            }

            if player.currentTrack != nil {
                miniPlayerBar
            }
        }
        .preferredColorScheme(themeMode.colorScheme)
        .sheet(isPresented: $showAuthSheet) {
            VKWebAuthSheet()
        }
        .sheet(isPresented: $showNowPlayingSheet) {
            NowPlayingSheet()
        }
        .sheet(isPresented: $showPlaylistsSheet) {
            PlaylistsSheet(
                playlists: vkClient.playlists,
                theme: theme,
                onSelect: { pl in
                    showPlaylistsSheet = false
                    Task { await vkClient.loadSection(.playlist(pl)) }
                }
            )
        }
    }

    // MARK: - EVE II Blueprint Header

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 7) {
            // Multi-cell blueprint top banner
            HStack(spacing: 0) {
                HStack(spacing: 5) {
                    Text("VK MUSIC")
                        .font(.system(size: 16, weight: .black, design: .monospaced))
                        .foregroundColor(theme.textPrimary)
                    Text("✦")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(theme.accentRose)
                    Text(themeMode.deckTag)
                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        .foregroundColor(theme.textSecondary)
                        .lineLimit(1)
                }
                .padding(.horizontal, 8)
                .frame(height: 30)

                Spacer(minLength: 4)

                Rectangle()
                    .fill(theme.ink)
                    .frame(width: 1.5, height: 30)

                Button {
                    rawTheme = themeMode.next.rawValue
                } label: {
                    Text(themeMode.badgeTitle)
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundColor(theme.buttonTextOnAccent)
                        .padding(.horizontal, 8)
                        .frame(height: 30)
                        .background(theme.accentButter)
                }

                Rectangle()
                    .fill(theme.ink)
                    .frame(width: 1.5, height: 30)

                Button {
                    showAuthSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(vkClient.user != nil ? theme.accentMint : theme.accentRose)
                            .frame(width: 6, height: 6)
                            .overlay(Circle().stroke(theme.ink, lineWidth: 1))
                        Text(vkClient.user?.name ?? "ВОЙТИ")
                            .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                            .foregroundColor(theme.textPrimary)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 8)
                    .frame(height: 30)
                    .background(theme.skyPanel)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .inkBox(theme, fill: theme.paper, radius: 3, shadow: 2)

            // Search / Filter Row
            HStack(spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(theme.textSecondary)

                    TextField("Фильтр / поиск в VK...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .foregroundColor(theme.textPrimary)
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
                            Image(systemName: "xmark")
                                .font(.system(size: 10.5, weight: .black))
                                .foregroundColor(theme.textSecondary)
                                .padding(4)
                        }
                    }
                }
                .padding(.horizontal, 8)
                .frame(height: 32)
                .inkBox(theme, fill: theme.paper, radius: 3, shadow: 2)

                Button {
                    let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !q.isEmpty {
                        Task { await vkClient.loadSection(.search(q)) }
                    } else {
                        Task { await vkClient.loadSection(vkClient.currentSection) }
                    }
                } label: {
                    Image(systemName: searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "arrow.clockwise" : "arrow.right")
                        .font(.system(size: 12.5, weight: .bold))
                        .foregroundColor(theme.buttonTextOnAccent)
                        .frame(width: 34, height: 32)
                        .inkBox(theme, fill: theme.accentSky, radius: 3, shadow: 2)
                }
            }

            // Fishbowl Note Status + Track Counter Stamp
            HStack(spacing: 6) {
                HStack(spacing: 5) {
                    Circle()
                        .fill(
                            player.isBuffering || vkClient.isLoading
                                ? theme.accentButter
                                : (player.isPlaying ? theme.accentMint : theme.textMuted)
                        )
                        .frame(width: 6, height: 6)
                        .overlay(Circle().stroke(theme.ink, lineWidth: 1))
                    Text(vkClient.statusText.uppercased())
                        .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                        .foregroundColor(theme.textSecondary)
                        .lineLimit(1)
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(theme.paper)
                .overlay(Rectangle().stroke(theme.ink, lineWidth: 1))

                Spacer(minLength: 4)

                Text("\(filteredTracks.count) TRK")
                    .font(.system(size: 9.5, weight: .black, design: .monospaced))
                    .foregroundColor(theme.buttonTextOnAccent)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(theme.accentRose)
                    .overlay(Rectangle().stroke(theme.ink, lineWidth: 1))
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .padding(.bottom, 6)
    }

    // MARK: - Section Sticker Tabs

    private var sectionStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                sectionStamp("МОЯ МУЗЫКА", active: vkClient.currentSection == .myMusic) {
                    Task { await vkClient.loadSection(.myMusic) }
                }
                sectionStamp("НЕДАВНО", active: vkClient.currentSection == .recentlyPlayed) {
                    Task { await vkClient.loadSection(.recentlyPlayed) }
                }
                sectionStamp(playlistsLabel, active: isPlaylistActive) {
                    showPlaylistsSheet = true
                }
                sectionStamp("РЕКОМЕНДАЦИИ", active: vkClient.currentSection == .recommendations) {
                    Task { await vkClient.loadSection(.recommendations) }
                }
                sectionStamp("ПОПУЛЯРНОЕ", active: vkClient.currentSection == .popular) {
                    Task { await vkClient.loadSection(.popular) }
                }
                sectionStamp("НА ДИСКЕ", active: vkClient.currentSection == .downloaded) {
                    Task { await vkClient.loadSection(.downloaded) }
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 2)
            .padding(.bottom, 7)
        }
    }

    private var isPlaylistActive: Bool {
        if case .playlist = vkClient.currentSection { return true }
        return false
    }

    private var playlistsLabel: String {
        if case .playlist(let pl) = vkClient.currentSection {
            return pl.title.uppercased()
        }
        return vkClient.playlists.isEmpty ? "ПЛЕЙЛИСТЫ" : "ПЛЕЙЛИСТЫ (\(vkClient.playlists.count))"
    }

    private func sectionStamp(_ title: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if active {
                    Text("★")
                        .font(.system(size: 9))
                }
                Text(title)
                    .font(.system(size: 10.5, weight: active ? .black : .bold, design: .monospaced))
            }
            .foregroundColor(active ? theme.buttonTextOnAccent : theme.textPrimary)
            .padding(.horizontal, 9)
            .frame(height: 28)
            .inkBox(theme, fill: active ? theme.accentSky : theme.paper, radius: 3, shadow: 2)
        }
    }

    // MARK: - Batch Action & Crossfade Bar

    private var actionBar: some View {
        HStack(spacing: 6) {
            Button {
                let list = filteredTracks
                if !list.isEmpty {
                    player.playFromList(list, index: 0)
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 9.5))
                    Text("СЛУШАТЬ")
                        .font(.system(size: 10.5, weight: .black, design: .monospaced))
                }
                .foregroundColor(theme.primaryKeyText)
                .padding(.horizontal, 10)
                .frame(height: 29)
                .inkBox(theme, fill: theme.primaryKeyFill, radius: 3, shadow: 2)
            }

            Button {
                let list = filteredTracks
                if !list.isEmpty {
                    if !player.shuffle { player.toggleShuffle() }
                    let idx = Int.random(in: 0..<list.count)
                    player.playFromList(list, index: idx)
                }
            } label: {
                Image(systemName: "shuffle")
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundColor(player.shuffle ? theme.buttonTextOnAccent : theme.textPrimary)
                    .frame(width: 30, height: 29)
                    .inkBox(theme, fill: player.shuffle ? theme.accentButter : theme.paper, radius: 3, shadow: 2)
            }

            Button {
                let list = filteredTracks
                if !list.isEmpty {
                    Task { await vkClient.downloadAll(list) }
                }
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: vkClient.batchDownloading ? "ellipsis" : "arrow.down")
                        .font(.system(size: 10, weight: .black))
                    Text(vkClient.batchDownloading ? "КАЧАЮ" : "ВСЕ")
                        .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                }
                .foregroundColor(theme.textPrimary)
                .padding(.horizontal, 8)
                .frame(height: 29)
                .inkBox(theme, fill: theme.paper, radius: 3, shadow: 2)
            }
            .disabled(vkClient.batchDownloading)

            if vkClient.currentSection == .recentlyPlayed && !vkClient.tracks.isEmpty {
                Button {
                    vkClient.clearRecentTracks()
                } label: {
                    Text("ОЧИСТИТЬ")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(theme.buttonTextOnAccent)
                        .padding(.horizontal, 7)
                        .frame(height: 29)
                        .inkBox(theme, fill: theme.accentRose, radius: 3, shadow: 2)
                }
            }

            Spacer()

            Button {
                player.cycleCrossfade()
            } label: {
                HStack(spacing: 3) {
                    Text("✦")
                        .font(.system(size: 9))
                    Text("\(player.crossfadeSecs)С")
                        .font(.system(size: 10.5, weight: .black, design: .monospaced))
                }
                .foregroundColor(player.crossfadeSecs > 0 ? theme.buttonTextOnAccent : theme.textSecondary)
                .padding(.horizontal, 8)
                .frame(height: 29)
                .inkBox(
                    theme,
                    fill: player.crossfadeSecs > 0 ? theme.accentButter : theme.paper,
                    radius: 3,
                    shadow: 2
                )
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Track List

    private var trackListView: some View {
        Group {
            if vkClient.isLoading && vkClient.tracks.isEmpty {
                VStack(spacing: 10) {
                    Spacer()
                    ProgressView()
                        .tint(theme.textPrimary)
                    Text("ЗАГРУЗКА...")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(theme.textSecondary)
                    Spacer()
                }
            } else if filteredTracks.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Text(emptyMessage.uppercased())
                        .font(.system(size: 12.5, weight: .bold, design: .monospaced))
                        .foregroundColor(theme.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .inkBox(theme, fill: theme.paper, radius: 3, shadow: 2)
                    if !vkClient.hasSavedSession && vkClient.currentSection != .recentlyPlayed && vkClient.currentSection != .downloaded {
                        Button {
                            showAuthSheet = true
                        } label: {
                            Text("ВОЙТИ ЧЕРЕЗ VK")
                                .font(.system(size: 12, weight: .black, design: .monospaced))
                                .foregroundColor(theme.buttonTextOnAccent)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .inkBox(theme, fill: theme.accentSky, radius: 3, shadow: 2)
                        }
                    }
                    Spacer()
                }
            } else {
                let list = filteredTracks
                let showAdd = vkClient.currentSection != .myMusic && vkClient.currentSection != .downloaded

                ScrollView {
                    LazyVStack(spacing: 5) {
                        ForEach(Array(list.enumerated()), id: \.offset) { index, track in
                            let isCurrent = player.currentTrack?.fullId == track.fullId
                            let isSaved = vkClient.downloadedIds.contains(track.fullId)
                            let isDownloading = vkClient.downloadingIds.contains(track.fullId)
                            let isAdded = vkClient.addedIds.contains(track.fullId)

                            TrackRowView(
                                index: index,
                                track: track,
                                theme: theme,
                                isCurrent: isCurrent,
                                isPlaying: isCurrent && player.isPlaying,
                                isSaved: isSaved,
                                isDownloading: isDownloading,
                                isAdded: isAdded,
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
                    .padding(.horizontal, 10)
                    .padding(.top, 7)
                    .padding(.bottom, player.currentTrack != nil ? 76 : 16)
                }
            }
        }
    }

    private var emptyMessage: String {
        if vkClient.currentSection == .recentlyPlayed {
            return "История прослушивания пуста"
        }
        return vkClient.hasSavedSession ? "Треки не найдены" : "Подключите аккаунт VK"
    }

    // MARK: - Bottom Mini-Player Deck

    private var miniPlayerBar: some View {
        Group {
            if let track = player.currentTrack {
                VStack(spacing: 0) {
                    GeometryReader { geo in
                        let progress = player.duration > 0 ? min(1, max(0, player.currentTime / player.duration)) : 0
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(theme.paper)
                            Rectangle()
                                .fill(theme.accentRose)
                                .frame(width: geo.size.width * progress)
                        }
                    }
                    .frame(height: 3.5)
                    .overlay(
                        Rectangle().stroke(theme.ink, lineWidth: 1)
                    )

                    HStack(spacing: 9) {
                        CoverThumb(urlString: track.coverUrl, size: 38, radius: 2, theme: theme)
                            .overlay(RoundedRectangle(cornerRadius: 2).stroke(theme.ink, lineWidth: 1.5))

                        VStack(alignment: .leading, spacing: 1.5) {
                            Text(track.title)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(theme.textPrimary)
                                .lineLimit(1)
                            HStack(spacing: 4) {
                                if player.isBuffering {
                                    Text("BUF")
                                        .font(.system(size: 9, weight: .black, design: .monospaced))
                                        .foregroundColor(theme.buttonTextOnAccent)
                                        .padding(.horizontal, 3)
                                        .background(theme.accentButter)
                                        .overlay(Rectangle().stroke(theme.ink, lineWidth: 1))
                                }
                                Text(track.artist)
                                    .font(.system(size: 11.5, weight: .medium))
                                    .foregroundColor(theme.textSecondary)
                                    .lineLimit(1)
                            }
                        }

                        Spacer(minLength: 4)

                        HStack(spacing: 5) {
                            Button {
                                player.previousTrack()
                            } label: {
                                Image(systemName: "backward.end.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(theme.textPrimary)
                                    .frame(width: 30, height: 30)
                                    .inkBox(theme, fill: theme.paper, radius: 3, shadow: 1.5)
                            }

                            Button {
                                player.togglePlayPause()
                            } label: {
                                Group {
                                    if player.isBuffering {
                                        ProgressView()
                                            .scaleEffect(0.65)
                                            .tint(theme.buttonTextOnAccent)
                                    } else {
                                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                                            .font(.system(size: 13))
                                            .foregroundColor(theme.buttonTextOnAccent)
                                    }
                                }
                                .frame(width: 34, height: 30)
                                .inkBox(theme, fill: theme.accentSky, radius: 3, shadow: 1.5)
                            }

                            Button {
                                player.nextTrack(manual: true)
                            } label: {
                                Image(systemName: "forward.end.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(theme.textPrimary)
                                    .frame(width: 30, height: 30)
                                    .inkBox(theme, fill: theme.paper, radius: 3, shadow: 1.5)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .background(theme.skyPanel)
                .overlay(
                    Rectangle()
                        .fill(theme.ink)
                        .frame(height: 1.5),
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
    let theme: ThemeColors
    let isCurrent: Bool
    let isPlaying: Bool
    let isSaved: Bool
    let isDownloading: Bool
    let isAdded: Bool
    let showAddButton: Bool
    let onTap: () -> Void
    let onAdd: () -> Void
    let onDownload: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Group {
                if isCurrent {
                    HStack(spacing: 1.5) {
                        Rectangle().frame(width: 2.2, height: isPlaying ? 7 : 3.5)
                        Rectangle().frame(width: 2.2, height: isPlaying ? 12 : 3.5)
                        Rectangle().frame(width: 2.2, height: isPlaying ? 8 : 3.5)
                    }
                    .foregroundColor(theme.textPrimary)
                } else {
                    Text(String(format: "%02d", index + 1))
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(theme.textSecondary)
                }
            }
            .frame(width: 24, height: 22)
            .background(isCurrent ? theme.accentButter : theme.skyPanel)
            .overlay(Rectangle().stroke(theme.ink, lineWidth: 1))

            CoverThumb(urlString: track.coverUrl, size: 38, radius: 2, theme: theme)
                .overlay(RoundedRectangle(cornerRadius: 2).stroke(theme.ink, lineWidth: 1.5))

            VStack(alignment: .leading, spacing: 2) {
                Text(track.title)
                    .font(.system(size: 13.5, weight: isCurrent ? .heavy : .semibold))
                    .foregroundColor(theme.textPrimary)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    if isSaved {
                        Circle()
                            .fill(theme.accentMint)
                            .frame(width: 6, height: 6)
                            .overlay(Circle().stroke(theme.ink, lineWidth: 1))
                    }
                    Text(track.artist)
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundColor(theme.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 4)

            if showAddButton {
                Button(action: onAdd) {
                    Image(systemName: isAdded ? "checkmark" : "plus")
                        .font(.system(size: 10.5, weight: .black))
                        .foregroundColor(isAdded ? theme.buttonTextOnAccent : theme.textPrimary)
                        .frame(width: 26, height: 26)
                        .background(isAdded ? theme.accentMint : theme.paper)
                        .overlay(Rectangle().stroke(theme.ink, lineWidth: 1.25))
                }
                .buttonStyle(.plain)
                .disabled(isAdded)
            }

            Button(action: onDownload) {
                Group {
                    if isDownloading {
                        ProgressView()
                            .scaleEffect(0.62)
                            .tint(theme.textPrimary)
                    } else if isSaved {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(theme.buttonTextOnAccent)
                    } else {
                        Image(systemName: "arrow.down")
                            .font(.system(size: 10.5, weight: .black))
                            .foregroundColor(theme.textPrimary)
                    }
                }
                .frame(width: 26, height: 26)
                .background(isSaved ? theme.accentMint : theme.paper)
                .overlay(Rectangle().stroke(theme.ink, lineWidth: 1.25))
            }
            .buttonStyle(.plain)

            Text(track.durationText)
                .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                .foregroundColor(theme.textMuted)
                .frame(width: 34, alignment: .trailing)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .inkBox(theme, fill: isCurrent ? theme.activePlate : theme.paper, radius: 3, shadow: isCurrent ? 2 : 1.5)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

private struct CoverThumb: View {
    let urlString: String
    let size: CGFloat
    let radius: CGFloat
    let theme: ThemeColors

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
            theme.skyPanel
            Image(systemName: "music.note")
                .font(.system(size: size * 0.34, weight: .bold))
                .foregroundColor(theme.textMuted)
        }
    }
}

private struct PlaylistsSheet: View {
    let playlists: [VKPlaylist]
    let theme: ThemeColors
    let onSelect: (VKPlaylist) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                SketchbookGridBackground(theme: theme)
                if playlists.isEmpty {
                    Text("ПЛЕЙЛИСТЫ НЕ НАЙДЕНЫ")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(theme.textSecondary)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(playlists) { pl in
                                Button {
                                    onSelect(pl)
                                } label: {
                                    HStack {
                                        Text(pl.title)
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(theme.textPrimary)
                                            .lineLimit(1)
                                        Spacer()
                                        Text("\(pl.count)")
                                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                                            .foregroundColor(theme.buttonTextOnAccent)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(theme.accentSky)
                                            .overlay(Rectangle().stroke(theme.ink, lineWidth: 1))
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .inkBox(theme, fill: theme.paper, radius: 3, shadow: 2)
                                }
                            }
                        }
                        .padding(14)
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
        .preferredColorScheme(theme.mode.colorScheme)
    }
}

private struct PrecisionBarSlider: View {
    let value: Double
    let range: ClosedRange<Double>
    let theme: ThemeColors
    let fillColor: Color
    let onChanged: (Double) -> Void
    let onEnded: (Double) -> Void

    @State private var isDragging = false

    private var fraction: Double {
        let span = range.upperBound - range.lowerBound
        guard span > 0 else { return 0 }
        return min(1, max(0, (value - range.lowerBound) / span))
    }

    var body: some View {
        GeometryReader { geo in
            let w = max(1, geo.size.width)
            let handleW: CGFloat = isDragging ? 10 : 8
            let xPos = CGFloat(fraction) * (w - handleW)

            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(theme.paper)
                    .frame(height: 10)
                    .overlay(Rectangle().stroke(theme.ink, lineWidth: 1.5))

                Rectangle()
                    .fill(fillColor)
                    .frame(width: max(0, xPos + handleW * 0.5), height: 7)
                    .padding(.leading, 1.5)

                Rectangle()
                    .fill(theme.accentButter)
                    .frame(width: handleW, height: 16)
                    .overlay(Rectangle().stroke(theme.ink, lineWidth: 1.5))
                    .offset(x: xPos)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        isDragging = true
                        let norm = min(1, max(0, Double(gesture.location.x / w)))
                        let newVal = range.lowerBound + norm * (range.upperBound - range.lowerBound)
                        onChanged(newVal)
                    }
                    .onEnded { gesture in
                        let norm = min(1, max(0, Double(gesture.location.x / w)))
                        let newVal = range.lowerBound + norm * (range.upperBound - range.lowerBound)
                        isDragging = false
                        onEnded(newVal)
                    }
            )
        }
        .frame(height: 24)
    }
}

private struct NowPlayingSheet: View {
    @EnvironmentObject var vkClient: VKAPIClient
    @EnvironmentObject var player: AudioPlayerManager
    @Environment(\.dismiss) private var dismiss

    @AppStorage("sqwore_theme") private var rawTheme: String = SqworeThemeMode.evePaper.rawValue
    @State private var isSeeking: Bool = false
    @State private var dragSeekSeconds: Double = 0
    @State private var isDraggingVolume: Bool = false
    @State private var dragVolume: Float = 1.0

    private var themeMode: SqworeThemeMode {
        SqworeThemeMode(rawValue: rawTheme) ?? .evePaper
    }

    private var theme: ThemeColors {
        ThemeColors(themeMode)
    }

    var body: some View {
        ZStack {
            SketchbookGridBackground(theme: theme)

            if let track = player.currentTrack {
                GeometryReader { geo in
                    let artSide = min(geo.size.width - 104, geo.size.height * 0.29, 200)
                    let effectiveVol = isDraggingVolume ? dragVolume : player.volume
                    let displayedPct = player.isMuted ? 0 : Int((effectiveVol * 100).rounded())
                    let fmtBadge = LocalStorage.findDownloadedFile(for: track)?.pathExtension.uppercased()
                        ?? (track.url.contains(".m3u8") ? "HLS" : "MP3")

                    VStack(spacing: 0) {
                        // Top Blueprint Header Strip
                        HStack(spacing: 8) {
                            Text("VK MUSIC // DECK")
                                .font(.system(size: 10.5, weight: .black, design: .monospaced))
                                .foregroundColor(theme.textPrimary)
                                .padding(.horizontal, 8)
                                .frame(height: 28)
                                .inkBox(theme, fill: theme.skyPanel, radius: 3, shadow: 2)

                            Spacer()

                            Button {
                                rawTheme = themeMode.next.rawValue
                            } label: {
                                Text(themeMode.badgeTitle)
                                    .font(.system(size: 10, weight: .black, design: .monospaced))
                                    .foregroundColor(theme.buttonTextOnAccent)
                                    .padding(.horizontal, 8)
                                    .frame(height: 28)
                                    .inkBox(theme, fill: theme.accentButter, radius: 3, shadow: 2)
                            }

                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 11.5, weight: .black))
                                    .foregroundColor(theme.textPrimary)
                                    .frame(width: 28, height: 28)
                                    .inkBox(theme, fill: theme.paper, radius: 3, shadow: 2)
                            }
                        }
                        .padding(.top, 12)

                        Spacer(minLength: 8)

                        // Framed Manga Artwork with Corner Zine Sticker
                        ZStack(alignment: .bottomTrailing) {
                            CoverThumb(urlString: track.coverUrl, size: artSide, radius: 2, theme: theme)
                                .overlay(Rectangle().stroke(theme.ink, lineWidth: 1.5))
                                .padding(7)
                                .inkBox(theme, fill: theme.paper, radius: 3, shadow: 3)

                            Text("\(fmtBadge) · \(player.crossfadeSecs)С")
                                .font(.system(size: 9.5, weight: .black, design: .monospaced))
                                .foregroundColor(theme.buttonTextOnAccent)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(theme.accentRose)
                                .overlay(Rectangle().stroke(theme.ink, lineWidth: 1.5))
                                .offset(x: 6, y: 6)
                        }

                        Spacer(minLength: 14)

                        // Title + Actions
                        HStack(alignment: .center, spacing: 8) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(track.title)
                                    .font(.system(size: 17, weight: .black))
                                    .foregroundColor(theme.textPrimary)
                                    .lineLimit(2)
                                Text(track.artist)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(theme.textSecondary)
                                    .lineLimit(1)
                            }
                            Spacer()

                            let isAdded = vkClient.addedIds.contains(track.fullId)
                            Button {
                                Task { await vkClient.addAudio(track: track) }
                            } label: {
                                Image(systemName: isAdded ? "checkmark" : "plus")
                                    .font(.system(size: 12.5, weight: .black))
                                    .foregroundColor(isAdded ? theme.buttonTextOnAccent : theme.textPrimary)
                                    .frame(width: 32, height: 32)
                                    .inkBox(theme, fill: isAdded ? theme.accentMint : theme.paper, radius: 3, shadow: 2)
                            }
                            .disabled(isAdded)

                            let isSaved = vkClient.downloadedIds.contains(track.fullId)
                            let isDownloading = vkClient.downloadingIds.contains(track.fullId)
                            Button {
                                Task { await vkClient.downloadTrack(track) }
                            } label: {
                                Group {
                                    if isDownloading {
                                        ProgressView().scaleEffect(0.7).tint(theme.textPrimary)
                                    } else if isSaved {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12, weight: .black))
                                            .foregroundColor(theme.buttonTextOnAccent)
                                    } else {
                                        Image(systemName: "arrow.down")
                                            .font(.system(size: 12.5, weight: .black))
                                            .foregroundColor(theme.textPrimary)
                                    }
                                }
                                .frame(width: 32, height: 32)
                                .inkBox(theme, fill: isSaved ? theme.accentMint : theme.paper, radius: 3, shadow: 2)
                            }
                        }

                        Spacer(minLength: 10)

                        // Tape Scrubber
                        VStack(spacing: 4) {
                            let maxDur = max(1.0, player.duration)
                            let shownPos = isSeeking ? dragSeekSeconds : min(player.currentTime, maxDur)

                            PrecisionBarSlider(
                                value: shownPos,
                                range: 0...maxDur,
                                theme: theme,
                                fillColor: theme.accentSky,
                                onChanged: { val in
                                    isSeeking = true
                                    dragSeekSeconds = val
                                },
                                onEnded: { val in
                                    player.seek(to: val)
                                    isSeeking = false
                                }
                            )

                            HStack {
                                Text(formatTime(shownPos))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(theme.paper)
                                    .overlay(Rectangle().stroke(theme.ink, lineWidth: 1))
                                Spacer()
                                Text(formatTime(player.duration))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(theme.paper)
                                    .overlay(Rectangle().stroke(theme.ink, lineWidth: 1))
                            }
                            .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                            .foregroundColor(theme.textPrimary)
                        }

                        Spacer(minLength: 10)

                        // Tactile Transport Keys
                        HStack(spacing: 12) {
                            Button {
                                player.toggleShuffle()
                            } label: {
                                Image(systemName: "shuffle")
                                    .font(.system(size: 14, weight: .black))
                                    .foregroundColor(player.shuffle ? theme.buttonTextOnAccent : theme.textPrimary)
                                    .frame(width: 36, height: 36)
                                    .inkBox(theme, fill: player.shuffle ? theme.accentButter : theme.paper, radius: 3, shadow: 2)
                            }

                            Button {
                                player.previousTrack()
                            } label: {
                                Image(systemName: "backward.end.fill")
                                    .font(.system(size: 17))
                                    .foregroundColor(theme.textPrimary)
                                    .frame(width: 44, height: 40)
                                    .inkBox(theme, fill: theme.paper, radius: 3, shadow: 2)
                            }

                            Button {
                                player.togglePlayPause()
                            } label: {
                                Group {
                                    if player.isBuffering {
                                        ProgressView().tint(theme.buttonTextOnAccent)
                                    } else {
                                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                                            .font(.system(size: 21))
                                            .foregroundColor(theme.buttonTextOnAccent)
                                    }
                                }
                                .frame(width: 56, height: 48)
                                .inkBox(theme, fill: theme.accentSky, radius: 3, shadow: 3)
                            }

                            Button {
                                player.nextTrack(manual: true)
                            } label: {
                                Image(systemName: "forward.end.fill")
                                    .font(.system(size: 17))
                                    .foregroundColor(theme.textPrimary)
                                    .frame(width: 44, height: 40)
                                    .inkBox(theme, fill: theme.paper, radius: 3, shadow: 2)
                            }

                            Button {
                                player.cycleRepeatMode()
                            } label: {
                                Image(systemName: player.repeatMode == .one ? "repeat.1" : "repeat")
                                    .font(.system(size: 14, weight: .black))
                                    .foregroundColor(player.repeatMode != .none ? theme.buttonTextOnAccent : theme.textPrimary)
                                    .frame(width: 36, height: 36)
                                    .inkBox(theme, fill: player.repeatMode != .none ? theme.accentRose : theme.paper, radius: 3, shadow: 2)
                            }
                        }

                        Spacer(minLength: 10)

                        // Volume Console + Crossfade Mode
                        VStack(spacing: 7) {
                            HStack(spacing: 6) {
                                Button {
                                    player.toggleMute()
                                } label: {
                                    Image(systemName: player.isMuted || effectiveVol <= 0.0001 ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(theme.textPrimary)
                                        .frame(width: 26, height: 24)
                                }

                                Button {
                                    player.adjustVolume(by: -0.01)
                                } label: {
                                    Text("−")
                                        .font(.system(size: 13, weight: .black, design: .monospaced))
                                        .foregroundColor(theme.textPrimary)
                                        .frame(width: 24, height: 24)
                                        .background(theme.skyPanel)
                                        .overlay(Rectangle().stroke(theme.ink, lineWidth: 1.25))
                                }

                                PrecisionBarSlider(
                                    value: Double(effectiveVol),
                                    range: 0...1,
                                    theme: theme,
                                    fillColor: theme.accentRose,
                                    onChanged: { v in
                                        isDraggingVolume = true
                                        dragVolume = Float(v)
                                        player.setVolume(Float(v))
                                    },
                                    onEnded: { v in
                                        player.setVolume(Float(v))
                                        isDraggingVolume = false
                                    }
                                )

                                Button {
                                    player.adjustVolume(by: 0.01)
                                } label: {
                                    Text("+")
                                        .font(.system(size: 13, weight: .black, design: .monospaced))
                                        .foregroundColor(theme.textPrimary)
                                        .frame(width: 24, height: 24)
                                        .background(theme.skyPanel)
                                        .overlay(Rectangle().stroke(theme.ink, lineWidth: 1.25))
                                }

                                Text(String(format: "%3d%%", displayedPct))
                                    .font(.system(size: 10.5, weight: .black, design: .monospaced))
                                    .foregroundColor(theme.textPrimary)
                                    .frame(width: 34, alignment: .trailing)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .inkBox(theme, fill: theme.paper, radius: 3, shadow: 2)

                            HStack {
                                Text("ПЕРЕХОД:")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(theme.textSecondary)
                                Spacer()
                                Button {
                                    player.cycleCrossfade()
                                } label: {
                                    Text(player.crossfadeSecs == 0 ? "0С · GAPLESS" : "\(player.crossfadeSecs)С · КРОССФЕЙД")
                                        .font(.system(size: 10, weight: .black, design: .monospaced))
                                        .foregroundColor(player.crossfadeSecs > 0 ? theme.buttonTextOnAccent : theme.textPrimary)
                                        .padding(.horizontal, 9)
                                        .padding(.vertical, 4)
                                        .inkBox(
                                            theme,
                                            fill: player.crossfadeSecs > 0 ? theme.accentButter : theme.paper,
                                            radius: 3,
                                            shadow: 2
                                        )
                                }
                            }
                        }
                        .padding(.bottom, 16)
                    }
                    .padding(.horizontal, 16)
                }
            } else {
                Button("Закрыть") { dismiss() }
            }
        }
        .preferredColorScheme(themeMode.colorScheme)
    }

    private func formatTime(_ secs: Double) -> String {
        let total = max(0, Int(secs))
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
