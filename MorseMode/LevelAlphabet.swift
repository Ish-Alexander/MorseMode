//
//  LevelAlphabet.swift
//  MorseMode
//
//  Created by Ishauna Marie Alexander on 4/9/26.
//

import SwiftUI
import WatchConnectivity
import AVFoundation

struct LevelAlphabet: View {
    @EnvironmentObject private var userProgress: UserProgress
    @EnvironmentObject private var morseEngine: MorseEngine
    @EnvironmentObject private var levelFlow: LevelFlow

    @State private var letter: String = ""
    @State private var inputPattern: String = ""
    @State private var lastFeedback: String = ""
    @State private var rotationAngle: Double = 0
    @State private var audioPlayer: AVAudioPlayer? = nil
    @State private var incorrectGuesses: Int = 0
    @State private var completedLetters: Set<String> = []
    @State private var isLevelComplete: Bool = false

    #if canImport(WatchConnectivity)
        private let watchDelegate = MorseWatchInputDelegate()
    #endif

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
        let upper = letter.uppercased()
        guard let first = upper.first, first.isLetter else {
            audioPlayer?.stop()
            audioPlayer = nil
            return
        }

        let baseName = "\(first)_morse_code"
        let candidateExtensions = ["ogg.mp3", "mp3", "ogg"]

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
            print("[Audio][LevelAlphabet] No audio file found for letter \(first)")
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
            print("[Audio][LevelAlphabet] Failed to play \(url.lastPathComponent): \(error)")
        }
    }

    private func sendToWatch(_ payload: [String: Any]) {
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(payload, replyHandler: nil)
        } else {
            try? WCSession.default.updateApplicationContext(payload)
        }
    }

    private func activateWatchSessionIfNeeded() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        if session.delegate == nil {
            session.delegate = watchDelegate
        }
        if session.activationState != .activated {
            session.activate()
        }
    }

    private func playCurrentLetterAcrossDevices() {
        guard !letter.isEmpty else { return }
        playHapticsForCurrentLetter()
        playSoundForCurrentLetter()
        sendToWatch([
            "action": "playMorse",
            "letter": letter
        ])
    }

    private func submitPattern(_ pattern: String) {
        guard !letter.isEmpty else { return }
        guard incorrectGuesses < 10 else { return }
        guard let targetChar = letter.uppercased().first,
              let expected = morseMap[targetChar] else {
            lastFeedback = "No target letter"
            return
        }

        if pattern == expected {
            let completedLetter = String(targetChar)
            completedLetters.insert(completedLetter)
            inputPattern.removeAll()

            if completedLetters.count == targetLetters.count {
                isLevelComplete = true
                userProgress.completeLevel(14)
                lastFeedback = "Alphabet Complete!"
            } else {
                lastFeedback = "Correct! \(completedLetters.count)/26"
            }

            sendToWatch([
                "action": "feedback",
                "result": "correct"
            ])

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                guard !isLevelComplete else { return }
                _ = createNewItem()
                playCurrentLetterAcrossDevices()
                lastFeedback = ""
            }
        } else {
            incorrectGuesses = min(incorrectGuesses + 1, 10)
            inputPattern.removeAll()
            if incorrectGuesses >= 10 {
                lastFeedback = "10 incorrect guesses. Go back and practice the earlier levels again."
            } else {
                lastFeedback = "Incorrect - Try Again! \(incorrectGuesses)/10"
            }
            sendToWatch([
                "action": "feedback",
                "result": "incorrect"
            ])

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                if lastFeedback.contains("Incorrect") && incorrectGuesses < 10 {
                    lastFeedback = ""
                }
            }
        }
    }

    private func appendSymbol(_ symbol: String) {
        guard !isLevelComplete else { return }
        guard inputPattern.count < 4 else { return }
        guard incorrectGuesses < 10 else { return }
        if symbol == "." {
            morseEngine.performInputHaptic(for: .dot)
        } else if symbol == "-" {
            morseEngine.performInputHaptic(for: .dash)
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
                HStack {
                    Button {
                        levelFlow.exitToLevelSelect()
                    } label: {
                        Text("Back")
                            .font(.custom("berkelium bitmap", size: 12))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(Color.neon)
                            )
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }

                Text("LEVEL 14")
                    .font(.custom("berkelium bitmap", size: 24))
                    .foregroundStyle(.neon)

                Text("Listen, then tap the Morse code for any letter in the alphabet.")
                    .font(.custom("berkelium bitmap", size: 12))
                    .foregroundStyle(Color.white.opacity(0.82))
                    .multilineTextAlignment(.center)

                HStack(spacing: 18) {
                    Text("Correct: \(completedLetters.count)/26")
                    Text("Incorrect: \(incorrectGuesses)/10")
                }
                .foregroundStyle(.neon)
                .font(.custom("berkelium bitmap", size: 14))

                Text("Letters in play: A B C D E F G H I J K L M N O P Q R S T U V W X Y Z")
                    .font(.custom("berkelium bitmap", size: 10))
                    .foregroundStyle(Color.white.opacity(0.72))
                    .multilineTextAlignment(.center)

                Text(alphabetProgressText)
                    .font(.custom("berkelium bitmap", size: 10))
                    .foregroundStyle(.neon.opacity(0.9))
                    .multilineTextAlignment(.center)

                if isLevelComplete {
                    Text("Alphabet mastered.")
                        .font(.custom("berkelium bitmap", size: 12))
                        .foregroundStyle(.green)
                }

                if !lastFeedback.isEmpty {
                    Text(lastFeedback)
                        .foregroundStyle(lastFeedback.contains("Correct") || lastFeedback.contains("Complete") ? .green : .yellow)
                        .font(.custom("berkelium bitmap", size: 12))
                        .multilineTextAlignment(.center)
                }

                ZStack {
                    Image("Tube")
                        .resizable()
                        .scaledToFit()

                    Text(letter)
                        .font(.custom("berkelium bitmap", size: isLevelComplete ? 92 : 118))
                        .minimumScaleFactor(0.55)
                        .lineLimit(1)
                        .frame(width: 150, height: 150)
                        .foregroundStyle(.neon)
                }
                .frame(maxHeight: 310)

                Button {
                    playCurrentLetterAcrossDevices()
                } label: {
                    ZStack {
                        Image("Radar")
                            .resizable()
                            .frame(width: 78, height: 78)
                            .scaledToFit()
                            .rotationEffect(.degrees(rotationAngle))
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.neon)
                            .rotationEffect(.degrees(rotationAngle))
                    }
                }
                .buttonStyle(.plain)

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
            }
            .padding()
        }
        .preferredColorScheme(.dark)
        .onAppear {
            activateWatchSessionIfNeeded()
            _ = createNewItem()
            playCurrentLetterAcrossDevices()
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false).speed(0.25)) {
                rotationAngle = 360
            }
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
    LevelAlphabet()
        .environmentObject(UserProgress())
        .environmentObject(MorseEngine())
        .environmentObject(LevelFlow())
}
