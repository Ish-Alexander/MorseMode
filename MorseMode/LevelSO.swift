//
//  LevelSO.swift
//  MorseMode
//
//  Created by Ishauna Marie Alexander on 4/9/26.
//

import SwiftUI
import WatchConnectivity
import AVFoundation

struct LevelSO: View {
    @EnvironmentObject private var userProgress: UserProgress
    @EnvironmentObject private var morseEngine: MorseEngine
    @EnvironmentObject private var playbackSettings: PlaybackSettings
    @EnvironmentObject private var levelFlow: LevelFlow

    @State private var letter: String = ""
    @State private var inputPattern: String = ""
    @State private var lastFeedback: String = ""
    @State private var rotationAngle: Double = 0
    @State private var audioPlayer: AVAudioPlayer? = nil
    @State private var correctCounts: [String: Int] = [
        "S": 0,
        "O": 0
    ]
    @State private var isLevelComplete: Bool = false

    #if canImport(WatchConnectivity)
        private let watchDelegate = MorseWatchInputDelegate()
    #endif

    private let targetLetters = ["S", "O"]
    private let morseMap: [Character: String] = [
        "S": "...",
        "O": "---"
    ]

    @discardableResult
    private func createNewItem() -> String {
        let remainingLetters = targetLetters.filter { correctCounts[$0, default: 0] < 5 }
        let newLetter = remainingLetters.randomElement() ?? targetLetters.randomElement() ?? "S"
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
            logPrefix: "LevelSO"
        )
        audioPlayer = playback.player
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
                userProgress.completeLevel(4)
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
        guard !isLevelComplete else { return }
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

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 14) {
                JourneyLevelTopBar()

                Text("LEVEL 4")
                    .font(.custom("berkelium bitmap", size: 24))
                    .foregroundStyle(.neon)

                HStack(spacing: 18) {
                    Text("S: \(correctCounts["S", default: 0])/5")
                    Text("O: \(correctCounts["O", default: 0])/5")
                }
                .foregroundStyle(.neon)
                .font(.custom("berkelium bitmap", size: 14))

                Text("Letters in play: S  O")
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
                        .font(.custom("berkelium bitmap", size: isLevelComplete ? 108 : 160))
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
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
                        Image(systemName: "play.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.neon)
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
                        .disabled(inputPattern.isEmpty)
                        .opacity(inputPattern.isEmpty ? 0.45 : 1)
                        
                        Button {
                                                   inputPattern.removeAll()
                                               } label: {
                                                   actionButtonLabel("Clear", fill: Color.yellow.opacity(0.12), textColor: .yellow)
                                               }
                                               .buttonStyle(.plain)
                                               .opacity(inputPattern.isEmpty ? 0.45 : 1)
                    }
                }

                Spacer(minLength: 0)

                if isLevelComplete {
                    Button {
                        levelFlow.goToNextLevel()
                    } label: {
                        actionButtonLabel("Continue to Next Level", fill: Color.neon, textColor: .black)
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
                .background(Color.neon)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isLevelComplete)
        .opacity(isLevelComplete ? 0.45 : 1)
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
    LevelSO()
        .environmentObject(UserProgress())
        .environmentObject(MorseEngine())
        .environmentObject(PlaybackSettings())
        .environmentObject(LevelFlow())
}
