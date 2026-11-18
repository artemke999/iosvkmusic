import SwiftUI

// MARK: - Design System & User Preset Models

enum AppThemeKind: String, CaseIterable, Identifiable {
    case skyShards = "sky-shards"
    case eveSketch = "eve-sketch"
    case dream17 = "dream-17"
    case appleRetro = "apple-retro"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .skyShards: return "Sky Shards"
        case .eveSketch: return "EVE II Sketchbook"
        case .dream17: return "Dream 17"
        case .appleRetro: return "Apple Retro SE"
        }
    }

    var subtitle: String {
        switch self {
        case .skyShards: return "Светлый коллаж, матовое стекло и осколки неба"
        case .eveSketch: return "Тёплая бумага, тонкая тушь и сетка скетчбука"
        case .dream17: return "Ночной бархат, мягкое свечение 17 и дымчатое стекло"
        case .appleRetro: return "Алюминий iPod SE, OLED-блок и тактильные клавиши"
        }
    }

    var tag: String {
        switch self {
        case .skyShards: return "空 // SHARDS"
        case .eveSketch: return "EVE // ZINE"
        case .dream17: return "17 // NIGHT"
        case .appleRetro: return "iAUDIO // SE"
        }
    }

    var colorScheme: ColorScheme {
        self == .dream17 ? .dark : .light
    }

    var defaultBanner: BannerArtKind {
        switch self {
        case .skyShards: return .art2
        case .eveSketch: return .art1
        case .dream17: return .art4
        case .appleRetro: return .art2
        }
    }
}

enum BannerArtKind: String, CaseIterable, Identifiable {
    case art1
    case art2
    case art3
    case art4
    case none

    var id: String { rawValue }

    var title: String {
        switch self {
        case .art1: return "Арт 1 · EVE II"
        case .art2: return "Арт 2 · Sky Shards"
        case .art3: return "Арт 3 · Город"
        case .art4: return "Арт 4 · 17 Night"
        case .none: return "Без арта"
        }
    }

    var assetName: String? {
        switch self {
        case .art1: return "Art1Eve"
        case .art2: return "Art2Sky"
        case .art3: return "Art3City"
        case .art4: return "Art4Dream"
        case .none: return nil
        }
    }

    static func fallbackAsset(for track: VKTrack) -> String {
        let names = ["Art2Sky", "Art1Eve", "Art3City", "Art4Dream"]
        let idx = Int(abs(track.id) % Int64(names.count))
        return names[idx]
    }
}

enum RowDisplayStyle: String, CaseIterable, Identifiable {
    case covers
    case compact
    case cards

    var id: String { rawValue }

    var title: String {
        switch self {
        case .covers: return "С обложками"
        case .compact: return "Компактный"
        case .cards: return "Карточки"
        }
    }
}

enum MiniPlayerStyle: String, CaseIterable, Identifiable {
    case floating
    case docked
    case inline

    var id: String { rawValue }

    var title: String {
        switch self {
        case .floating: return "Капсула"
        case .docked: return "У нижнего края"
        case .inline: return "Встроенный"
        }
    }
}

enum NowPlayingTab: String, CaseIterable {
    case player
    case equalizer
}

struct ThemePalette {
    let kind: AppThemeKind
    let bgTop: Color
    let bgBottom: Color
    let surface: Color
    let surfaceMuted: Color
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
    let bannerText: Color
    let bannerMuted: Color

    init(_ kind: AppThemeKind) {
        self.kind = kind
        switch kind {
        case .skyShards:
            self.bgTop = Color(red: 223 / 255, green: 240 / 255, blue: 251 / 255)
            self.bgBottom = Color(red: 242 / 255, green: 247 / 255, blue: 252 / 255)
            self.surface = Color.white.opacity(0.78)
            self.surfaceMuted = Color(red: 217 / 255, green: 236 / 255, blue: 252 / 255).opacity(0.68)
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
            self.miniBg = Color.white.opacity(0.88)
            self.bannerText = Color(red: 22 / 255, green: 34 / 255, blue: 48 / 255)
            self.bannerMuted = Color(red: 58 / 255, green: 79 / 255, blue: 102 / 255)

        case .eveSketch:
            self.bgTop = Color(red: 246 / 255, green: 244 / 255, blue: 238 / 255)
            self.bgBottom = Color(red: 242 / 255, green: 239 / 255, blue: 231 / 255)
            self.surface = Color(red: 253 / 255, green: 252 / 255, blue: 248 / 255)
            self.surfaceMuted = Color(red: 238 / 255, green: 234 / 255, blue: 224 / 255)
            self.border = Color(red: 20 / 255, green: 20 / 255, blue: 23 / 255).opacity(0.16)
            self.strongBorder = Color(red: 20 / 255, green: 20 / 255, blue: 23 / 255).opacity(0.68)
            self.textPrimary = Color(red: 22 / 255, green: 22 / 255, blue: 26 / 255)
            self.textSecondary = Color(red: 90 / 255, green: 93 / 255, blue: 102 / 255)
            self.textMuted = Color(red: 140 / 255, green: 144 / 255, blue: 156 / 255)
            self.accent = Color(red: 85 / 255, green: 146 / 255, blue: 198 / 255)
            self.accentSoft = Color(red: 220 / 255, green: 235 / 255, blue: 247 / 255)
            self.accentText = Color(red: 16 / 255, green: 50 / 255, blue: 78 / 255)
            self.pillBg = Color(red: 22 / 255, green: 22 / 255, blue: 26 / 255)
            self.pillText = Color(red: 253 / 255, green: 252 / 255, blue: 248 / 255)
            self.miniBg = Color(red: 253 / 255, green: 252 / 255, blue: 248 / 255).opacity(0.95)
            self.bannerText = Color(red: 22 / 255, green: 22 / 255, blue: 26 / 255)
            self.bannerMuted = Color(red: 82 / 255, green: 85 / 255, blue: 95 / 255)

        case .dream17:
            self.bgTop = Color(red: 17 / 255, green: 11 / 255, blue: 31 / 255)
            self.bgBottom = Color(red: 9 / 255, green: 6 / 255, blue: 16 / 255)
            self.surface = Color(red: 25 / 255, green: 19 / 255, blue: 42 / 255).opacity(0.76)
            self.surfaceMuted = Color(red: 42 / 255, green: 31 / 255, blue: 68 / 255).opacity(0.60)
            self.border = Color(red: 218 / 255, green: 200 / 255, blue: 255 / 255).opacity(0.14)
            self.strongBorder = Color(red: 255 / 255, green: 164 / 255, blue: 232 / 255).opacity(0.45)
            self.textPrimary = Color(red: 246 / 255, green: 242 / 255, blue: 255 / 255)
            self.textSecondary = Color(red: 180 / 255, green: 169 / 255, blue: 212 / 255)
            self.textMuted = Color(red: 119 / 255, green: 108 / 255, blue: 152 / 255)
            self.accent = Color(red: 255 / 255, green: 156 / 255, blue: 227 / 255)
            self.accentSoft = Color(red: 255 / 255, green: 156 / 255, blue: 227 / 255).opacity(0.18)
            self.accentText = Color(red: 255 / 255, green: 214 / 255, blue: 244 / 255)
            self.pillBg = Color(red: 246 / 255, green: 242 / 255, blue: 255 / 255)
            self.pillText = Color(red: 19 / 255, green: 11 / 255, blue: 34 / 255)
            self.miniBg = Color(red: 22 / 255, green: 16 / 255, blue: 36 / 255).opacity(0.90)
            self.bannerText = Color(red: 246 / 255, green: 242 / 255, blue: 255 / 255)
            self.bannerMuted = Color(red: 198 / 255, green: 186 / 255, blue: 225 / 255)

        case .appleRetro:
            self.bgTop = Color(red: 238 / 255, green: 238 / 255, blue: 234 / 255)
            self.bgBottom = Color(red: 225 / 255, green: 225 / 255, blue: 220 / 255)
            self.surface = Color(red: 246 / 255, green: 246 / 255, blue: 242 / 255)
            self.surfaceMuted = Color(red: 217 / 255, green: 217 / 255, blue: 210 / 255)
            self.border = Color.black.opacity(0.11)
            self.strongBorder = Color.black.opacity(0.28)
            self.textPrimary = Color(red: 28 / 255, green: 28 / 255, blue: 30 / 255)
            self.textSecondary = Color(red: 92 / 255, green: 92 / 255, blue: 96 / 255)
            self.textMuted = Color(red: 142 / 255, green: 142 / 255, blue: 147 / 255)
            self.accent = Color(red: 44 / 255, green: 107 / 255, blue: 224 / 255)
            self.accentSoft = Color(red: 44 / 255, green: 107 / 255, blue: 224 / 255).opacity(0.14)
            self.accentText = Color(red: 23 / 255, green: 70 / 255, blue: 158 / 255)
            self.pillBg = Color(red: 44 / 255, green: 107 / 255, blue: 224 / 255)
            self.pillText = .white
            self.miniBg = Color(red: 242 / 255, green: 242 / 255, blue: 238 / 255).opacity(0.96)
            self.bannerText = Color(red: 244 / 255, green: 246 / 255, blue: 248 / 255)
            self.bannerMuted = Color(red: 185 / 255, green: 194 / 255, blue: 206 / 255)
        }
    }

    var rowRadius: CGFloat {
        kind == .eveSketch ? 8 : 12
    }

    var cardRadius: CGFloat {
        kind == .eveSketch ? 9 : 16
    }
}

// MARK: - Ambient Collage Backdrop

private struct AppBackdropView: View {
    let palette: ThemePalette

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [palette.bgTop, palette.bgBottom],
                startPoint: .top,
                endPoint: .bottom
            )

            switch palette.kind {
            case .skyShards:
                RadialGradient(
                    colors: [Color(red: 133 / 255, green: 192 / 255, blue: 238 / 255).opacity(0.45), .clear],
                    center: .topLeading,
                    startRadius: 10,
                    endRadius: 320
                )
                RadialGradient(
                    colors: [Color(red: 164 / 255, green: 214 / 255, blue: 160 / 255).opacity(0.20), .clear],
                    center: .bottomTrailing,
                    startRadius: 10,
                    endRadius: 280
                )
            case .eveSketch:
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
                    ctx.stroke(path, with: .color(Color.black.opacity(0.035)), lineWidth: 0.75)
                }
            case .dream17:
                RadialGradient(
                    colors: [Color(red: 255 / 255, green: 134 / 255, blue: 219 / 255).opacity(0.22), .clear],
                    center: .topTrailing,
                    startRadius: 10,
                    endRadius: 300
                )
                RadialGradient(
                    colors: [Color(red: 105 / 255, green: 221 / 255, blue: 255 / 255).opacity(0.16), .clear],
                    center: .bottomLeading,
                    startRadius: 10,
                    endRadius: 320
                )
            case .appleRetro:
                EmptyView()
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

// MARK: - Main Screen (Matches Preset: sky-shards | banner: art2 | rows: covers | mini: floating | tools: hidden)

struct ContentView: View {
    @EnvironmentObject var vkClient: VKAPIClient
    @EnvironmentObject var player: AudioPlayerManager

    @AppStorage("ui_theme") private var rawTheme: String = AppThemeKind.skyShards.rawValue
    @AppStorage("ui_banner") private var rawBanner: String = BannerArtKind.art2.rawValue
    @AppStorage("ui_row_style") private var rawRowStyle: String = RowDisplayStyle.covers.rawValue
    @AppStorage("ui_mini_style") private var rawMiniStyle: String = MiniPlayerStyle.floating.rawValue
    @AppStorage("ui_show_tools") private var showToolsStrip: Bool = false

    @State private var searchText: String = ""
    @State private var browsingPlaylists: Bool = false
    @State private var showAuthSheet: Bool = false
    @State private var showAppearanceSheet: Bool = false
    @State private var showNowPlayingSheet: Bool = false
    @State private var nowPlayingTab: NowPlayingTab = .player

    private var themeKind: AppThemeKind {
        AppThemeKind(rawValue: rawTheme) ?? .skyShards
    }

    private var palette: ThemePalette {
        ThemePalette(themeKind)
    }

    private var bannerKind: BannerArtKind {
        BannerArtKind(rawValue: rawBanner) ?? .art2
    }

    private var rowStyle: RowDisplayStyle {
        RowDisplayStyle(rawValue: rawRowStyle) ?? .covers
    }

    private var miniStyle: MiniPlayerStyle {
        MiniPlayerStyle(rawValue: rawMiniStyle) ?? .floating
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
            AppBackdropView(palette: palette)

            VStack(spacing: 0) {
                headerArea
                sectionTabsStrip
                if showToolsStrip {
                    optionalToolsStrip
                }
                mainContentArea
                if player.currentTrack != nil && miniStyle != .floating {
                    miniPlayerView
                }
            }

            if player.currentTrack != nil && miniStyle == .floating {
                miniPlayerView
                    .padding(.horizontal, 10)
                    .padding(.bottom, 10)
            }
        }
        .preferredColorScheme(palette.kind.colorScheme)
        .sheet(isPresented: $showAuthSheet) {
            VKWebAuthSheet()
        }
        .sheet(isPresented: $showNowPlayingSheet) {
            NowPlayingSheet(
                selectedTab: $nowPlayingTab,
                palette: palette,
                onOpenAppearance: {
                    showNowPlayingSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        showAppearanceSheet = true
                    }
                }
            )
        }
        .sheet(isPresented: $showAppearanceSheet) {
            AppearanceSheet(
                rawTheme: $rawTheme,
                rawBanner: $rawBanner,
                rawRowStyle: $rawRowStyle,
                rawMiniStyle: $rawMiniStyle,
                showToolsStrip: $showToolsStrip,
                palette: palette
            )
        }
    }

    // MARK: - Header & Search

    private var headerArea: some View {
        VStack(spacing: 8) {
            if let asset = bannerKind.assetName {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("VK Music")
                            .font(.system(size: 17, weight: .heavy))
                            .tracking(-0.3)
                            .foregroundColor(palette.bannerText)

                        Text(headerSubtitle)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(palette.bannerMuted)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 4)

                    headerActionButtons(onDarkBanner: themeKind == .dream17 || themeKind == .appleRetro)
                }
                .padding(.horizontal, 12)
                .frame(height: 60)
                .background(
                    GeometryReader { geo in
                        ZStack(alignment: .trailing) {
                            bannerSurfaceBackground

                            Image(asset)
                                .resizable()
                                .scaledToFill()
                                .frame(width: geo.size.width, height: geo.size.height)
                                .opacity(bannerImageOpacity)
                                .grayscale(themeKind == .eveSketch ? 1.0 : 0.0)

                            LinearGradient(
                                colors: [
                                    bannerWashColor.opacity(themeKind == .dream17 || themeKind == .appleRetro ? 0.85 : 0.72),
                                    bannerWashColor.opacity(0.28)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )

                            if themeKind == .skyShards {
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
                            }
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: palette.cardRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: palette.cardRadius)
                        .stroke(themeKind == .eveSketch ? palette.strongBorder : palette.border, lineWidth: 1)
                )
            } else {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("VK Music")
                            .font(.system(size: 20, weight: .heavy))
                            .tracking(-0.4)
                            .foregroundColor(palette.textPrimary)
                        Text(headerSubtitle)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(palette.textMuted)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 4)
                    headerActionButtons(onDarkBanner: themeKind == .dream17)
                }
                .padding(.horizontal, 2)
                .padding(.top, 2)
            }

            HStack(spacing: 7) {
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
                .clipShape(RoundedRectangle(cornerRadius: palette.rowRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: palette.rowRadius)
                        .stroke(themeKind == .eveSketch ? palette.strongBorder : palette.border, lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .padding(.bottom, 8)
    }

    private func headerActionButtons(onDarkBanner: Bool) -> some View {
        let chipBg = onDarkBanner ? Color.white.opacity(0.14) : Color.white.opacity(0.62)
        let chipStroke = onDarkBanner ? Color.white.opacity(0.24) : palette.border
        let textCol = onDarkBanner ? Color.white : palette.textPrimary

        return HStack(spacing: 5) {
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
                .foregroundColor(player.eqEnabled ? (onDarkBanner ? palette.accent : palette.accentText) : textCol)
                .padding(.horizontal, 8)
                .frame(height: 27)
                .background(player.eqEnabled ? palette.accentSoft : chipBg)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(player.eqEnabled ? palette.accent.opacity(0.55) : chipStroke, lineWidth: 1))
            }
            .buttonStyle(.plain)

            Button {
                showAppearanceSheet = true
            } label: {
                Text("✦ Вид")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(textCol)
                    .padding(.horizontal, 8)
                    .frame(height: 27)
                    .background(chipBg)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(chipStroke, lineWidth: 1))
            }
            .buttonStyle(.plain)

            Button {
                showAuthSheet = true
            } label: {
                HStack(spacing: 4) {
                    Circle()
                        .fill(vkClient.user != nil ? Color.green : Color.orange)
                        .frame(width: 6, height: 6)
                    Text(vkClient.user?.name ?? "Войти")
                        .font(.system(size: 11, weight: .semibold))
                        .lineLimit(1)
                }
                .foregroundColor(textCol)
                .frame(maxWidth: 92)
                .padding(.horizontal, 8)
                .frame(height: 27)
                .background(chipBg)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(chipStroke, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var bannerSurfaceBackground: some View {
        if themeKind == .appleRetro {
            LinearGradient(
                colors: [
                    Color(red: 39 / 255, green: 43 / 255, blue: 48 / 255),
                    Color(red: 27 / 255, green: 30 / 255, blue: 34 / 255)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            palette.surface
        }
    }

    private var bannerWashColor: Color {
        if themeKind == .appleRetro {
            return Color(red: 27 / 255, green: 30 / 255, blue: 34 / 255)
        }
        return palette.surface
    }

    private var bannerImageOpacity: Double {
        switch themeKind {
        case .skyShards: return 0.36
        case .eveSketch: return 0.22
        case .dream17: return 0.32
        case .appleRetro: return 0.18
        }
    }

    private var headerSubtitle: String {
        if player.isAirPodsConnected {
            return "🎧 \(player.audioRouteName) · \(player.eqPreset.title)"
        }
        if vkClient.isLoading {
            return vkClient.statusText
        }
        return "\(themeKind.tag) · \(filteredTracks.count) треков"
    }

    private func submitSearchOrReload() {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        browsingPlaylists = false
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
                    Task { await vkClient.loadSection(.myMusic) }
                }
                sectionPill("Недавно", active: !browsingPlaylists && vkClient.currentSection == .recentlyPlayed) {
                    browsingPlaylists = false
                    Task { await vkClient.loadSection(.recentlyPlayed) }
                }
                sectionPill(playlistsTabTitle, active: browsingPlaylists || isPlaylistSection) {
                    browsingPlaylists = true
                }
                sectionPill("Рекомендации", active: !browsingPlaylists && vkClient.currentSection == .recommendations) {
                    browsingPlaylists = false
                    Task { await vkClient.loadSection(.recommendations) }
                }
                sectionPill("Популярное", active: !browsingPlaylists && vkClient.currentSection == .popular) {
                    browsingPlaylists = false
                    Task { await vkClient.loadSection(.popular) }
                }
                sectionPill("На диске", active: !browsingPlaylists && vkClient.currentSection == .downloaded) {
                    browsingPlaylists = false
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
                .clipShape(RoundedRectangle(cornerRadius: themeKind == .eveSketch ? 6 : 15))
                .overlay(
                    RoundedRectangle(cornerRadius: themeKind == .eveSketch ? 6 : 15)
                        .stroke(active ? Color.clear : palette.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // Optional Aux Strip (hidden by default to honor tools: hidden)

    private var optionalToolsStrip: some View {
        HStack(spacing: 6) {
            toolChip("⇄ Mix", active: player.shuffle) {
                player.toggleShuffle()
            }
            toolChip(repeatChipTitle, active: player.repeatMode != .none) {
                player.cycleRepeatMode()
            }
            toolChip("≈ \(player.crossfadeSecs)с", active: player.crossfadeSecs > 0) {
                player.cycleCrossfade()
            }
            toolChip("🎧 EQ", active: player.eqEnabled) {
                nowPlayingTab = .equalizer
                showNowPlayingSheet = true
            }
            Spacer()
            if !filteredTracks.isEmpty {
                toolChip(vkClient.batchDownloading ? "Качаю..." : "↓ Все", active: false) {
                    Task { await vkClient.downloadAll(filteredTracks) }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    private var repeatChipTitle: String {
        switch player.repeatMode {
        case .none: return "↻ Off"
        case .all: return "↻ All"
        case .one: return "↻ 1"
        }
    }

    private func toolChip(_ title: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(active ? palette.accentText : palette.textSecondary)
                .padding(.horizontal, 9)
                .frame(height: 26)
                .background(active ? palette.accentSoft : palette.surface)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(active ? palette.accent.opacity(0.5) : palette.border, lineWidth: 1))
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
        Group {
            if vkClient.playlists.isEmpty {
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
                        ForEach(Array(vkClient.playlists.enumerated()), id: \.element.id) { idx, pl in
                            let artNames = ["Art1Eve", "Art2Sky", "Art4Dream", "Art3City"]
                            let fallbackName = artNames[idx % artNames.count]
                            Button {
                                browsingPlaylists = false
                                Task { await vkClient.loadSection(.playlist(pl)) }
                            } label: {
                                HStack(spacing: 10) {
                                    Image(fallbackName)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 46, height: 46)
                                        .clipShape(RoundedRectangle(cornerRadius: 9))
                                        .overlay(RoundedRectangle(cornerRadius: 9).stroke(palette.border, lineWidth: 1))

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(pl.title)
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(palette.textPrimary)
                                            .lineLimit(1)
                                        Text("\(pl.count) треков")
                                            .font(.system(size: 12))
                                            .foregroundColor(palette.textSecondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(palette.textMuted)
                                }
                                .padding(.horizontal, 11)
                                .padding(.vertical, 9)
                                .background(palette.surface)
                                .clipShape(RoundedRectangle(cornerRadius: palette.rowRadius))
                                .overlay(RoundedRectangle(cornerRadius: palette.rowRadius).stroke(palette.border, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 2)
                    .padding(.bottom, floatingListBottomInset)
                }
            }
        }
    }

    private var trackListView: some View {
        Group {
            if vkClient.isLoading && vkClient.tracks.isEmpty {
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
                    LazyVStack(spacing: rowStyle == .cards ? 6 : 2) {
                        contextualListBar(list: list)

                        ForEach(Array(list.enumerated()), id: \.offset) { index, track in
                            let isCurrent = player.currentTrack?.fullId == track.fullId
                            let isSaved = vkClient.downloadedIds.contains(track.fullId)
                            let isDownloading = vkClient.downloadingIds.contains(track.fullId)
                            let isAdded = vkClient.addedIds.contains(track.fullId)

                            TrackRowView(
                                index: index,
                                track: track,
                                palette: palette,
                                rowStyle: rowStyle,
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
                    .padding(.horizontal, 12)
                    .padding(.top, 2)
                    .padding(.bottom, floatingListBottomInset)
                }
            }
        }
    }

    @ViewBuilder
    private func contextualListBar(list: [VKTrack]) -> some View {
        HStack(spacing: 8) {
            if isPlaylistSection {
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
                        .background(Color.red.opacity(0.10))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            Button {
                Task { await vkClient.downloadAll(list) }
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
        .padding(.bottom, 6)
    }

    private var floatingListBottomInset: CGFloat {
        guard player.currentTrack != nil else { return 16 }
        return miniStyle == .floating ? 84 : 12
    }

    private var emptyMessage: String {
        if vkClient.currentSection == .recentlyPlayed {
            return "История прослушивания пуста"
        }
        return vkClient.hasSavedSession ? "Ничего не найдено" : "Подключите аккаунт VK"
    }

    // MARK: - Floating / Docked / Inline Mini-Player

    @ViewBuilder
    private var miniPlayerView: some View {
        if let track = player.currentTrack {
            let corner: CGFloat = miniStyle == .docked ? 0 : palette.cardRadius
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
                    ArtworkView(track: track, size: 38, radius: 8, palette: palette)

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

                    HStack(spacing: 6) {
                        Button {
                            player.previousTrack()
                        } label: {
                            Image(systemName: "backward.end.fill")
                                .font(.system(size: 11.5))
                                .foregroundColor(palette.textPrimary)
                                .frame(width: 28, height: 28)
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
                                        .scaleEffect(0.62)
                                        .tint(palette.pillText)
                                } else {
                                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                                        .font(.system(size: 12.5))
                                        .foregroundColor(palette.pillText)
                                }
                            }
                            .frame(width: 33, height: 33)
                            .background(palette.pillBg)
                            .clipShape(Circle())
                        }
                        .buttonStyle(.plain)

                        Button {
                            player.nextTrack(manual: true)
                        } label: {
                            Image(systemName: "forward.end.fill")
                                .font(.system(size: 11.5))
                                .foregroundColor(palette.textPrimary)
                                .frame(width: 28, height: 28)
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
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: corner))
            .overlay(
                RoundedRectangle(cornerRadius: corner)
                    .stroke(themeKind == .eveSketch ? palette.strongBorder : palette.border, lineWidth: 1)
            )
            .shadow(
                color: Color.black.opacity(miniStyle == .floating ? 0.14 : 0.05),
                radius: miniStyle == .floating ? 16 : 6,
                x: 0,
                y: miniStyle == .floating ? 8 : -2
            )
            .padding(.horizontal, miniStyle == .inline ? 12 : 0)
            .padding(.bottom, miniStyle == .inline ? 10 : 0)
            .contentShape(Rectangle())
            .onTapGesture {
                nowPlayingTab = .player
                showNowPlayingSheet = true
            }
        }
    }

    private func formatTime(_ secs: Double) -> String {
        let total = max(0, Int(secs))
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

// MARK: - Track Row (Covers / Compact / Cards)

private struct TrackRowView: View {
    let index: Int
    let track: VKTrack
    let palette: ThemePalette
    let rowStyle: RowDisplayStyle
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
        HStack(spacing: rowStyle == .compact ? 8 : 10) {
            if rowStyle != .compact {
                ZStack {
                    ArtworkView(track: track, size: 40, radius: 8, palette: palette)
                    if isCurrent {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black.opacity(0.36))
                            .frame(width: 40, height: 40)
                        HStack(spacing: 2) {
                            Capsule().frame(width: 2.5, height: isPlaying ? 8 : 4)
                            Capsule().frame(width: 2.5, height: isPlaying ? 14 : 4)
                            Capsule().frame(width: 2.5, height: isPlaying ? 10 : 4)
                        }
                        .foregroundColor(.white)
                    }
                }
            } else {
                Text(isCurrent ? (isPlaying ? "ılı" : "▶") : String(format: "%d", index + 1))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(isCurrent ? palette.accentText : palette.textMuted)
                    .frame(width: 22)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(track.title)
                    .font(.system(size: 13.5, weight: isCurrent ? .bold : .semibold))
                    .foregroundColor(isCurrent ? palette.accentText : palette.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    if isSaved {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                    }
                    Text(track.albumTitle.isEmpty ? track.artist : "\(track.artist) · \(track.albumTitle)")
                        .font(.system(size: 11.5))
                        .foregroundColor(palette.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 4)

            if showAddButton {
                Button(action: onAdd) {
                    Image(systemName: isAdded ? "checkmark" : "plus")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(isAdded ? .white : palette.textSecondary)
                        .frame(width: 26, height: 26)
                        .background(isAdded ? Color.green : palette.surfaceMuted)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(isAdded)
            }

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
                .background(isSaved ? Color.green : palette.surfaceMuted)
                .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Text(track.durationText)
                .font(.system(size: 11, weight: .medium).monospacedDigit())
                .foregroundColor(palette.textMuted)
                .frame(width: 34, alignment: .trailing)
        }
        .padding(.horizontal, rowStyle == .cards ? 10 : 8)
        .padding(.vertical, rowStyle == .compact ? 6 : 7)
        .background(rowBackground)
        .clipShape(RoundedRectangle(cornerRadius: palette.rowRadius))
        .overlay(
            RoundedRectangle(cornerRadius: palette.rowRadius)
                .stroke(rowBorderColor, lineWidth: isCurrent || rowStyle == .cards ? 1 : 0)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }

    private var rowBackground: Color {
        if isCurrent { return palette.accentSoft }
        return rowStyle == .cards ? palette.surface : .clear
    }

    private var rowBorderColor: Color {
        if isCurrent { return palette.accent.opacity(0.45) }
        return rowStyle == .cards ? palette.border : .clear
    }
}

// MARK: - Artwork View (VK Cover + Bundled Sqwore Fallback)

private struct ArtworkView: View {
    let track: VKTrack
    let size: CGFloat
    let radius: CGFloat
    let palette: ThemePalette

    var body: some View {
        Group {
            if let url = URL(string: track.coverUrl), !track.coverUrl.isEmpty {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        fallbackArt
                    }
                }
            } else {
                fallbackArt
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: radius))
        .overlay(
            RoundedRectangle(cornerRadius: radius)
                .stroke(palette.border, lineWidth: 1)
        )
    }

    private var fallbackArt: some View {
        Image(BannerArtKind.fallbackAsset(for: track))
            .resizable()
            .scaledToFill()
    }
}

// MARK: - Appearance Picker Sheet

private struct AppearanceSheet: View {
    @Binding var rawTheme: String
    @Binding var rawBanner: String
    @Binding var rawRowStyle: String
    @Binding var rawMiniStyle: String
    @Binding var showToolsStrip: Bool
    let palette: ThemePalette
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackdropView(palette: palette)

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("КОНЦЕПТ ОФОРМЛЕНИЯ")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(palette.textMuted)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(AppThemeKind.allCases) { kind in
                                    let active = rawTheme == kind.rawValue
                                    Button {
                                        rawTheme = kind.rawValue
                                        rawBanner = kind.defaultBanner.rawValue
                                    } label: {
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(kind.title)
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundColor(palette.textPrimary)
                                            Text(kind.subtitle)
                                                .font(.system(size: 11))
                                                .foregroundColor(palette.textSecondary)
                                                .lineLimit(2)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(10)
                                        .background(active ? palette.accentSoft : palette.surface)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(active ? palette.accent : palette.border, lineWidth: active ? 1.5 : 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("АРТ В ШАПКЕ")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(palette.textMuted)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 7) {
                                    ForEach(BannerArtKind.allCases) { art in
                                        let active = rawBanner == art.rawValue
                                        Button {
                                            rawBanner = art.rawValue
                                        } label: {
                                            HStack(spacing: 6) {
                                                if let asset = art.assetName {
                                                    Image(asset)
                                                        .resizable()
                                                        .scaledToFill()
                                                        .frame(width: 20, height: 20)
                                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                                }
                                                Text(art.title)
                                                    .font(.system(size: 12, weight: .semibold))
                                            }
                                            .foregroundColor(active ? palette.pillText : palette.textPrimary)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 7)
                                            .background(active ? palette.pillBg : palette.surface)
                                            .clipShape(Capsule())
                                            .overlay(Capsule().stroke(active ? Color.clear : palette.border, lineWidth: 1))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("СТРОКИ СПИСКА")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(palette.textMuted)
                            HStack(spacing: 6) {
                                ForEach(RowDisplayStyle.allCases) { rs in
                                    let active = rawRowStyle == rs.rawValue
                                    Button {
                                        rawRowStyle = rs.rawValue
                                    } label: {
                                        Text(rs.title)
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(active ? palette.pillText : palette.textPrimary)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 8)
                                            .background(active ? palette.pillBg : palette.surface)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(active ? Color.clear : palette.border, lineWidth: 1))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("МИНИ-ПЛЕЕР И ПАНЕЛЬ")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(palette.textMuted)
                            HStack(spacing: 6) {
                                ForEach(MiniPlayerStyle.allCases) { ms in
                                    let active = rawMiniStyle == ms.rawValue
                                    Button {
                                        rawMiniStyle = ms.rawValue
                                    } label: {
                                        Text(ms.title)
                                            .font(.system(size: 11.5, weight: .semibold))
                                            .foregroundColor(active ? palette.pillText : palette.textPrimary)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 8)
                                            .background(active ? palette.pillBg : palette.surface)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(active ? Color.clear : palette.border, lineWidth: 1))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            Toggle(isOn: $showToolsStrip) {
                                Text("Показывать полоску Mix / Rpt / Xfade сверху")
                                    .font(.system(size: 12.5, weight: .medium))
                                    .foregroundColor(palette.textPrimary)
                            }
                            .tint(palette.accent)
                            .padding(10)
                            .background(palette.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(palette.border, lineWidth: 1))
                        }
                    }
                    .padding(14)
                }
            }
            .navigationTitle("Внешний вид")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .preferredColorScheme(palette.kind.colorScheme)
    }
}

// MARK: - Full Player + Equalizer & AirPods 3 Sheet

private struct NowPlayingSheet: View {
    @EnvironmentObject var vkClient: VKAPIClient
    @EnvironmentObject var player: AudioPlayerManager
    @Environment(\.dismiss) private var dismiss

    @Binding var selectedTab: NowPlayingTab
    let palette: ThemePalette
    let onOpenAppearance: () -> Void

    @State private var isSeeking: Bool = false
    @State private var dragSeekSeconds: Double = 0
    @State private var isDraggingVolume: Bool = false
    @State private var dragVolume: Float = 1.0

    var body: some View {
        ZStack {
            AppBackdropView(palette: palette)

            VStack(spacing: 0) {
                topBar
                if selectedTab == .player {
                    playerBody
                } else {
                    equalizerBody
                }
            }
        }
        .preferredColorScheme(palette.kind.colorScheme)
    }

    private var topBar: some View {
        HStack(spacing: 8) {
            Button {
                dismiss()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                    Text("Список")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(palette.textPrimary)
                .padding(.horizontal, 10)
                .frame(height: 30)
                .background(palette.surface)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(palette.border, lineWidth: 1))
            }
            .buttonStyle(.plain)

            Spacer()

            HStack(spacing: 3) {
                tabButton("Плеер", tab: .player)
                tabButton("🎧 EQ · AirPods 3", tab: .equalizer)
            }
            .padding(3)
            .background(palette.surface)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(palette.border, lineWidth: 1))

            Spacer()

            Button(action: onOpenAppearance) {
                Text("✦")
                    .font(.system(size: 13, weight: .bold))
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
                .padding(.horizontal, 10)
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
                            ArtworkView(track: track, size: 214, radius: palette.cardRadius, palette: palette)
                                .shadow(color: Color.black.opacity(0.22), radius: 22, x: 0, y: 12)

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
                                nowPlayingTab = .equalizer
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

                            let isAdded = vkClient.addedIds.contains(track.fullId)
                            Button {
                                Task { await vkClient.addAudio(track: track) }
                            } label: {
                                Image(systemName: isAdded ? "checkmark" : "plus")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(isAdded ? .white : palette.textPrimary)
                                    .frame(width: 28, height: 28)
                                    .background(isAdded ? Color.green : palette.surface)
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
                                .background(isSaved ? Color.green : palette.surface)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(palette.border, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }

                        // Timeline Scrubber
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

                        // Transport Buttons
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
                                    .overlay(Circle().stroke(player.shuffle ? palette.accent : palette.border, lineWidth: 1))
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
                                .shadow(color: Color.black.opacity(0.22), radius: 12, y: 6)
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
                                    .overlay(Circle().stroke(player.repeatMode != .none ? palette.accent : palette.border, lineWidth: 1))
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
                        .clipShape(RoundedRectangle(cornerRadius: palette.cardRadius))
                        .overlay(RoundedRectangle(cornerRadius: palette.cardRadius).stroke(palette.border, lineWidth: 1))
                        .padding(.horizontal, 14)
                        .padding(.bottom, 18)
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Spacer()
                    Image("Art2Sky")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 140, height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    Text("Выбери трек из списка")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(palette.textPrimary)
                    Button {
                        nowPlayingTab = .equalizer
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

    // MARK: - Equalizer & AirPods 3 Studio Tab

    private var equalizerBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // 1. Master Status + Live Audio Route Card
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: player.isAirPodsConnected ? "airpods.gen3" : "headphones")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(player.isAirPodsConnected ? .green : palette.accent)
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
                        .tint(palette.accent)
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
                    .tint(palette.accent)

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
                .clipShape(RoundedRectangle(cornerRadius: palette.cardRadius))
                .overlay(RoundedRectangle(cornerRadius: palette.cardRadius).stroke(palette.border, lineWidth: 1))

                // 2. Antipop / Hyperpop & AirPods 3 Presets
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

                // 3. Frequency Curve Visualizer + 6-Band Interactive Faders
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
                .clipShape(RoundedRectangle(cornerRadius: palette.cardRadius))
                .overlay(RoundedRectangle(cornerRadius: palette.cardRadius).stroke(palette.border, lineWidth: 1))
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
