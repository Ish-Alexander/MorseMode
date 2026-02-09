//
//  Daily.swift
//  MorseMode
//
//  Created by Ishauna Marie Alexander on 1/27/26.
//

import SwiftUI
import WatchConnectivity
import Combine

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
}

final class DailyMorseViewModel: ObservableObject {
    
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
    @Published var timeRemaining: Int = 180 // 3 minutes
    @Published var isActive: Bool = true

    private var timer: Timer?

    init(word: String = "") {
        self.targetWord = (word.isEmpty ? Self.wordForToday() : word).uppercased()
        startTimer()
    }

    deinit {
        timer?.invalidate()
    }

    func startTimer() {
        timer?.invalidate()
        isActive = true
        timeRemaining = 180
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] t in
            guard let self else { return }
            if self.timeRemaining > 0 && self.isActive {
                self.timeRemaining -= 1
            } else {
                t.invalidate()
                self.isActive = false
            }
        }
    }

    var morseClue: String {
        encodeMorse(targetWord)
    }

    var displayBlanks: String {
        // Hangman-style: underscores for unrevealed letters, keep spaces
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
        } else {
            wrongGuesses.insert(upper)
        }
        if isSolved {
            isActive = false
            timer?.invalidate()
        }
    }

    func reset(with newWord: String? = nil) {
        revealed.removeAll()
        wrongGuesses.removeAll()
        if let newWord, !newWord.isEmpty {
            targetWord = newWord.uppercased()
        }
        startTimer()
    }
    
    func resetForToday() {
        reset(with: Self.wordForToday())
    }
}

struct Daily: View {
    @StateObject private var vm = DailyMorseViewModel()
    @State private var currentGuess: String = ""
    @State private var isPlayingHaptics: Bool = false
    
#if canImport(CoreHaptics)
    @State private var hapticEngine: CHHapticEngine? = nil
#endif
    
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
                
                ZStack{
                    Image("Tube")
                    VStack(spacing: 8) {
                        
                        Text(vm.morseClue)
                            .font(.system(size: 28, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                
                // Hangman blanks
                VStack(spacing: 8) {
                    Text("Decode")
                        .font(.custom("berkelium bitmap", size: 24))
                        .font(.headline)
                        .foregroundStyle(.neonGreen.opacity(0.8))
                    Text(vm.displayBlanks)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.neonGreen)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Input row
                HStack(spacing: 12) {
                    TextField("Guess a letter", text: $currentGuess)
                        .textInputAutocapitalization(.characters)
                        .disableAutocorrection(true)
                        .foregroundStyle(.neonGreen)
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
                    // Replay Haptics Button
                    Button(action: {
                        replayHaptics()
                    }) {
                        ZStack {
                            Text("Replay Haptics")
                                .font(.custom("berkelium bitmap", size: 16))
                                .foregroundStyle(.neonGreen)
                        }
                    }
                    .accessibilityLabel("Replay the last Morse haptics")
                    .disabled(isPlayingHaptics)
                    
                    // Status
                    if vm.isSolved {
                        Text("Solved! ✅")
                            .font(.custom("berkelium bitmap", size: 16))
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.neonGreen)
                    } else if vm.timeRemaining == 0 {
                        Text("Time's up! The word was \(vm.targetWord)")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.yellow)
                            .multilineTextAlignment(.center)
                            .padding(.top, 8)
                    }
                    
                    Spacer(minLength: 0)
                }
                .padding()
            }
        }
        .onAppear {
            // Small delay to ensure layout/haptic engine readiness
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                replayHaptics()
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
    
    private func playMorseHaptics(for morse: String) {
#if canImport(UIKit)
        guard !isPlayingHaptics else { return }
        isPlayingHaptics = true

        // Base timing unit (seconds)
        let unit: TimeInterval = 0.08 // tweak to taste
        let dot = unit
        let dash = unit * 3 // dash lasts 3x as long as dot
        let intraCharGap = unit
        let interCharGap = unit * 6 // between letters (increased for clearer separation)
        let wordGap = unit * 7 // between words ('/' separator)

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
        }
#endif // UIKit
    }

    // MARK: - Haptics
    private func replayHaptics() {
#if canImport(UIKit)
        let morse = vm.morseClue
        playMorseHaptics(for: morse)
#else
        // No UIKit haptics available
#endif
    }
}

#Preview {
    Daily()
}

