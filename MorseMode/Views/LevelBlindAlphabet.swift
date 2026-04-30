//
//  LevelBlindAlphabet.swift
//  MorseMode
//
//  Created by Codex on 4/27/26.
//

import SwiftUI
import WatchConnectivity
import AVFoundation

struct LevelBlindAlphabet: View {
    @EnvironmentObject private var userProgress: UserProgress
    @EnvironmentObject private var morseEngine: MorseEngine
    @EnvironmentObject private var playbackSettings: PlaybackSettings
    @EnvironmentObject private var levelFlow: LevelFlow

    @State private var letter: String = ""
    @State private var inputPattern: String = ""
    @State private var lastFeedback: String = ""
    @State private var audioPlayer: AVAudioPlayer? = nil
    @State private var incorrectGuesses: Int = 0
    @State private var completedLetters: Set<String> = []
    @State private var isLevelComplete: Bool = false

    private let targetLetters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ").map { String($0) }
    private let morseMap: [Character: String] = [
        "A": ".-",   "B": "-...", "C": "-.-.", "D": "-..",  "E": ".",
        "F": "..-.", "G": "--.",  "H": "....", "I": "..",   "J": ".---",
        "K": "-.-",  "L": ".-..", "M": "--",   "N": "-.",   "O": "---",
        "P": ".--.", "Q": "--.-", "R": ".-.",  "S": "...",  "T": "-",
        "U": "..-",  "V": "...-", "W": ".--",  "X": "-..-", "Y": "-.--",
        "Z": "--.."
    ]

    @discardableResult
    private func createNewItem() -> String {
        let remainingLetters = targetLetters.filter { !completedLetters.contains($0) }
        let newLetter = remainingLetters.randomElement() ?? targetLetters.randomElement() ?? "A"
        letter = newLetter
        inputPattern.removeAll()
        return newLetter
    }

    private func playHapticsForCurrentLetter() {
        guard let letterEnum = Letter(string: letter) else { return }
        morseEngine.performHaptic(for: letterEnum)
    }

    private func playSoundForCurrentLetter() {
        let playback = MorseLetterAudio.play(
            character: Character(letter),
            reusing: audioPlayer,
            logPrefix: "LevelBlindAlphabet"
        )
        audioPlayer = playback.player
    }

    private func sendToWatch(_ payload: [String: Any]) {
        MorseModePhoneConnectivity.shared.send(payload)
    }

    private func activateWatchSessionIfNeeded() {
        guard WCSession.isSupported() else { return }
        MorseModePhoneConnectivity.shared.activate()
    }

    private func playCurrentLetterAcrossDevices() {
        guard !letter.isEmpty else { return }
        if playbackSettings.mode.allowsHaptics {
            playHapticsForCurrentLetter()
        }
        if playbackSettings.mode.allowsSound {
            playSoundForCurrentLetter()
        }
        sendToWatch([
            "action": "playMorse",
            "letter": letter
        ])
    }

    private func advanceToNextLetter(after delay: TimeInterval = 1.4) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard !isLevelComplete else { return }
            guard incorrectGuesses < 10 else { return }
            _ = createNewItem()
            playCurrentLetterAcrossDevices()
            lastFeedback = ""
        }
    }

    private func submitPattern(_ pattern: String) {
        guard !letter.isEmpty else { return }
        guard incorrectGuesses < 10 else { return }
        guard let targetChar = letter.uppercased().first,
              let expected = morseMap[targetChar] else {
            lastFeedback = "No target letter"
            return
        }

        let completedLetter = String(targetChar)

        if pattern == expected {
            completedLetters.insert(completedLetter)
            inputPattern.removeAll()

            if completedLetters.count == targetLetters.count {
                isLevelComplete = true
                userProgress.completeLevel(15)
                lastFeedback = "Final level complete!"
            } else {
                lastFeedback = "Correct! \(completedLetter) \(completedLetters.count)/26"
                advanceToNextLetter()
            }

            sendToWatch([
                "action": "feedback",
                "result": "correct"
            ])
        } else {
            incorrectGuesses = min(incorrectGuesses + 1, 10)
            inputPattern.removeAll()

            if incorrectGuesses >= 10 {
                lastFeedback = "10 incorrect guesses. Go back and practice the earlier levels again."
            } else {
                lastFeedback = "Incorrect. That was \(completedLetter). \(incorrectGuesses)/10"
                advanceToNextLetter(after: 1.8)
            }

            sendToWatch([
                "action": "feedback",
                "result": "incorrect"
            ])
        }
    }

    private func appendSymbol(_ symbol: String) {
        guard !isLevelComplete else { return }
        guard incorrectGuesses < 10 else { return }
        guard inputPattern.count < 4 else { return }
        if playbackSettings.mode.allowsHaptics {
            if symbol == "." {
                morseEngine.performInputHaptic(for: .dot)
            } else if symbol == "-" {
                morseEngine.performInputHaptic(for: .dash)
            }
        }
        inputPattern.append(symbol)
    }

    private var alphabetProgressText: String {
        targetLetters.map { completedLetters.contains($0) ? $0 : "_" }.joined(separator: " ")
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 14) {
                JourneyLevelTopBar()

                Text("LEVEL 15")
                    .font(.custom("berkelium bitmap", size: 24))
                    .foregroundStyle(.neon)

                Text("The letter plays once. Enter the Morse pattern with no replay.")
                    .font(.custom("berkelium bitmap", size: 12))
                    .foregroundStyle(Color.white.opacity(0.82))
                    .multilineTextAlignment(.center)

                HStack(spacing: 18) {
                    Text("Correct: \(completedLetters.count)/26")
                    Text("Incorrect: \(incorrectGuesses)/10")
                }
                .foregroundStyle(.neon)
                .font(.custom("berkelium bitmap", size: 16))

                Text(alphabetProgressText)
                    .font(.custom("berkelium bitmap", size: 14))
                    .foregroundStyle(.neon.opacity(0.9))
                    .multilineTextAlignment(.center)

                if isLevelComplete {
                    Text("Every letter identified from memory.")
                        .font(.custom("berkelium bitmap", size: 12))
                        .foregroundStyle(.green)
                }

                if !lastFeedback.isEmpty {
                    Text(lastFeedback)
                        .foregroundStyle(lastFeedback.contains("Correct") || lastFeedback.contains("complete") ? .green : .yellow)
                        .font(.custom("berkelium bitmap", size: 12))
                        .multilineTextAlignment(.center)
                }

                ZStack {
                    Image("Tube")
                        .resizable()
                        .scaledToFit()

                    Text(isLevelComplete ? "A-Z" : letter)
                        .font(.custom("berkelium bitmap", size: isLevelComplete ? 84 : 150))
                        .minimumScaleFactor(0.55)
                        .lineLimit(1)
                        .frame(width: 170, height: 150)
                        .foregroundStyle(.neon)
                }
                .frame(maxHeight: 310)

                VStack(spacing: 12) {
                    Text(inputPattern.isEmpty ? "Input: " : "Input: \(inputPattern)")
                        .font(.custom("berkelium bitmap", size: 14))
                        .foregroundStyle(.neon)

                    HStack(spacing: 12) {
                        morseButton(title: "DOT", symbol: ".")
                        morseButton(title: "DASH", symbol: "-")
                    }

                    HStack(spacing: 12) {
                        Button {
                            submitPattern(inputPattern)
                        } label: {
                            actionButtonLabel("Send", fill: Color.neon.opacity(0.12), textColor: .neon)
                        }
                        .buttonStyle(.plain)
                        .disabled(inputPattern.isEmpty || incorrectGuesses >= 10)
                        .opacity(inputPattern.isEmpty || incorrectGuesses >= 10 ? 0.45 : 1)

                        Button {
                            inputPattern.removeAll()
                        } label: {
                            actionButtonLabel("Clear", fill: Color.yellow.opacity(0.12), textColor: .yellow)
                        }
                        .buttonStyle(.plain)
                        .disabled(incorrectGuesses >= 10)
                        .opacity(inputPattern.isEmpty || incorrectGuesses >= 10 ? 0.45 : 1)
                    }
                }

                Spacer(minLength: 0)

                if isLevelComplete {
                    Button {
                        levelFlow.exitToLevelSelect()
                    } label: {
                        actionButtonLabel("Back to Journey Map", fill: Color.neon, textColor: .black)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .preferredColorScheme(.dark)
        .onAppear {
            activateWatchSessionIfNeeded()
            _ = createNewItem()
            playCurrentLetterAcrossDevices()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("MorseModeWatchInput"))) { notification in
            guard let userInfo = notification.userInfo as? [String: Any],
                  let action = userInfo["action"] as? String,
                  let pattern = userInfo["pattern"] as? String else { return }
            if action == "morsePreview" {
                inputPattern = pattern
                return
            }
            guard action == "morseInput" else { return }
            submitPattern(pattern)
        }
    }

    private func morseButton(title: String, symbol: String) -> some View {
        Button {
            appendSymbol(symbol)
        } label: {
            Text(title == "DOT" ? "Dot ·" : "Dash -")
                .font(.custom("berkelium bitmap", size: 18))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(incorrectGuesses >= 10 ? Color.white.opacity(0.2) : Color.neon)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isLevelComplete || incorrectGuesses >= 10)
        .opacity(isLevelComplete || incorrectGuesses >= 10 ? 0.45 : 1)
    }

    private func actionButtonLabel(_ title: String, fill: Color, textColor: Color) -> some View {
        Text(title)
            .font(.custom("berkelium bitmap", size: 18))
            .foregroundStyle(textColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(fill)
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(fill == Color.yellow.opacity(0.12) ? Color.yellow : Color.neon, lineWidth: 1.5)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#Preview {
    LevelBlindAlphabet()
        .environmentObject(UserProgress())
        .environmentObject(MorseEngine())
        .environmentObject(PlaybackSettings())
        .environmentObject(LevelFlow())
}
