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
    case academy
    case warehouse
}

struct ContentView: View {
    @StateObject private var morseEngine = MorseEngine()
    // Manages Morse code logic
    @EnvironmentObject var userProgress: UserProgress
    // Shared global data
    
    @StateObject private var connectivity = MorseModePhoneConnectivity.shared
    // Connects phone to watch
    @State private var path = NavigationPath()
    
    // Set Environment(\.isInOnboarding) = true from your Onboarding view to disable watch-driven navigation while onboarding is active.
    @State private var isInOnboarding: Bool = false

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 18) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.black.opacity(0.72))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.green.opacity(0.28), lineWidth: 1)
                        )
                        .shadow(color: Color.green.opacity(0.12), radius: 12)

                    Image("Level")
                        .resizable()
                        .scaledToFit()
                        .font(.largeTitle)
                        .opacity(0.92)

                    Image("Icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 78)
                        .offset(x: -74, y: 0)

                    Text("Level: \(userProgress.level)")
                        .font(.custom("Berkelium Bitmap", size: 18))
                        .bold()
                        .foregroundStyle(.neon)
                        .offset(x: 24)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 92)

                NavigationLink(destination: Daily()) {
                    headerButton(title: "The Daily Intercept")
                }

                NavigationLink(destination: Learn2()) {
                    headerButton(title: "Agency Academy", fontSize: 24)
                }

                NavigationLink(destination: Practice(morseEngine: MorseEngine(), letter: .a)) {
                    headerButton(title: "The Warehouse", fontSize: 24)
                }
            }
            .frame(maxWidth: 420)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding()
            .background {
                ZStack {
                    if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                        DigitalRainBackground()
                    } else {
                        Color.black
                    }
                }
                .ignoresSafeArea()
            }
            .onReceive(connectivity.$requestedView.compactMap { $0 }) { requested in
                // If onboarding is active, ignore watch-driven navigation changes.
                guard !isInOnboarding else {
                    DispatchQueue.main.async { connectivity.requestedView = nil }
                    return
                }

                if let destination = mapRequestedView(requested) {
                    // Pop to root first so all screens return to ContentView.
                    path = NavigationPath()
                    // Then navigate to the requested destination from root.
                    path.append(destination)
                    DispatchQueue.main.async {
                        connectivity.requestedView = nil
                    }
                } else {
                    print("Unknown requested view: \(requested)")
                }
            }
            .navigationDestination(for: AppDestination.self) { destination in
                switch destination {
                case .daily:
                    Daily()
                case .academy:
                    Learn2()
                case .warehouse:
                    Practice(morseEngine: MorseEngine(), letter: .a)
                }
            }
            .toolbarBackground(.black.opacity(0.35), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        // Propagate onboarding flag so onboarding screens can opt out of watch-driven navigation.
        .environment(\.isInOnboarding, isInOnboarding)
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func headerButton(title: String, fontSize: CGFloat = 22) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.78))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.green.opacity(0.24), lineWidth: 1)
                )
                .shadow(color: Color.green.opacity(0.1), radius: 10)

            Image("Header")
                .resizable()
                .scaledToFit()
                .opacity(0.92)

            Text(title)
                .font(.custom("berkelium bitmap", size: fontSize))
                .foregroundStyle(.neon)
                .shadow(color: Color.black.opacity(0.85), radius: 1)
        }
        .compositingGroup()
        .frame(maxWidth: .infinity)
        .frame(height: 96)
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public struct DigitalRainBackground: View {
        // Tunables
        public var speed: Double = 60          // points per second
        public var density: Int = 20         // approximate number of columns
        public var glyphSize: CGFloat = 20     // font size for glyphs
        public var randomize: Bool = true      // randomize stream timing

        public init(speed: Double = 60, density: Int = 24, glyphSize: CGFloat = 16, randomize: Bool = true) {
            self.speed = speed
            self.density = max(6, density)
            self.glyphSize = glyphSize
            self.randomize = randomize
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
                                       jitterSeed: randomize ? UInt64(idx) : 0)
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
                case "Agency Academy":
                    return .academy
                case "Warehouse":
                    return .warehouse
                default:
                    return nil
                }
            }
            private func replayHaptics() {
                // Triggers haptic feedback
#if canImport(UIKit)
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
#endif
            }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
private struct RainColumn: View {
    let height: CGFloat
    let columnWidth: CGFloat
    let speed: Double
    let glyphSize: CGFloat
    let jitterSeed: UInt64
    
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
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            RainColumnAnimated(height: height,
                               columnWidth: columnWidth,
                               speed: speed,
                               glyphSize: glyphSize,
                               jitterSeed: jitterSeed,
                               glyphs: glyphs)
        } else {
            Rectangle()
                .fill(Color.black)
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
                        let dropCount = max(2, min(5, rowCount / 10))
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
        .environmentObject(UserProgress())
        .environment(\.isInOnboarding, false)
}

