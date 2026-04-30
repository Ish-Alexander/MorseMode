//
//  Daily.swift
//  MorseMode
//
//  Created by Ishauna Marie Alexander on 1/27/26.
//

import SwiftUI
import WatchConnectivity
import Combine
import AVFoundation

#if canImport(UIKit)
import UIKit
#endif

#if canImport(CoreHaptics)
import CoreHaptics
#endif

// Simple Morse code encoder
private let morseMap: [Character: String] = [
    "A": ".-",   "B": "-...", "C": "-.-.", "D": "-..",  "E": ".",
    "F": "..-.", "G": "--.",  "H": "....", "I": "..",   "J": ".---",
    "K": "-.-",  "L": ".-..", "M": "--",   "N": "-.",  "O": "---",
    "P": ".--.","Q": "--.-", "R": ".-.",  "S": "...",  "T": "-",
    "U": "..-",  "V": "...-", "W": ".--",  "X": "-..-", "Y": "-.--",
    "Z": "--.."
]

fileprivate func encodeMorse(_ text: String) -> String {
    text.uppercased().map { ch -> String in
        if ch == " " { return "/" }
        return morseMap[ch] ?? ""
    }.joined(separator: " ")
    // Converts text to uppercase, looks up the morse code, and joins everything together
}

private func displayMorseClue(_ morse: String) -> String {
    let wordJoiner = "\u{2060}"

    return morse
        .split(separator: " ", omittingEmptySubsequences: false)
        .map { token in
            let value = String(token)
            guard value.count > 1 else { return value }
            return value.map(String.init).joined(separator: wordJoiner)
        }
        .joined(separator: " ")
}

private struct MorseClueToken: Identifiable {
    let id: Int
    let text: String
    let isSpace: Bool
}

private struct MorseClueFlowLayout: Layout {
    var horizontalSpacing: CGFloat = 10
    var verticalSpacing: CGFloat = 10

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let maxWidth = proposal.width ?? .greatestFiniteMagnitude
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }

        var lineWidth: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalWidth: CGFloat = 0
        var totalHeight: CGFloat = 0

        for size in sizes {
            let nextWidth = lineWidth == 0 ? size.width : lineWidth + horizontalSpacing + size.width
            if nextWidth > maxWidth, lineWidth > 0 {
                totalWidth = max(totalWidth, lineWidth)
                totalHeight += lineHeight + verticalSpacing
                lineWidth = size.width
                lineHeight = size.height
            } else {
                lineWidth = nextWidth
                lineHeight = max(lineHeight, size.height)
            }
        }

        totalWidth = max(totalWidth, lineWidth)
        totalHeight += lineHeight

        return CGSize(width: totalWidth, height: totalHeight)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        var x = bounds.minX
        var y = bounds.minY
        var lineHeight: CGFloat = 0

        for (index, subview) in subviews.enumerated() {
            let size = sizes[index]
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += lineHeight + verticalSpacing
                lineHeight = 0
            }

            subview.place(
                at: CGPoint(x: x, y: y),
                anchor: .topLeading,
                proposal: ProposedViewSize(width: size.width, height: size.height)
            )

            x += size.width + horizontalSpacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

struct DailyRoot: View {
    @ObservedObject var vm: DailyMorseViewModel
    @State private var showDaily: Bool = false

    var body: some View {
        Group {
            if showDaily {
                Daily(vm: vm)
                    .transition(.opacity)
            } else {
                // If today's puzzle is already solved, skip the intro immediately
                if vm.isSolved || UserDefaults.standard.bool(forKey: "dailySolved_\(currentDateKey())") {
                    Daily(vm: vm)
                        .transition(.opacity)
                } else {
                    DailyIntroLoadingView {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            showDaily = true
                        }
                    }
                    .transition(.opacity)
                }
            }
        }
        .animation(.easeInOut, value: showDaily)
    }
}

private func currentDateKey() -> String {
    let cal = Calendar(identifier: .gregorian)
    let startOfDay = cal.startOfDay(for: Date())
    let formatter = DateFormatter()
    formatter.calendar = cal
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: startOfDay)
}

final class DailyMorseViewModel: ObservableObject {
    // Updates screen automatically
    
    // Persistence keys per daily word

    // Use a date-based suffix so repeats of the same word on different days are playable again
    private var todayKeySuffix: String {
        let cal = Calendar(identifier: .gregorian)
        let startOfDay = cal.startOfDay(for: Date())
        let formatter = DateFormatter()
        formatter.calendar = cal
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: startOfDay)
    }

    private var timeKey: String { "dailyTimeRemaining_\(todayKeySuffix)" }
    private var wrongKey: String { "dailyWrongGuesses_\(todayKeySuffix)" }
    private var revealedKey: String { "dailyRevealed_\(todayKeySuffix)" }
    private var lastSavedAtKey: String { "dailyLastSavedAt_\(todayKeySuffix)" }
    private var activeKey: String { "dailyIsActive_\(todayKeySuffix)" }
    private var completionTimeKey: String { "dailyCompletionTime_\(todayKeySuffix)" }

    private func saveTimeRemaining() {
        UserDefaults.standard.set(timeRemaining, forKey: timeKey)
    }

    private func loadTimeRemaining() -> Int? {
        let value = UserDefaults.standard.integer(forKey: timeKey)
        // integer(forKey:) returns 0 if missing; distinguish missing by checking object(forKey:)
        if UserDefaults.standard.object(forKey: timeKey) == nil { return nil }
        return value
    }

    private func clearTimeRemaining() {
        UserDefaults.standard.removeObject(forKey: timeKey)
    }

    private func saveLastSavedAt(_ date: Date = Date()) {
        UserDefaults.standard.set(date.timeIntervalSince1970, forKey: lastSavedAtKey)
    }

    private func loadLastSavedAt() -> Date? {
        guard UserDefaults.standard.object(forKey: lastSavedAtKey) != nil else { return nil }
        let timestamp = UserDefaults.standard.double(forKey: lastSavedAtKey)
        return Date(timeIntervalSince1970: timestamp)
    }

    private func clearLastSavedAt() {
        UserDefaults.standard.removeObject(forKey: lastSavedAtKey)
    }

    private func saveIsActive() {
        UserDefaults.standard.set(isActive, forKey: activeKey)
    }

    private func loadIsActive() -> Bool? {
        guard UserDefaults.standard.object(forKey: activeKey) != nil else { return nil }
        return UserDefaults.standard.bool(forKey: activeKey)
    }

    private func clearIsActive() {
        UserDefaults.standard.removeObject(forKey: activeKey)
    }

    private func saveCompletionTime(_ seconds: Int) {
        UserDefaults.standard.set(seconds, forKey: completionTimeKey)
    }

    private func loadCompletionTime() -> Int? {
        guard UserDefaults.standard.object(forKey: completionTimeKey) != nil else { return nil }
        return UserDefaults.standard.integer(forKey: completionTimeKey)
    }

    private func saveWrongGuesses() {
        let array = Array(wrongGuesses).map { String($0) }
        UserDefaults.standard.set(array, forKey: wrongKey)
    }

    private func loadWrongGuesses() -> Set<Character> {
        guard let array = UserDefaults.standard.array(forKey: wrongKey) as? [String] else { return [] }
        return Set(array.compactMap { $0.first })
    }

    private func clearWrongGuesses() {
        UserDefaults.standard.removeObject(forKey: wrongKey)
    }
    
    private func saveRevealed() {
        let array = Array(revealed).map { String($0) }
        UserDefaults.standard.set(array, forKey: revealedKey)
    }

    private func loadRevealed() -> Set<Character> {
        guard let array = UserDefaults.standard.array(forKey: revealedKey) as? [String] else { return [] }
        return Set(array.compactMap { $0.first })
    }

    private func clearRevealed() {
        UserDefaults.standard.removeObject(forKey: revealedKey)
    }
    
    private var solvedKey: String { "dailySolved_\(todayKeySuffix)" }
    private func markSolved() {
        UserDefaults.standard.set(true, forKey: solvedKey)
        clearTimeRemaining()
        clearWrongGuesses()
        clearRevealed()
        clearLastSavedAt()
        clearIsActive()
    }
    private var isAlreadySolved: Bool {
        UserDefaults.standard.bool(forKey: solvedKey)
    }
    // Remembers if the user solved today's puzzle

    private static let dailyWordPool: [String] = [
        "SWIFT", "APPLE", "MORSE", "CODE", "WATCH", "SIGNAL", "XCODE", "DECODE",
        "BITMAP", "NEON", "HAPTIC", "VIBRATE", "DOT", "DASH", "PUZZLE", "SECRET",
        "RADIO", "TELEGRAPH", "MESSAGE", "ENCODE", "SENDER", "RECEIVER",
        "FREQUENCY", "PATTERN", "RHYTHM", "SPEED", "TIMER", "TARGET", "LETTER",
        "BEACON", "SUNRISE", "THUNDER", "MEADOW", "CANDLE", "RIVER", "MOUNTAIN",
        "GARDEN", "LANTERN", "ORANGE", "WINTER", "SUMMER", "AUTUMN", "SPRING",
        "SHADOW", "BREEZE", "HARBOR", "MARBLE", "VELVET", "POCKET", "MARKET",
        "FOREST", "CASTLE", "SILVER", "GOLDEN", "PILLOW", "ROCKET", "CLOUD",
        "OCEAN", "DESERT", "ISLAND", "PLANET", "COMET", "GALAXY", "SATURN",
        "TUNNEL", "BRIDGE", "CIRCLE", "SPIRAL", "WINDOW", "BUTTON", "PENCIL",
        "PAPER", "COFFEE", "COOKIE", "CINNAMON", "BLOSSOM", "SUNSET", "MORNING",
        "MIDNIGHT", "SPARK", "FLAME", "CRYSTAL", "BOTTLE", "JACKET", "MIRROR",
        "BALLOON", "DRAGON", "TIGER", "RABBIT", "FALCON", "WHALE", "OTTER",
        "DOLPHIN", "PARADE", "MUSEUM", "MELODY", "GUITAR", "PIANO", "POETRY",
        "STUDIO", "VOYAGE", "JOURNEY", "HORIZON", "TRAIL", "CANYON", "GLACIER",
        "PRAIRIE", "WATERFALL", "RAINBOW", "TROPHY", "ANCHOR", "COMPASS", "PICNIC",
        "POPCORN", "CAMPFIRE", "NOTEBOOK", "KITCHEN", "VILLAGE", "LIBRARY", "THEATER"
    ]

    private static let dailyWords: [String] = {
        var seen: Set<String> = []
        return dailyWordPool.filter { seen.insert($0).inserted }
    }()

    private static func dailyIndex(for date: Date = Date()) -> Int {
        let cal = Calendar(identifier: .gregorian)
        let startOfDay = cal.startOfDay(for: date)
        let daysSinceRef = cal.dateComponents([.day], from: Date(timeIntervalSince1970: 0), to: startOfDay).day ?? 0
        return abs(daysSinceRef) % max(1, dailyWords.count)
        
    }

    static func wordForToday(on date: Date = Date()) -> String {
        dailyWords[dailyIndex(for: date)]
        //Picks one word for the day, makes that word the same for everyone
    }

    static func completionSecondsForToday() -> Int? {
        let cal = Calendar(identifier: .gregorian)
        let startOfDay = cal.startOfDay(for: Date())
        let formatter = DateFormatter()
        formatter.calendar = cal
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        let suffix = formatter.string(from: startOfDay)
        let key = "dailyCompletionTime_\(suffix)"
        guard UserDefaults.standard.object(forKey: key) != nil else { return nil }
        return UserDefaults.standard.integer(forKey: key)
    }

    @Published var targetWord: String
    @Published var revealed: Set<Character> = []
    @Published var wrongGuesses: Set<Character> = []
    @Published var timeRemaining: Int = 180 // 3 minutes
    @Published var isActive: Bool = true
// Updates UI when changes are made
    
    private var timer: Timer?

    private func persistGameplayState(at date: Date = Date()) {
        saveTimeRemaining()
        saveWrongGuesses()
        saveRevealed()
        saveIsActive()
        saveLastSavedAt(date)
    }

    private func restoreElapsedTimeIfNeeded(referenceDate: Date = Date()) {
        if let restoredTime = loadTimeRemaining() {
            timeRemaining = restoredTime
        }

        if let wasActive = loadIsActive() {
            isActive = wasActive && timeRemaining > 0
        } else {
            isActive = false
        }

        saveTimeRemaining()
        saveIsActive()
        saveLastSavedAt(referenceDate)
    }

    init(word: String = "") {
        self.targetWord = (word.isEmpty ? Self.wordForToday() : word).uppercased()
        if isAlreadySolved {
            // Reveal all unique letters and keep game inactive
            revealed = Set(targetWord.filter { $0 != " " })
            saveRevealed()
            isActive = false
            timeRemaining = 180
            if let completionTime = loadCompletionTime() {
                timeRemaining = max(0, 180 - completionTime)
            }
            // Clear any leftover persisted state for a solved day
            clearTimeRemaining()
            clearWrongGuesses()
            clearLastSavedAt()
            clearIsActive()
        } else {
            // Try to restore persisted progress for this day's word
            let restoredTime = loadTimeRemaining()
            let restoredWrong = loadWrongGuesses()
            if let t = restoredTime, t > 0 {
                timeRemaining = t
            } else {
                timeRemaining = 180
            }
            wrongGuesses = restoredWrong
            revealed = loadRevealed()
            isActive = loadIsActive() ?? false // start after intro haptics
            restoreElapsedTimeIfNeeded()
        }
    }

    deinit {
        persistGameplayState()
        timer?.invalidate()
    }

    func startTimer() {
        timer?.invalidate()
        isActive = true
        persistGameplayState()
        // timeRemaining = 180  // Removed this line as per instructions
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] t in
            guard let self else { return }
            if self.timeRemaining > 0 && self.isActive {
                self.timeRemaining -= 1
                self.persistGameplayState()
            } else {
                t.invalidate()
                self.isActive = false
                self.persistGameplayState()
                // Runs the timer
            }
        }
    }

    func syncStateForScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .active:
            restoreElapsedTimeIfNeeded()
            if isActive && timeRemaining > 0 && timer == nil {
                startTimer()
            }
        case .inactive, .background:
            timer?.invalidate()
            timer = nil
            persistGameplayState()
        @unknown default:
            persistGameplayState()
        }
    }

    var morseClue: String {
        encodeMorse(targetWord)
        // Converts the target word into Morse Code
    }

    var displayBlanks: String {
        // Underscores for unrevealed letters, keeps spaces
        targetWord.map { ch -> String in
            if ch == " " { return "  " }
            return revealed.contains(ch) ? String(ch) : "_"
        }.joined(separator: " ")
    }
// Includes underscores for unguessed letters
    
    var isSolved: Bool {
        targetWord.allSatisfy { $0 == " " || revealed.contains($0) }
    }

    func guess(_ letter: Character) {
        let upper = Character(String(letter).uppercased())
        guard isActive, timeRemaining > 0, upper.isLetter else { return }
        if targetWord.contains(upper) {
            revealed.insert(upper)
            saveRevealed()
        } else {
            wrongGuesses.insert(upper)
            saveWrongGuesses()
        }
        saveLastSavedAt()
        // Adds letters to "Revealed" and "Wrong Guess" lines
        if isSolved {
            isActive = false
            timer?.invalidate()
            timer = nil
            let completionSeconds = max(0, 180 - timeRemaining)
            saveCompletionTime(completionSeconds)
            NotificationCenter.default.post(
                name: .dailyInterceptCompleted,
                object: nil,
                userInfo: ["seconds": completionSeconds]
            )
            markSolved()
            clearTimeRemaining()
            clearWrongGuesses()
            clearRevealed()
        }
    }
}

struct Daily: View {
    @ObservedObject var vm: DailyMorseViewModel
    @EnvironmentObject private var playbackSettings: PlaybackSettings
    @EnvironmentObject private var userProgress: UserProgress
    // Game logic object
    @State private var currentGuess: String = ""
    // What the user types
    @FocusState private var isGuessFieldFocused: Bool
    @State private var isPlayingHaptics: Bool = false
    @State private var replayRotationAngle: Double = 0
    @State private var activeClueTokenID: Int? = nil
    @State private var playbackWorkItems: [DispatchWorkItem] = []
    // Prevents overlapping haptics
    @State private var audioPlayer: AVAudioPlayer? = nil
    // Plays morse code audio

#if canImport(CoreHaptics)
    @State private var hapticEngine: CHHapticEngine? = nil
#endif

    @Environment(\.scenePhase) private var scenePhase

    private var clueTokens: [MorseClueToken] {
        Array(vm.targetWord.uppercased()).enumerated().map { index, ch in
            if ch == " " {
                return MorseClueToken(id: index, text: "/", isSpace: true)
            }
            return MorseClueToken(
                id: index,
                text: displayMorseClue(morseMap[ch] ?? ""),
                isSpace: false
            )
        }
    }
    
    private func activateWatchSessionIfNeeded() {
    #if canImport(WatchConnectivity)
        // Makes sure watch and phone can communicate
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        if session.activationState != .activated {
            session.activate()
        }
    #endif
    }
    
    private func sendMorseToWatch(_ morse: String) {
    #if canImport(WatchConnectivity)
        MorseModePhoneConnectivity.shared.sendWatchHaptics(
            morse: morse,
            word: vm.targetWord
        )
    #endif
    }
    
    private func soundPlaybackDuration(for letter: Character) -> TimeInterval {
        guard playbackSettings.mode.allowsSound else { return 0 }
        return MorseLetterAudio.playbackDuration(for: letter)
    }

    @discardableResult
    private func playSound(for letter: Character) -> TimeInterval {
        guard playbackSettings.mode.allowsSound else {
            audioPlayer = MorseLetterAudio.stop(audioPlayer)
            return 0
        }
        let playback = MorseLetterAudio.play(
            character: letter,
            reusing: audioPlayer,
            logPrefix: "Daily"
        )
        audioPlayer = playback.player
        return playback.duration
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            GeometryReader { proxy in
                ScrollView {
                    VStack(spacing: 16) {
                        // Header / Timer
                        Text(timerString)
                            .font(.custom("berkelium bitmap", size: 36))
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(vm.timeRemaining > 10 ? .green : .red)
                            .accessibilityLabel("Time remaining: \(timerString)")
                        // Shows timer, color changes when time gets low
                        
                        ZStack{
                            Image("Tube")
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: 240)
                            VStack(spacing: 8) {
                                // Status above the clue
                                if vm.isSolved {
                                    Text("Solved! ✅")
                                        .font(.custom("berkelium bitmap", size: 16))
                                        .foregroundStyle(.neon)
                                        .transition(.opacity)
                                } else if vm.timeRemaining == 0 {
                                    Text("Time's up! The word was \(vm.targetWord)")
                                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.yellow)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(3)
                                        .minimumScaleFactor(0.7)
                                        .allowsTightening(true)
                                        .padding(.horizontal, 16)
                                        .frame(maxWidth: 200)
                                        .transition(.opacity)
                                }

                                // Morse clue below
                                MorseClueFlowLayout(horizontalSpacing: 8, verticalSpacing: 8) {
                                    ForEach(clueTokens) { token in
                                        clueTokenView(token)
                                    }
                                }
                                .frame(maxWidth: 220)
                                .padding(.horizontal, 16)
                            }
                        }
                        
                        // Hangman blanks
                        VStack(spacing: 8) {
                            Text("Decode")
                                .font(.custom("berkelium bitmap", size: 24))
                                .font(.headline)
                                .foregroundStyle(.neon.opacity(0.8))
                            Text(vm.displayBlanks)
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundStyle(.neon)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        HStack(spacing: 12) {
                            TextField(text: $currentGuess, prompt: Text("Guess a letter! (Press Enter to guess)").foregroundStyle(.black)) {
                            }
                            .textInputAutocapitalization(.characters)
                            .disableAutocorrection(true)
                            .onChange(of: currentGuess) { _, newValue in
                                let sanitized = sanitizeGuessInput(newValue)
                                if sanitized != newValue {
                                    currentGuess = sanitized
                                }
                            }
                            .foregroundStyle(.neon)
                            .tint(.white)
                            .focused($isGuessFieldFocused)
                            .padding(12)
                            .background(Color.white.opacity(0.4))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .onSubmit(submitGuess)

                            Button(action: submitGuess) {
                                Text("Guess")
                                    .font(.custom("berkelium bitmap", size: 14))
                                    .foregroundStyle(.black)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                    .background(Color.neon)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .disabled(currentGuess.isEmpty || vm.timeRemaining == 0 || vm.isSolved)
                            .opacity(currentGuess.isEmpty || vm.timeRemaining == 0 || vm.isSolved ? 0.45 : 1)
                        }
                        
                        // Wrong guesses
                        if !vm.wrongGuesses.isEmpty {
                            VStack(spacing: 6) {
                                Text("Wrong Guesses")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.7))
                                Text(vm.wrongGuesses.sorted().map(String.init).joined(separator: " "))
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundStyle(.red)
                            }
                        }
                        
                        // Controls
                        HStack(spacing: 16) {
                            Button(action: {
                                replayHaptics()
                            }) {
                                ZStack {
                                    Image("Radar")
                                        .resizable()
                                        .frame(width: 75, height: 75)
                                        .scaledToFit()
                                        .ignoresSafeArea()
                                        .rotationEffect(.degrees(replayRotationAngle))
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundStyle(.neon)
                                        .rotationEffect(.degrees(replayRotationAngle))
                                        .shadow(color: .black.opacity(0.35), radius: 2, x: 0, y: 1)
                                        .onAppear {
                                            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false).speed(0.25)) {
                                                replayRotationAngle = 360
                                            }
                                        }
                                }
                            }
                            .accessibilityLabel("Replay the Morse clue")
                            .disabled(isPlayingHaptics)
                            .opacity(isPlayingHaptics ? 0.5 : 1)
                            // Replays the morse code and haptics
                        }
                        .padding()
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: proxy.size.height, alignment: .top)
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 28)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .onAppear {
            vm.syncStateForScenePhase(.active)
            activateWatchSessionIfNeeded()
            // If today's word is already solved, don't play haptics or start timer
            if vm.isSolved {
                // Still send to watch in case it wants to show the clue
                sendMorseToWatch(vm.morseClue)
            } else {
                sendMorseToWatch(vm.morseClue)
                // Small delay to ensure layout/haptic engine readiness
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    if vm.timeRemaining > 0 { // continue the remaining time
                        replayHaptics { vm.startTimer() }
                    }
                }
            }
        }
        .onDisappear {
            vm.syncStateForScenePhase(.inactive)
            stopFeedbackPlaybackOnly()
        }
        .onReceive(NotificationCenter.default.publisher(for: .dailyInterceptCompleted)) { notification in
            let xpReward = 50
            userProgress.addEXP(xpReward)
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            vm.syncStateForScenePhase(newPhase)
            if newPhase == .inactive || newPhase == .background {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    stopFeedbackPlaybackOnly()
                }
            }
        }
    }
    
    private var timerString: String {
        let m = vm.timeRemaining / 60
        let s = vm.timeRemaining % 60
        return String(format: "%d:%02d", m, s)
    }

    private func sanitizeGuessInput(_ value: String) -> String {
        let lettersOnly = value.uppercased().filter(\.isLetter)
        return lettersOnly.isEmpty ? "" : String(lettersOnly.prefix(1))
    }

    private func submitGuess() {
        guard let ch = currentGuess.trimmingCharacters(in: .whitespacesAndNewlines).first else { return }
        vm.guess(ch)
        currentGuess = ""
        isGuessFieldFocused = false
    }
    
    private func stopFeedbackPlaybackOnly() {
#if canImport(UIKit)
        cancelPlaybackHighlights()
    #if canImport(CoreHaptics)
        hapticEngine?.stop()
    #endif
        if audioPlayer?.isPlaying == true { audioPlayer?.stop() }
        audioPlayer = nil
        isPlayingHaptics = false
#endif
    }

    @ViewBuilder
    private func clueTokenView(_ token: MorseClueToken) -> some View {
        let isActive = activeClueTokenID == token.id && !token.isSpace

        Text(token.text)
            .font(.system(size: 28, weight: .medium, design: .monospaced))
            .foregroundStyle(isActive ? Color(red: 0.9, green: 1.0, blue: 0.92) : .white)
            .padding(.horizontal, token.isSpace ? 0 : 6)
            .padding(.vertical, token.isSpace ? 0 : 4)
            .background {
                if isActive {
                    Capsule()
                        .fill(Color.green.opacity(0.34))
                        .blur(radius: 14)
                        .overlay(
                            Capsule()
                                .stroke(Color.green.opacity(0.55), lineWidth: 1)
                        )
                }
            }
            .shadow(color: isActive ? Color.green.opacity(0.95) : .clear, radius: 12)
            .animation(.easeInOut(duration: 0.12), value: isActive)
    }

    private func cancelPlaybackHighlights() {
        playbackWorkItems.forEach { $0.cancel() }
        playbackWorkItems.removeAll()
        activeClueTokenID = nil
    }
    
    private func playMorseHaptics(for morse: String, completion: @escaping () -> Void) {
#if canImport(UIKit)
        guard !isPlayingHaptics else { completion(); return }
        isPlayingHaptics = true
        cancelPlaybackHighlights()

        // Base timing unit (seconds)
        let unit: TimeInterval = 0.08
        let dot = unit
        let dash = unit * 3 // dash lasts 3x as long as dot
        let intraCharGap = unit
        let interCharGap = unit * 6 // Space between letters
        let wordGap = unit * 7 // Space between words

        // Schedule audio playback aligned to the Morse timing per letter
        // Compute the start time for each letter based on its dot/dash pattern and configured gaps.
        var audioStart: TimeInterval = 0
        let letters = Array(vm.targetWord.uppercased())
        for (i, ch) in letters.enumerated() {
            if ch == " " {
                audioStart += wordGap
                continue
            }

            // Schedule audio at the start of this letter
            let tokenID = i
            let letterStart = audioStart
            let startWorkItem = DispatchWorkItem {
                activeClueTokenID = tokenID
                if playbackSettings.mode.allowsSound {
                    playSound(for: ch)
                }
            }
            playbackWorkItems.append(startWorkItem)
            DispatchQueue.main.asyncAfter(deadline: .now() + letterStart, execute: startWorkItem)

            // Advance by the duration of this letter’s Morse pattern (symbols + intra gaps)
            if let pattern = morseMap[ch] {
                var letterDuration: TimeInterval = 0
                for (idx, sym) in pattern.enumerated() {
                    letterDuration += (sym == "-" ? dash : dot)
                    if idx < pattern.count - 1 {
                        letterDuration += intraCharGap
                    }
                }
                let highlightDuration = max(letterDuration, soundPlaybackDuration(for: ch))
                audioStart += letterDuration

                let clearWorkItem = DispatchWorkItem {
                    if activeClueTokenID == tokenID {
                        activeClueTokenID = nil
                    }
                }
                playbackWorkItems.append(clearWorkItem)
                DispatchQueue.main.asyncAfter(deadline: .now() + letterStart + highlightDuration, execute: clearWorkItem)
            }

            // Add inter-letter gap unless next is a space or end
            if i < letters.count - 1 {
                let next = letters[i + 1]
                audioStart += (next == " " ? wordGap : interCharGap)
            }
        }

        let totalPlaybackDuration = audioStart + unit

        guard playbackSettings.mode.allowsHaptics else {
            DispatchQueue.main.asyncAfter(deadline: .now() + totalPlaybackDuration) {
                cancelPlaybackHighlights()
                isPlayingHaptics = false
                completion()
            }
            return
        }

#if canImport(CoreHaptics)
        // Core Haptics path with precise durations
        var coreHapticsWorked = false
        do {
            if hapticEngine == nil {
                hapticEngine = try CHHapticEngine()
            }
            let engine = hapticEngine!
            try engine.start()

            // Build haptic events timeline
            var events: [CHHapticEvent] = []
            var relativeTime: TimeInterval = 0

            func addDot() {
                let event = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
                    ],
                    relativeTime: relativeTime
                )
                events.append(event)
                relativeTime += dot
            }

            func addDash() {
                let attack = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.55)
                    ],
                    relativeTime: relativeTime
                )
                let body = CHHapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                    ],
                    relativeTime: relativeTime + 0.02,
                    duration: max(dash - 0.02, unit * 2.5)
                )
                events.append(attack)
                events.append(body)
                relativeTime += dash
            }

            for ch in morse {
                switch ch {
                case ".":
                    addDot()
                    relativeTime += intraCharGap
                case "-":
                    addDash()
                    relativeTime += intraCharGap
                case " ":
                    // letter gap: replace last intraChar with interChar by adding the delta
                    relativeTime += (interCharGap - intraCharGap)
                case "/":
                    // word gap: replace last intraChar with word gap by adding the delta
                    relativeTime += (wordGap - intraCharGap)
                default:
                    break
                }
            }

            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
            // Stop flag after completion
            DispatchQueue.main.asyncAfter(deadline: .now() + relativeTime + unit) {
                cancelPlaybackHighlights()
                isPlayingHaptics = false
                completion()
            }
            coreHapticsWorked = true
        } catch {
            coreHapticsWorked = false
        }

        if coreHapticsWorked {
            return
        }
#endif // CoreHaptics
        // UIKit fallback: simulate duration by repeating impacts over the desired interval
        let dotImpact = UIImpactFeedbackGenerator(style: .rigid)
        let dashImpact = UIImpactFeedbackGenerator(style: .heavy)
        dotImpact.prepare()
        dashImpact.prepare()

        var delay: TimeInterval = 0
        func scheduleDotImpact() {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                dotImpact.impactOccurred(intensity: 1.0)
            }
            delay += dot
        }

        func scheduleDashBurst(duration: TimeInterval) {
            // Fire heavier impacts more frequently so dashes feel fuller than dots.
            let step = max(unit / 3, 0.02)
            var t: TimeInterval = 0
            while t < duration {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay + t) {
                    dashImpact.impactOccurred(intensity: 1.0)
                }
                t += step
            }
            delay += duration
        }

        for ch in morse {
            switch ch {
            case ".":
                scheduleDotImpact()
                delay += intraCharGap
            case "-":
                scheduleDashBurst(duration: dash)
                delay += intraCharGap
            case " ":
                delay += (interCharGap - intraCharGap)
            case "/":
                delay += (wordGap - intraCharGap)
            default:
                break
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay + unit) {
            cancelPlaybackHighlights()
            isPlayingHaptics = false
            completion()
        }
#endif // UIKit
    }
    private func replayHaptics(completion: (() -> Void)? = nil) {
#if canImport(UIKit)
        let morse = vm.morseClue
        // Send to watch so it can play haptics too
        activateWatchSessionIfNeeded()
        sendMorseToWatch(morse)
        playMorseHaptics(for: morse, completion: { completion?() })
#else
        completion?()
#endif
    }
}

#Preview {
    Daily(vm: DailyMorseViewModel())
        .environmentObject(PlaybackSettings())
        .environmentObject(UserProgress())
}
