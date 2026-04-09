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

    private func saveTimeRemaining() {
        UserDefaults.standard.set(timeRemaining, forKey: timeKey)
    }

    private func loadTimeRemaining() -> Int? {
        let value = UserDefaults.standard.integer(forKey: timeKey)
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

    private static let dailyWords: [String] = [
        "SWIFT", "APPLE", "MORSE", "CODE", "WATCH", "SIGNAL", "XCODE", "DECODE",
        "BITMAP", "NEON", "HAPTIC", "VIBRATE", "DOT", "DASH", "PUZZLE", "SECRET",
        "RADIO", "TELEGRAPH", "MESSAGE", "ENCODE", "DECODE", "SENDER", "RECEIVER",
        "FREQUENCY", "PATTERN", "RHYTHM", "SPEED", "TIMER", "TARGET", "LETTER"
    ]

    private static func dailyIndex(for date: Date = Date()) -> Int {
        let cal = Calendar(identifier: .gregorian)
        let startOfDay = cal.startOfDay(for: date)
        let daysSinceRef = cal.dateComponents([.day], from: Date(timeIntervalSince1970: 0), to: startOfDay).day ?? 0
        return abs(daysSinceRef) % max(1, dailyWords.count)
    }

    static func wordForToday(on date: Date = Date()) -> String {
        dailyWords[dailyIndex(for: date)]
    }

    @Published var targetWord: String
    @Published var revealed: Set<Character> = []
    @Published var wrongGuesses: Set<Character> = []
    @Published var timeRemaining: Int = 180
    @Published var isActive: Bool = true

    private var timer: Timer?

    private func persistGameplayState(at date: Date = Date()) {
        saveTimeRemaining()
        saveWrongGuesses()
        saveRevealed()
        saveIsActive()
        saveLastSavedAt(date)
    }

    private func restoreElapsedTimeIfNeeded(referenceDate: Date = Date()) {
        guard let wasActive = loadIsActive(), wasActive else {
            if let restoredTime = loadTimeRemaining(), restoredTime > 0 {
                timeRemaining = restoredTime
            }
            return
        }

        guard let savedAt = loadLastSavedAt() else { return }
        let restoredTime = loadTimeRemaining() ?? timeRemaining
        let elapsed = max(0, Int(referenceDate.timeIntervalSince(savedAt)))
        let adjusted = max(0, restoredTime - elapsed)

        timeRemaining = adjusted
        isActive = adjusted > 0
        saveTimeRemaining()
        saveIsActive()
        saveLastSavedAt(referenceDate)
    }

    init(word: String = "") {
        self.targetWord = (word.isEmpty ? Self.wordForToday() : word).uppercased()
        if isAlreadySolved {
            revealed = Set(targetWord.filter { $0 != " " })
            saveRevealed()
            isActive = false
            timeRemaining = 180
            clearTimeRemaining()
            clearWrongGuesses()
            clearLastSavedAt()
            clearIsActive()
        } else {
            let restoredTime = loadTimeRemaining()
            let restoredWrong = loadWrongGuesses()
            if let t = restoredTime, t > 0 {
                timeRemaining = t
            } else {
                timeRemaining = 180
            }
            wrongGuesses = restoredWrong
            revealed = loadRevealed()
            isActive = loadIsActive() ?? false
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
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] t in
            guard let self else { return }
            if self.timeRemaining > 0 && self.isActive {
                self.timeRemaining -= 1
                self.persistGameplayState()
            } else {
                t.invalidate()
                self.isActive = false
                self.persistGameplayState()
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
    }

    var displayBlanks: String {
        targetWord.map { ch -> String in
            if ch == " " { return "  " }
            return revealed.contains(ch) ? String(ch) : "_"
        }.joined(separator: " ")
    }

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
        if isSolved {
            isActive = false
            timer?.invalidate()
            timer = nil
            markSolved()
            clearTimeRemaining()
            clearWrongGuesses()
            clearRevealed()
        }
    }
}

struct Daily: View {
    @ObservedObject var vm: DailyMorseViewModel
    @State private var currentGuess: String = ""
    @FocusState private var isGuessFieldFocused: Bool
    @State private var isPlayingHaptics: Bool = false
    @State private var audioPlayer: AVAudioPlayer? = nil
    @State private var wcSessionActivated: Bool = false

#if canImport(CoreHaptics)
    @State private var hapticEngine: CHHapticEngine? = nil
#endif

    @Environment(\.scenePhase) private var scenePhase

    // ✅ FIX: Sets audio session to .playback so sound works in silent mode
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: []
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("[Audio][Daily] Session setup failed: \(error)")
        }
    }

    private func activateWatchSessionIfNeeded() {
    #if canImport(WatchConnectivity)
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

    private func playSound(for letter: Character) {
        let upper = String(letter).uppercased()
        guard let first = upper.first, first.isLetter else {
            audioPlayer?.stop()
            audioPlayer = nil
            return
        }
        let baseName = "\(first)_morse_code"
        let candidateExtensions = ["ogg.mp3", "mp3", "ogg", "wav", "m4a"]
        var foundURL: URL? = nil
        for ext in candidateExtensions {
            if let url = Bundle.main.url(forResource: baseName, withExtension: ext) {
                foundURL = url
                break
            }
        }
        guard let url = foundURL else {
            if audioPlayer?.isPlaying == true { audioPlayer?.stop() }
            audioPlayer = nil
            print("[Audio][Daily] No audio file for letter \(first). Tried: \(candidateExtensions.map { "\(baseName).\($0)" }.joined(separator: ", "))")
            return
        }
        do {
            if let player = audioPlayer, player.url == url {
                player.currentTime = 0
                player.play()
            } else {
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                player.play()
                audioPlayer = player
            }
        } catch {
            print("[Audio][Daily] Failed to play \(url.lastPathComponent): \(error)")
        }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            GeometryReader { proxy in
                ScrollView {
                    VStack(spacing: 16) {
                        Text(timerString)
                            .font(.custom("berkelium bitmap", size: 36))
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(vm.timeRemaining > 10 ? .green : .red)
                            .accessibilityLabel("Time remaining: \(timerString)")

                        ZStack {
                            Image("Tube")
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: 240)
                            VStack(spacing: 8) {
                                if vm.isSolved {
                                    Text("Solved! ✅")
                                        .font(.custom("berkelium bitmap", size: 16))
                                        .foregroundStyle(.neon)
                                        .transition(.opacity)
                                } else if vm.timeRemaining == 0 {
                                    Text("Time's up! The word was \(vm.targetWord)")
                                        .font(.title3.weight(.semibold))
                                        .foregroundStyle(.yellow)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                        .transition(.opacity)
                                }

                                Text(vm.morseClue)
                                    .font(.system(size: 28, weight: .medium, design: .monospaced))
                                    .foregroundStyle(.white)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(nil)
                                    .minimumScaleFactor(0.4)
                                    .allowsTightening(true)
                                    .padding(.horizontal, 16)
                                    .frame(maxWidth: 220)
                            }
                        }

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
                        }

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

                        HStack(spacing: 16) {
                            Button(action: {
                                replayHaptics()
                            }) {
                                ZStack {
                                    Text("Replay Haptics")
                                        .font(.custom("berkelium bitmap", size: 16))
                                        .foregroundStyle(.neon)
                                }
                            }
                            .accessibilityLabel("Replay the last Morse haptics")
                            .disabled(isPlayingHaptics)
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
            setupAudioSession() // ✅ FIX: Configure audio before anything plays
            vm.syncStateForScenePhase(.active)
            activateWatchSessionIfNeeded()
            if vm.isSolved {
                sendMorseToWatch(vm.morseClue)
            } else {
                sendMorseToWatch(vm.morseClue)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    if vm.timeRemaining > 0 {
                        replayHaptics { vm.startTimer() }
                    }
                }
            }
        }
        .onDisappear {
            vm.syncStateForScenePhase(.inactive)
            stopFeedbackPlaybackOnly()
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
    #if canImport(CoreHaptics)
        hapticEngine?.stop()
    #endif
        if audioPlayer?.isPlaying == true { audioPlayer?.stop() }
        audioPlayer = nil
        isPlayingHaptics = false
#endif
    }

    private func playMorseHaptics(for morse: String, completion: @escaping () -> Void) {
#if canImport(UIKit)
        guard !isPlayingHaptics else { completion(); return }
        isPlayingHaptics = true

        let unit: TimeInterval = 0.08
        let dot = unit
        let dash = unit * 3
        let intraCharGap = unit
        let interCharGap = unit * 6
        let wordGap = unit * 7

        var audioStart: TimeInterval = 0
        let letters = Array(vm.targetWord.uppercased())
        for (i, ch) in letters.enumerated() {
            if ch == " " {
                audioStart += wordGap
                continue
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + audioStart) {
                playSound(for: ch)
            }
            if let pattern = morseMap[ch] {
                var letterDuration: TimeInterval = 0
                for (idx, sym) in pattern.enumerated() {
                    letterDuration += (sym == "-" ? dash : dot)
                    if idx < pattern.count - 1 {
                        letterDuration += intraCharGap
                    }
                }
                audioStart += letterDuration
            }
            if i < letters.count - 1 {
                let next = letters[i + 1]
                audioStart += (next == " " ? wordGap : interCharGap)
            }
        }

#if canImport(CoreHaptics)
        var coreHapticsWorked = false
        do {
            if hapticEngine == nil {
                hapticEngine = try CHHapticEngine()
            }
            let engine = hapticEngine!
            try engine.start()

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
                    relativeTime += (interCharGap - intraCharGap)
                case "/":
                    relativeTime += (wordGap - intraCharGap)
                default:
                    break
                }
            }

            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
            DispatchQueue.main.asyncAfter(deadline: .now() + relativeTime + unit) {
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
#endif
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
            isPlayingHaptics = false
            completion()
        }
#endif
    }

    private func replayHaptics(completion: (() -> Void)? = nil) {
#if canImport(UIKit)
        let morse = vm.morseClue
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
}
