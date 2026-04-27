//
//  ContentView.swift
//  MorseMode
//
//  Created by Ishauna Marie Alexander on 1/22/26.
//

import SwiftUI
import WatchConnectivity
import Combine
import SpriteKit

#if canImport(UIKit)
import UIKit
#endif

private struct IsInOnboardingKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var isInOnboarding: Bool {
        get { self[IsInOnboardingKey.self] }
        set { self[IsInOnboardingKey.self] = newValue }
    }
}

private enum AppDestination: Hashable {
    // Defines possible destinations
    case daily
    case leaderboard
    case warehouse
    case journey
    case journeyResume
    case journeyLevel(Int)
}

private enum HomeCard: Hashable {
    case rank
    case leaderboard
    case daily
    case journey
    case warehouse
}

struct ContentView: View {
    @EnvironmentObject private var morseEngine: MorseEngine
    // Shared Morse code logic
    @EnvironmentObject var userProgress: UserProgress
    @EnvironmentObject private var playbackSettings: PlaybackSettings
    // Shared global data
    
    @StateObject private var connectivity = MorseModePhoneConnectivity.shared
    // Connects phone to watch
    @State private var path: [AppDestination] = []
    @StateObject private var dailyViewModel = DailyMorseViewModel()
    
    // Set Environment(\.isInOnboarding) = true from your Onboarding view to disable watch-driven navigation while onboarding is active.
    @State private var isInOnboarding: Bool = false
    @State private var isShowingOnboardingReplay: Bool = false
    @State private var isShowingPlaybackSettings: Bool = false
    @State private var flashingCard: HomeCard?
    
    private let contentCardSpacing: CGFloat = 24
    
    private var progressFraction: Double {
        let needed = max(userProgress.expNeededForNextLevel, 1)
        return min(max(Double(userProgress.currentEXP) / Double(needed), 0), 1)
    }
    
    private var currentJourneyLevel: Int {
        (1...14).first(where: {
            userProgress.isLevelUnlocked($0) && !userProgress.isLevelCompleted($0)
        }) ?? ((1...14).last(where: { userProgress.isLevelUnlocked($0) }) ?? 1)
    }

    private var visibleJourneyLevels: [Int] {
        let totalLevels = 14
        let previewCount = 5
        let highestStart = max(1, totalLevels - previewCount + 1)
        let startLevel = min(currentJourneyLevel, highestStart)
        let endLevel = min(startLevel + previewCount - 1, totalLevels)
        return Array(startLevel...endLevel)
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: contentCardSpacing) {
                    topStatusRow
                    dailyMissionCard
                        .padding(.bottom, 24)
                    journeyCard
                        .padding(.bottom, 40)
                    warehouseCard
                }
                .frame(maxWidth: 420)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, contentCardSpacing)
                .padding(.vertical, contentCardSpacing)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background {
                ZStack {
                    if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                        DigitalRainBackground(isPaused: !playbackSettings.isDigitalRainEnabled)
                    } else {
                        Color.black
                    }
                }
                .ignoresSafeArea()
            }
            .overlay(alignment: .topTrailing) {
                topTrailingButtons
                    .padding(.top, -10)
                    .padding(.trailing, contentCardSpacing)
            }
                .onReceive(connectivity.$requestedView.compactMap { $0 }) { requested in
                    // If onboarding is active, ignore watch-driven navigation changes.
                    guard !isInOnboarding else {
                        DispatchQueue.main.async { connectivity.requestedView = nil }
                        return
                    }
                
                    if let destination = mapRequestedView(requested) {
                    // Pop to root first so all screens return to ContentView.
                    path.removeAll()
                    // Then navigate to the requested destination from root.
                    path.append(destination)
                    if destination == .daily {
                        connectivity.sendWatchHaptics(
                            morse: dailyViewModel.morseClue,
                            word: dailyViewModel.targetWord
                        )
                    }
                    DispatchQueue.main.async {
                        connectivity.requestedView = nil
                    }
                } else {
                        print("Unknown requested view: \(requested)")
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: MorseModePhoneConnectivity.resendDailyMorseNotification)) { _ in
                    connectivity.sendWatchHaptics(
                        morse: dailyViewModel.morseClue,
                        word: dailyViewModel.targetWord
                    )
                }
                .navigationDestination(for: AppDestination.self) { destination in
                    switch destination {
                    case .daily:
                        DailyRoot(vm: dailyViewModel)
                    case .leaderboard:
                        LeaderboardView()
                    case .warehouse:
                        Practice(morseEngine: morseEngine, letter: nil)
                    case .journey:
                        Journey()
                    case .journeyResume:
                        Journey(openCurrentLevelOnAppear: true)
                    case .journeyLevel(let level):
                        Journey(initialSelectedLevel: level)
                    }
                }
        }
        .fullScreenCover(isPresented: $isShowingOnboardingReplay, onDismiss: {
            isInOnboarding = false
        }) {
            OnboardingView(items: onboardingData) {
                isShowingOnboardingReplay = false
                isInOnboarding = false
            }
            .onAppear {
                isInOnboarding = true
            }
        }
        .environment(\.isInOnboarding, isInOnboarding)
        .sheet(isPresented: $isShowingPlaybackSettings) {
            PlaybackSettingsSheet()
                .environmentObject(playbackSettings)
                .environmentObject(morseEngine)
                .preferredColorScheme(.dark)
        }
        .preferredColorScheme(.dark)
    }

    private var topTrailingButtons: some View {
        HStack(spacing: 12) {
            circularOverlayButton(systemName: "gearshape", label: "Playback settings") {
                isShowingPlaybackSettings = true
            }

            circularOverlayButton(systemName: "info.circle", label: "Replay onboarding") {
                triggerSuccessHaptic()
                isShowingOnboardingReplay = true
            }
        }
    }

    private func circularOverlayButton(
        systemName: String,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.neon)
                .padding(12)
                .background(Color.black.opacity(0.55))
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.neon.opacity(0.9), lineWidth: 1.5)
                )
        }
        .accessibilityLabel(label)
    }

    private func triggerSuccessHaptic() {
        guard playbackSettings.mode.allowsHaptics else { return }
#if canImport(UIKit)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
#endif
    }

    private var topStatusRow: some View {
        HStack(alignment: .top, spacing: contentCardSpacing) {
            dashboardButton(card: .rank) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(red: 0.97, green: 0.23, blue: 0.20), Color(red: 1.0, green: 0.88, blue: 0.12)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            Circle()
                                .stroke(Color.neon, lineWidth: 4)
                                .padding(1)
                            Image("Icon")
                                .resizable()
                                .scaledToFit()
                                .padding(8)
                        }
                        .frame(width: 72, height: 72)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Rank: Field Operative")
                                .font(.system(size: 15, weight: .heavy, design: .rounded))
                                .foregroundStyle(Color.white.opacity(0.95))
                            Text("LVL: \(userProgress.level)")
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .foregroundStyle(Color.white.opacity(0.95))
                        }

                        Spacer(minLength: 0)
                    }

                    expBar
                }
                .padding(16)
            } destination: {
                flashCard(.rank) {
                    path.append(.journeyResume)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 148)

            dashboardButton(card: .leaderboard) {
                VStack(spacing: 10) {
                    Spacer(minLength: 0)
                    Image(systemName: "trophy.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .foregroundStyle(.neon)
                        .shadow(color: Color.neon.opacity(0.25), radius: 10)
                    Text("Leaderboard")
                        .font(.custom("berkelium bitmap", size: 10))
                        .foregroundStyle(Color.neon.opacity(0.92))
                    Spacer(minLength: 0)
                }
            } destination: {
                flashCard(.leaderboard) {
                    path.append(.leaderboard)
                }
            }
            .frame(width: 122)
            .frame(height: 124)
            .padding(.top, 28)
        }
    }
    
    private var expBar: some View {
        GeometryReader { proxy in
            let width = max(proxy.size.width, 1)
            let fillWidth = max(42, width * progressFraction)
            
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(red: 0.09, green: 0.21, blue: 0.31).opacity(0.96))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.neon.opacity(0.32), lineWidth: 2)
                    )
                
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.neon)
                    .frame(width: fillWidth)
                
                HStack(spacing: 5) {
                    ForEach(0..<10, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .stroke(Color(red: 0.20, green: 0.33, blue: 0.45), lineWidth: 1)
                            .background(
                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                    .fill(Color.clear)
                            )
                            .frame(height: 22)
                            .opacity(index < Int((progressFraction * 10).rounded(.down)) ? 0 : 1)
                    }
                }
                .padding(.horizontal, 10)
            }
        }
        .frame(height: 34)
    }
    
    private var dailyMissionCard: some View {
        VStack(spacing: 18) {
            cardTitle("Daily Intercept")

            Text(dailyMissionSummary)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.96))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 18)

            Button {
                flashCard(.daily) {
                    path.append(.daily)
                }
            } label: {
                Text(dailyViewModel.isSolved ? "Mission Complete" : "Start Mission")
                    .font(.custom("berkelium bitmap", size: 28))
                    .foregroundStyle(.neon)
                    .shadow(color: Color.black.opacity(0.75), radius: 1)
                    .minimumScaleFactor(0.7)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.neon.opacity(0.12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.neon, lineWidth: 2)
                            )
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 14)
        .background(cardBackground(for: .daily))
        .frame(height: 320)
    }
    
    private var journeyCard: some View {
        VStack(spacing: 18) {
            journeyCardTitle

            GeometryReader { proxy in
                let points = journeyPoints(in: proxy.size)

                ZStack {
                    journeyConnectorPath(in: proxy.size)
                        .stroke(
                            Color.neon,
                            style: StrokeStyle(lineWidth: 5, lineCap: .round, dash: [10, 9])
                        )
                        .opacity(0.95)

                    ForEach(Array(visibleJourneyLevels.enumerated()), id: \.element) { index, level in
                        let point = points[index]

                        if userProgress.isLevelUnlocked(level) {
                            Button(action: {
                                flashCard(.journey) {
                                    path.append(.journeyLevel(level))
                                }
                            }) {
                                journeyNode(level)
                            }
                            .buttonStyle(.plain)
                            .position(point)
                        } else {
                            journeyNode(level)
                                .position(point)
                        }
                    }
                }
            }
            .frame(height: 220)
            
            Button(action: {
                flashCard(.journey) {
                    path.append(.journeyResume)
                }
            }) {
                Text("Start Level \(currentJourneyLevel)")
                    .font(.custom("berkelium bitmap", size: 22))
                    .foregroundStyle(Color.neon)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.neon.opacity(0.12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.neon, lineWidth: 2)
                            )
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 22)
        .padding(.horizontal, 16)
        .background(cardBackground(for: .journey))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .frame(height: 360)
    }
    
    private var warehouseCard: some View {
        dashboardButton(card: .warehouse) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.neon)
                        .frame(width: 42, height: 42)
                    Image(systemName: "archivebox.fill")
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(Color(red: 0.06, green: 0.19, blue: 0.27))
                }

                Text("Enter Warehouse")
                    .font(.custom("berkelium bitmap", size: 20))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 20)
        } destination: {
            flashCard(.warehouse) {
                path.append(.warehouse)
            }
        }
        .frame(height: 106)
    }
    
    private var dailyMissionSummary: String {
        if dailyViewModel.isSolved {
            return "Today's intercept has been decrypted. Re-open the file and review the solved signal."
        }
        return "Incoming signal detected. Your daily objective is ready. Initiate decryption?"
    }
    
    private var morsePrompt: String {
        let clue = dailyViewModel.morseClue.trimmingCharacters(in: .whitespacesAndNewlines)
        return clue.isEmpty ? "..." : clue
    }
    
    private func dashboardButton<Label: View>(
        card: HomeCard? = nil,
        @ViewBuilder _ label: () -> Label,
        destination: @escaping () -> Void
    ) -> some View {
        Button(action: destination) {
            label()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(cardBackground(for: card))
        }
        .buttonStyle(.plain)
    }
    
    private func cardBackground(for card: HomeCard?) -> some View {
        let isFlashing = card != nil && card == flashingCard
        let fillColor = isFlashing
            ? Color(red: 0.82, green: 0.16, blue: 0.16).opacity(0.96)
            : Color(red: 0.08, green: 0.17, blue: 0.24).opacity(0.94)
        let strokeColor = isFlashing ? Color.red.opacity(0.95) : Color.neon

        return RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(fillColor)
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(strokeColor, lineWidth: 2.8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    .padding(6)
            )
            .shadow(color: strokeColor.opacity(isFlashing ? 0.24 : 0.12), radius: 12)
            .animation(.easeInOut(duration: 0.12), value: isFlashing)
    }

    private func flashCard(_ card: HomeCard, action: @escaping () -> Void) {
        flashingCard = card

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            action()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
            if flashingCard == card {
                flashingCard = nil
            }
        }
    }
    
    private func cardTitle(
        _ text: String,
        maxWidth: CGFloat = 305,
        horizontalPadding: CGFloat = 46,
        imageHorizontalPadding: CGFloat = 0,
        imageScale: CGFloat = 1
    ) -> some View {
        ZStack {
            Image("Header")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: maxWidth)
                .opacity(0.96)
                .padding(.horizontal, imageHorizontalPadding)
                .scaleEffect(imageScale)

            Text(text)
                .font(.custom("berkelium bitmap", size: 18))
                .foregroundStyle(.white)
                .shadow(color: Color.black.opacity(0.85), radius: 1)
                .padding(.horizontal, horizontalPadding)
                .padding(.bottom, 4)
        }
    }

    private var journeyCardTitle: some View {
        ZStack {
            Image("Header")
                .resizable()
                .scaledToFit()
                .frame(width: 315, height: 78)
                .opacity(0.96)

            Text("Agents Journey")
                .font(.custom("berkelium bitmap", size: 18))
                .foregroundStyle(.white)
                .shadow(color: Color.black.opacity(0.85), radius: 1)
                .padding(.horizontal, 42)
                .padding(.bottom, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, -8)
    }
    
    private func journeyConnectorPath(in size: CGSize) -> Path {
        Path { path in
            let points = journeyPoints(in: size)
            guard points.count == 5 else { return }

            let p1 = points[0]
            let p2 = points[1]
            let p3 = points[2]
            let p4 = points[3]
            let p5 = points[4]
            let exitPoint = CGPoint(x: size.width * 0.18, y: size.height - 20)
            let arrowPoint = CGPoint(x: exitPoint.x + 14, y: exitPoint.y + 14)

            path.move(to: p1)
            path.addLine(to: p2)
            path.addLine(to: p3)
            path.addCurve(
                to: p4,
                control1: CGPoint(x: p3.x + (size.width * 0.14), y: p3.y + 26),
                control2: CGPoint(x: p4.x + (size.width * 0.24), y: p4.y - 24)
            )
            path.addLine(to: p5)
            path.addCurve(
                to: exitPoint,
                control1: CGPoint(x: p5.x - (size.width * 0.28), y: p5.y + 6),
                control2: CGPoint(x: size.width * 0.06, y: p5.y + 40)
            )
            path.addLine(to: arrowPoint)
            path.move(to: CGPoint(x: exitPoint.x - 6, y: exitPoint.y - 4))
            path.addLine(to: arrowPoint)
            path.addLine(to: CGPoint(x: arrowPoint.x - 11, y: arrowPoint.y))
        }
    }
    
    private func journeyPoints(in size: CGSize) -> [CGPoint] {
        let insetX = max(40, size.width * 0.14)
        let topY = size.height * 0.34
        let bottomY = size.height * 0.74
        let topSpacing = (size.width - (insetX * 2)) / 2

        return [
            CGPoint(x: insetX, y: topY),
            CGPoint(x: insetX + topSpacing, y: topY),
            CGPoint(x: size.width - insetX, y: topY),
            CGPoint(x: size.width - insetX, y: bottomY),
            CGPoint(x: insetX, y: bottomY)
        ]
    }
    
    private func journeyNode(_ level: Int) -> some View {
        let unlocked = userProgress.isLevelUnlocked(level)
        let active = currentJourneyLevel == level
        
        return ZStack {
            Image("Tab")
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .frame(width: 78, height: 78)
                .foregroundStyle(unlocked ? Color.neon : Color.white.opacity(0.18))
                .shadow(color: unlocked ? Color.neon.opacity(active ? 0.55 : 0.28) : .clear, radius: 12)

            Text("\(level)")
                .font(.custom("berkelium bitmap", size: 24))
                .foregroundStyle(Color.black)
        }
    }
}

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public struct DigitalRainBackground: View {
        // Tunables
        public var speed: Double = 60          // points per second
        public var density: Int = 12           // approximate number of columns
        public var glyphSize: CGFloat = 18     // font size for glyphs
        public var randomize: Bool = true      // randomize stream timing
        public var isPaused: Bool = false

        public init(speed: Double = 60, density: Int = 12, glyphSize: CGFloat = 18, randomize: Bool = true, isPaused: Bool = false) {
            self.speed = speed
            self.density = max(6, density)
            self.glyphSize = glyphSize
            self.randomize = randomize
            self.isPaused = isPaused
        }

        public var body: some View {
            GeometryReader { proxy in
                let columns = max(6, density)
                let columnWidth = max(glyphSize, proxy.size.width / CGFloat(columns))
                let count = Int(ceil(proxy.size.width / columnWidth))

                ZStack {
                    Color.black.ignoresSafeArea()

                    HStack(spacing: 0) {
                        ForEach(0..<count, id: \.self) { idx in
                            RainColumn(height: proxy.size.height,
                                       columnWidth: columnWidth,
                                       speed: speed,
                                       glyphSize: glyphSize,
                                       jitterSeed: randomize ? UInt64(idx) : 0,
                                       isPaused: isPaused)
                                .frame(width: columnWidth, height: proxy.size.height)
                        }
                    }
                    .accessibilityHidden(true)
                    .drawingGroup(opaque: true)
                }
            }
        }
    }
            
            private func mapRequestedView(_ view: String) -> AppDestination? {
                // Converts strings into enum values
                switch view {
                case "Daily":
                    return .daily
                case "Warehouse":
                    return .warehouse
                case "Agents Journey":
                    return .journeyResume
                default:
                    return nil
                }
            }


@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
private struct RainColumn: View {
    let height: CGFloat
    let columnWidth: CGFloat
    let speed: Double
    let glyphSize: CGFloat
    let jitterSeed: UInt64
    let isPaused: Bool
    
    private var glyphs: [String] {
        // A set of katakana-like symbols and digits to evoke the look
        let chars = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
        let len = Int(ceil((height / glyphSize) * 1.5))
        // Seeded RNG for stable per-column glyphs (split to help the type-checker)
        let seedMultiplier: UInt64 = 0x9E3779B97F4A7C15
        let combinedSeed: UInt64 = jitterSeed &* seedMultiplier
        var seeded = SeededGenerator(seed: combinedSeed)
        var results: [String] = []
        results.reserveCapacity(len)
        for _ in 0..<len {
            if let ch = chars.randomElement(using: &seeded) {
                results.append(String(ch))
            } else {
                results.append("0")
            }
        }
        return results
    }
    
    @ViewBuilder
    var body: some View {
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *), !isPaused {
            RainColumnAnimated(height: height,
                               columnWidth: columnWidth,
                               speed: speed,
                               glyphSize: glyphSize,
                               jitterSeed: jitterSeed,
                               glyphs: glyphs)
        } else {
            RainColumnStatic(height: height,
                             columnWidth: columnWidth,
                             speed: speed,
                             glyphSize: glyphSize,
                             jitterSeed: jitterSeed,
                             glyphs: glyphs)
        }
    }

    private struct RainColumnStatic: View {
        let height: CGFloat
        let columnWidth: CGFloat
        let speed: Double
        let glyphSize: CGFloat
        let jitterSeed: UInt64
        let glyphs: [String]

        var body: some View {
            Canvas(rendersAsynchronously: true) { ctx, _ in
                let safeGlyphs = glyphs.isEmpty ? ["0"] : glyphs
                let dt = 0.0

                let baseSpeed = max(10.0, speed)
                let jitter = jitterSeed == 0 ? 0.0 : Double(jitterSeed % 100) / 100.0
                let speedPS = baseSpeed * (1.0 + jitter * 0.5)
                let step = glyphSize * 1.05
                let rowCount = max(1, Int(ceil(height / step)) + 3)
                let dropCount = max(1, min(3, rowCount / 14))
                let font = Font.system(size: glyphSize, design: .monospaced)
                var drewGlyph = false

                for row in 0..<rowCount {
                    let y = CGFloat(row) * step
                    guard y > -glyphSize && y < height + glyphSize else { continue }

                    var opacity: Double = 0
                    var glyphIndex = row

                    for drop in 0..<dropCount {
                        let dropSeed = jitterSeed &+ UInt64(drop &* 977)
                        let spacing = Double(rowCount) / Double(dropCount)
                        let cycleRows = Double(rowCount) + spacing * 2.0
                        let trailLength = max(6.0, floor(Double(rowCount) * (0.18 + stableNoise(dropSeed, 11, 23) * 0.22)))
                        let dropOffset = stableNoise(dropSeed, 17, 41) * cycleRows
                        let head = (dt * speedPS / Double(step) + dropOffset).truncatingRemainder(dividingBy: cycleRows)
                        let distance = head - Double(row)
                        let wrappedDistance = distance >= 0 ? distance : distance + cycleRows
                        guard wrappedDistance >= 0 && wrappedDistance <= trailLength else { continue }

                        let gapNoise = stableNoise(dropSeed, UInt64(row), UInt64(Int(dt * 9.0) + drop * 13))
                        let isHead = wrappedDistance < 0.75
                        let shouldDraw = isHead || gapNoise > 0.28
                        guard shouldDraw else { continue }

                        let trailProgress = 1.0 - (wrappedDistance / max(trailLength, 1.0))
                        let candidateOpacity = isHead
                            ? 1.0
                            : max(0.12, trailProgress * trailProgress * 0.85)

                        if candidateOpacity > opacity {
                            opacity = candidateOpacity
                            glyphIndex = positiveModulo(Int(floor(head)) - row + row + drop * 7, safeGlyphs.count)
                        }
                    }

                    guard opacity > 0 else { continue }
                    drewGlyph = true

                    let glyph = safeGlyphs[glyphIndex]
                    let text = Text(glyph).font(font)
                    var resolved = ctx.resolve(text)
                    resolved.shading = .color(opacity > 0.92 ? .white : .green)

                    var drawContext = ctx
                    drawContext.opacity = opacity
                    drawContext.draw(resolved, at: CGPoint(x: columnWidth * 0.5, y: y))
                }

                if !drewGlyph {
                    let fallbackIndex = positiveModulo(Int(dt * speedPS / Double(step)), safeGlyphs.count)
                    let text = Text(safeGlyphs[fallbackIndex]).font(font)
                    var resolved = ctx.resolve(text)
                    resolved.shading = .color(.green)

                    var drawContext = ctx
                    drawContext.opacity = 0.45
                    drawContext.draw(resolved, at: CGPoint(x: columnWidth * 0.5, y: height * 0.5))
                }
            }
        }
    }
    
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    private struct RainColumnAnimated: View {
        let height: CGFloat
        let columnWidth: CGFloat
        let speed: Double
        let glyphSize: CGFloat
        let jitterSeed: UInt64
        let glyphs: [String]
        
        var body: some View {
            TimelineView<AnimationTimelineSchedule, AnyView>(.animation) { context in
                AnyView(
                    Canvas(rendersAsynchronously: true) { ctx, _ in
                        let safeGlyphs = glyphs.isEmpty ? ["0"] : glyphs

                        let dt = context.date.timeIntervalSinceReferenceDate

                        let baseSpeed = max(10.0, speed)
                        let jitter = jitterSeed == 0 ? 0.0 : Double(jitterSeed % 100) / 100.0
                        let speedPS = baseSpeed * (1.0 + jitter * 0.5)
                        let step = glyphSize * 1.05
                        let rowCount = max(1, Int(ceil(height / step)) + 3)
                        let dropCount = max(1, min(3, rowCount / 14))
                        let font = Font.system(size: glyphSize, design: .monospaced)
                        var drewGlyph = false

                        for row in 0..<rowCount {
                            let y = CGFloat(row) * step
                            guard y > -glyphSize && y < height + glyphSize else { continue }

                            var opacity: Double = 0
                            var glyphIndex = row

                            for drop in 0..<dropCount {
                                let dropSeed = jitterSeed &+ UInt64(drop &* 977)
                                let spacing = Double(rowCount) / Double(dropCount)
                                let cycleRows = Double(rowCount) + spacing * 2.0
                                let trailLength = max(6.0, floor(Double(rowCount) * (0.18 + stableNoise(dropSeed, 11, 23) * 0.22)))
                                let dropOffset = stableNoise(dropSeed, 17, 41) * cycleRows
                                let head = (dt * speedPS / Double(step) + dropOffset).truncatingRemainder(dividingBy: cycleRows)
                                let distance = head - Double(row)
                                let wrappedDistance = distance >= 0 ? distance : distance + cycleRows
                                guard wrappedDistance >= 0 && wrappedDistance <= trailLength else { continue }

                                let gapNoise = stableNoise(dropSeed, UInt64(row), UInt64(Int(dt * 9.0) + drop * 13))
                                let isHead = wrappedDistance < 0.75
                                let shouldDraw = isHead || gapNoise > 0.28
                                guard shouldDraw else { continue }

                                let trailProgress = 1.0 - (wrappedDistance / max(trailLength, 1.0))
                                let candidateOpacity = isHead
                                    ? 1.0
                                    : max(0.12, trailProgress * trailProgress * 0.85)

                                if candidateOpacity > opacity {
                                    opacity = candidateOpacity
                                    glyphIndex = positiveModulo(Int(floor(head)) - row + row + drop * 7, safeGlyphs.count)
                                }
                            }

                            guard opacity > 0 else { continue }
                            drewGlyph = true

                            let glyph = safeGlyphs[glyphIndex]

                            let text = Text(glyph).font(font)
                            var resolved = ctx.resolve(text)
                            resolved.shading = .color(opacity > 0.92 ? .white : .green)

                            var drawContext = ctx
                            drawContext.opacity = opacity
                            drawContext.draw(resolved, at: CGPoint(x: columnWidth * 0.5, y: y))
                        }

                        if !drewGlyph {
                            let fallbackIndex = positiveModulo(Int(dt * speedPS / Double(step)), safeGlyphs.count)
                            let text = Text(safeGlyphs[fallbackIndex]).font(font)
                            var resolved = ctx.resolve(text)
                            resolved.shading = .color(.green)

                            var drawContext = ctx
                            drawContext.opacity = 0.45
                            drawContext.draw(resolved, at: CGPoint(x: columnWidth * 0.5, y: height * 0.5))
                        }
                    }
                )
            }
        }
    }
}

fileprivate struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { self.state = seed == 0 ? 0xCBF29CE484222325 : seed }
    mutating func next() -> UInt64 {
        // xorshift64*
        var x = state
        x ^= x >> 12
        x ^= x << 25
        x ^= x >> 27
        state = x
        return x &* 2685821657736338717
    }
}

fileprivate func stableNoise(_ a: UInt64, _ b: UInt64, _ c: UInt64) -> Double {
    var value = a &+ 0x9E3779B97F4A7C15
    value ^= b &+ 0xBF58476D1CE4E5B9
    value ^= c &+ 0x94D049BB133111EB
    value ^= value >> 30
    value &*= 0xBF58476D1CE4E5B9
    value ^= value >> 27
    value &*= 0x94D049BB133111EB
    value ^= value >> 31
    let bucket = value & 0xFFFF
    return Double(bucket) / Double(0xFFFF)
}

fileprivate func positiveModulo(_ value: Int, _ modulus: Int) -> Int {
    let remainder = value % modulus
    return remainder >= 0 ? remainder : remainder + modulus
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

#Preview {
    ContentView()
        .environmentObject(MorseEngine())
        .environmentObject(UserProgress())
        .environmentObject(PlaybackSettings())
        .environment(\.isInOnboarding, false)
}
