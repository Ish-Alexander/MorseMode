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
    }
    private var isAlreadySolved: Bool {
        UserDefaults.standard.bool(forKey: solvedKey)
    }
    // Remembers if the user solved today's puzzle

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
        //Picks one word for the day, makes that word the same for everyone
    }

    @Published var targetWord: String
    @Published var revealed: Set<Character> = []
    @Published var wrongGuesses: Set<Character> = []
    @Published var timeRemaining: Int = 180 // 3 minutes
    @Published var isActive: Bool = true
// Updates UI when changes are made
    
    private var timer: Timer?

    init(word: String = "") {
        self.targetWord = (word.isEmpty ? Self.wordForToday() : word).uppercased()
        if isAlreadySolved {
            // Reveal all unique letters and keep game inactive
            revealed = Set(targetWord.filter { $0 != " " })
            saveRevealed()
            isActive = false
            timeRemaining = 180
            // Clear any leftover persisted state for a solved day
            clearTimeRemaining()
            clearWrongGuesses()
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
            isActive = false // start after intro haptics
        }
    }

    deinit {
        saveTimeRemaining()
        saveRevealed()
        saveWrongGuesses()
        timer?.invalidate()
    }

    func startTimer() {
        timer?.invalidate()
        isActive = true
        // timeRemaining = 180  // Removed this line as per instructions
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] t in
            guard let self else { return }
            if self.timeRemaining > 0 && self.isActive {
                self.timeRemaining -= 1
                self.saveTimeRemaining()
            } else {
                t.invalidate()
                self.isActive = false
                self.saveTimeRemaining()
                // Runs the timer
            }
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
        // Adds letters to "Revealed" and "Wrong Guess" lines
        if isSolved {
            isActive = false
            timer?.invalidate()
            markSolved()
            clearTimeRemaining()
            clearWrongGuesses()
            clearRevealed()
            // Stops timer when word is solved
        }
    }
}

struct Daily: View {
    @StateObject private var vm = DailyMorseViewModel()
    // Game logic object
    @State private var currentGuess: String = ""
    // What the user types
    @State private var isPlayingHaptics: Bool = false
    // Prevents overlapping haptics
    @State private var audioPlayer: AVAudioPlayer? = nil
    // Plays morse code audio
    
    // Watch Connectivity session
    @State private var wcSessionActivated: Bool = false

#if canImport(CoreHaptics)
    @State private var hapticEngine: CHHapticEngine? = nil
#endif

    @Environment(\.scenePhase) private var scenePhase
    
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
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        // Prefer immediate message if reachable; fall back to user info transfer
        let payload: [String: Any] = ["morseClue": morse, "word": vm.targetWord]
        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
        } else {
            session.transferUserInfo(payload)
        }
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
            // Finds the audio file, plays the matching letter, sends error code if audio not found
        }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
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
                    VStack(spacing: 8) {
                        // Status above the clue
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

                        // Morse clue below
                        Text(vm.morseClue)
                            .font(.system(size: 28, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                            .minimumScaleFactor(0.4)
                            .allowsTightening(true)
                            .padding(.horizontal, 16)
                            .frame(maxWidth: 300) // constrain to fit inside Tube image
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
                
                // Input row
                HStack(spacing: 12) {
                    TextField("Guess a letter", text: $currentGuess)
                        .textInputAutocapitalization(.characters)
                        .disableAutocorrection(true)
                        .foregroundStyle(.neon)
                        .tint(.white)
                        .padding(12)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .frame(maxWidth: 220)
                        .onSubmit(submitGuess)
                    
                    Button(action: submitGuess) {
                        Text("Guess")
                            .fontWeight(.semibold)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(.white)
                            .foregroundStyle(.black)
                            .clipShape(Capsule())
                    }
                    .disabled(!vm.isActive || vm.timeRemaining == 0)
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
                            Text("Replay Haptics")
                                .font(.custom("berkelium bitmap", size: 16))
                                .foregroundStyle(.neon)
                        }
                    }
                    .accessibilityLabel("Replay the last Morse haptics")
                    .disabled(isPlayingHaptics)
                    // Replays the morse code and haptics
                }
                .padding()
            }
        }
        .onAppear {
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
            stopFeedbackPlaybackOnly()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
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

    private func submitGuess() {
        guard let ch = currentGuess.trimmingCharacters(in: .whitespacesAndNewlines).first else { return }
        vm.guess(ch)
        currentGuess = ""
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
            DispatchQueue.main.asyncAfter(deadline: .now() + audioStart) {
                playSound(for: ch)
            }

            // Advance by the duration of this letter’s Morse pattern (symbols + intra gaps)
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

            // Add inter-letter gap unless next is a space or end
            if i < letters.count - 1 {
                let next = letters[i + 1]
                audioStart += (next == " " ? wordGap : interCharGap)
            }
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

            func addContinuous(_ duration: TimeInterval, intensity: Float) {
                let intensityParam = CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity)
                let sharpnessParam = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                let event = CHHapticEvent(eventType: .hapticContinuous, parameters: [intensityParam, sharpnessParam], relativeTime: relativeTime, duration: duration)
                events.append(event)
                relativeTime += duration
            }

            for ch in morse {
                switch ch {
                case ".":
                    addContinuous(dot, intensity: 0.6)
                    relativeTime += intraCharGap
                case "-":
                    addContinuous(dash, intensity: 1.0)
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
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.prepare()

        var delay: TimeInterval = 0
        func scheduleImpactBurst(duration: TimeInterval, intensity: CGFloat) {
            // Fire small impacts every ~unit/2 to simulate continuous feel
            let step = max(unit / 2, 0.02)
            var t: TimeInterval = 0
            while t <= duration {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay + t) {
                    impact.impactOccurred(intensity: intensity)
                }
                t += step
            }
            delay += duration
        }

        for ch in morse {
            switch ch {
            case ".":
                scheduleImpactBurst(duration: dot, intensity: 0.6)
                delay += intraCharGap
            case "-":
                scheduleImpactBurst(duration: dash, intensity: 1.0)
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
    Daily()
}

