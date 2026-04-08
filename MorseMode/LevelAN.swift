//
//  LevelAN.swift
//  MorseMode
//
//  Created by Ishauna Marie Alexander on 4/7/26.
//

import SwiftUI
import WatchConnectivity
import AVFoundation

struct LevelAN: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var userProgress: UserProgress
    @EnvironmentObject private var morseEngine: MorseEngine

    @State private var letter: String = ""
    @State private var inputPattern: String = ""
    @State private var lastFeedback: String = ""
    @State private var rotationAngle: Double = 0
    @State private var audioPlayer: AVAudioPlayer? = nil
    @State private var correctCounts: [String: Int] = [
        "A": 0,
        "N": 0
    ]
    @State private var isLevelComplete: Bool = false

    #if canImport(WatchConnectivity)
        private let watchDelegate = Learn2WatchDelegate()
    #endif

    private let targetLetters = ["A", "N"]
    private let morseMap: [Character: String] = [
        "A": ".-",
        "N": "-."
    ]

    @discardableResult
    private func createNewItem() -> String {
        let newLetter = targetLetters.randomElement() ?? "A"
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
            print("[Audio][LevelAN] No audio file found for letter \(first)")
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
            print("[Audio][LevelAN] Failed to play \(url.lastPathComponent): \(error)")
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
        guard let targetChar = letter.uppercased().first,
              let expected = morseMap[targetChar] else {
            lastFeedback = "No target letter"
            return
        }

        if pattern == expected {
            let completedLetter = String(targetChar)
            let updatedCount = min(correctCounts[completedLetter, default: 0] + 1, 5)
            correctCounts[completedLetter] = updatedCount
            inputPattern.removeAll()

            let hasCompletedLevel = targetLetters.allSatisfy { correctCounts[$0, default: 0] >= 5 }
            if hasCompletedLevel {
                isLevelComplete = true
                userProgress.completeLevel(2)
                lastFeedback = "Level Complete!"
            } else {
                lastFeedback = "Correct! \(completedLetter) \(updatedCount)/5"
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
            inputPattern.removeAll()
            lastFeedback = "Incorrect - Try Again!"
            sendToWatch([
                "action": "feedback",
                "result": "incorrect"
            ])

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                if lastFeedback.contains("Incorrect") {
                    lastFeedback = ""
                }
            }
        }
    }

    private func appendSymbol(_ symbol: String) {
        guard inputPattern.count < 4 else { return }
        inputPattern.append(symbol)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 14) {
                HStack {
                    Button {
                        dismiss()
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

                Text("LEVEL A/N")
                    .font(.custom("berkelium bitmap", size: 24))
                    .foregroundStyle(.neon)

                Text("Listen, then tap the Morse code for A or N.")
                    .font(.custom("berkelium bitmap", size: 12))
                    .foregroundStyle(Color.white.opacity(0.82))
                    .multilineTextAlignment(.center)

                HStack(spacing: 18) {
                    Text("A: \(correctCounts["A", default: 0])/5")
                    Text("N: \(correctCounts["N", default: 0])/5")
                }
                .foregroundStyle(.neon)
                .font(.custom("berkelium bitmap", size: 14))

                Text("Letters in play: A  N")
                    .font(.custom("berkelium bitmap", size: 12))
                    .foregroundStyle(Color.white.opacity(0.72))

                if isLevelComplete {
                    Text("Both letters mastered.")
                        .font(.custom("berkelium bitmap", size: 12))
                        .foregroundStyle(.green)
                }

                if !lastFeedback.isEmpty {
                    Text(lastFeedback)
                        .foregroundStyle(lastFeedback.contains("Correct") ? .green : .yellow)
                        .font(.custom("berkelium bitmap", size: 12))
                }

                ZStack {
                    Image("Tube")
                        .resizable()
                        .scaledToFit()

                    Text(letter)
                        .font(.custom("berkelium bitmap", size: 180))
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
                            inputPattern.removeAll()
                        } label: {
                            actionButtonLabel("Clear", fill: Color.white.opacity(0.12), textColor: .white)
                        }
                        .buttonStyle(.plain)

                        Button {
                            submitPattern(inputPattern)
                        } label: {
                            actionButtonLabel("Send", fill: inputPattern.isEmpty ? Color.gray.opacity(0.35) : Color.neon, textColor: inputPattern.isEmpty ? .white.opacity(0.7) : .black)
                        }
                        .buttonStyle(.plain)
                        .disabled(inputPattern.isEmpty)
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
                  action == "morseInput",
                  let pattern = userInfo["pattern"] as? String else { return }
            submitPattern(pattern)
        }
    }

    private func morseButton(title: String, symbol: String) -> some View {
        Button {
            appendSymbol(symbol)
        } label: {
            VStack(spacing: 8) {
                Text(symbol)
                    .font(.custom("berkelium bitmap", size: 28))
                    .foregroundStyle(.black)

                Text(title)
                    .font(.custom("berkelium bitmap", size: 10))
                    .foregroundStyle(.black.opacity(0.78))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 96)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.neon)
            )
        }
        .buttonStyle(.plain)
    }

    private func actionButtonLabel(_ title: String, fill: Color, textColor: Color) -> some View {
        Text(title)
            .font(.custom("berkelium bitmap", size: 12))
            .foregroundStyle(textColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(fill)
            )
    }
}

#Preview {
    LevelAN()
        .environmentObject(UserProgress())
        .environmentObject(MorseEngine())
}
