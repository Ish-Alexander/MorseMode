//
//  TapScreen.swift
//  MorseMode
//
//  Created by Ishauna Marie Alexander on 1/27/26.
//

import SwiftUI
import WatchKit
import WatchConnectivity

private final class WatchFeedbackSessionDelegate: NSObject, WCSessionDelegate {
    private let morseMap: [Character: String] = [
        "A": ".-",   "B": "-...", "C": "-.-.", "D": "-..",  "E": ".",
        "F": "..-.", "G": "--.",  "H": "....", "I": "..",   "J": ".---",
        "K": "-.-",  "L": ".-..", "M": "--",   "N": "-.",  "O": "---",
        "P": ".--.","Q": "--.-", "R": ".-.",  "S": "...",  "T": "-",
        "U": "..-",  "V": "...-", "W": ".--",  "X": "-..-", "Y": "-.--",
        "Z": "--.."
    ]

    private func playMorsePattern(for letter: String) {
        guard let char = letter.uppercased().first, let pattern = morseMap[char] else { return }
        // Immediate haptic to signal new letter arrival
        WKInterfaceDevice.current().play(.start)
        let unit: TimeInterval = 0.15
        let dot = unit
        let dash = unit * 4
        let intra = unit
        var delay: TimeInterval = 0
        for s in pattern {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                if s == "." {
                    WKInterfaceDevice.current().play(.click)
                } else {
                    WKInterfaceDevice.current().play(.directionUp)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                        WKInterfaceDevice.current().play(.directionUp)
                    }
                }
            }
            delay += (s == "." ? dot : dash) + intra
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("[Watch] didReceiveMessage: \(message)")
        if let action = message["action"] as? String, action == "feedback",
           let result = message["result"] as? String {
            print("[Watch] Received feedback: \(result)")
            DispatchQueue.main.async {
                if result == "correct" {
                    WKInterfaceDevice.current().play(.success)
                } else if result == "incorrect" {
                    WKInterfaceDevice.current().play(.failure)
                }
            }
            // If the result is correct, request EXP award on the phone
            if result == "correct" {
                print("[Watch] Sending awardEXP amount=1")
                let payload: [String: Any] = [
                    "action": "awardEXP",
                    "amount": 1
                ]
                if WCSession.default.isReachable {
                    WCSession.default.sendMessage(payload, replyHandler: nil, errorHandler: nil)
                } else {
                    try? WCSession.default.updateApplicationContext(payload)
                }
            }
            return
        }
        if let action = message["action"] as? String, action == "playMorse",
           let letter = message["letter"] as? String {
            print("[Watch] Play morse for letter: \(letter)")
            playMorsePattern(for: letter)
            return
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print("[Watch] didReceiveApplicationContext: \(applicationContext)")
        if let action = applicationContext["action"] as? String, action == "feedback",
           let result = applicationContext["result"] as? String {
            print("[Watch] Received feedback (context): \(result)")
            DispatchQueue.main.async {
                if result == "correct" {
                    WKInterfaceDevice.current().play(.success)
                } else if result == "incorrect" {
                    WKInterfaceDevice.current().play(.failure)
                }
            }
            // If the result is correct, request EXP award on the phone
            if result == "correct" {
                print("[Watch] Sending awardEXP (context) amount=1")
                let payload: [String: Any] = [
                    "action": "awardEXP",
                    "amount": 1
                ]
                if WCSession.default.isReachable {
                    WCSession.default.sendMessage(payload, replyHandler: nil, errorHandler: nil)
                } else {
                    try? WCSession.default.updateApplicationContext(payload)
                }
            }
            return
        }
        if let action = applicationContext["action"] as? String, action == "playMorse",
           let letter = applicationContext["letter"] as? String {
            print("[Watch] Play morse (context) for letter: \(letter)")
            playMorsePattern(for: letter)
            return
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
}

struct TapScreen: View {
    @State private var rotationAngle: Double = 0
    @State private var isPressing = false
    private let hapticType: WKHapticType = .click

    @State private var pattern: String = ""
    private let wcDelegate = WatchFeedbackSessionDelegate()

    private func sendPatternPayload(action: String, pattern: String) {
        let payload: [String: Any] = [
            "action": action,
            "pattern": pattern
        ]

        guard WCSession.isSupported() else {
            print("[Watch] WCSession not supported")
            return
        }

        let session = WCSession.default
        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil) { error in
                print("[Watch] \(action) sendMessage error: \(error)")
            }
            print("[Watch] \(action) sent via sendMessage: \(pattern)")
        } else {
            do {
                try session.updateApplicationContext(payload)
                print("[Watch] \(action) sent via applicationContext: \(pattern)")
            } catch {
                print("[Watch] \(action) updateApplicationContext error: \(error)")
            }
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            // Current pattern preview
            Text(pattern.isEmpty ? "Tap Dot / Dash" : pattern)
                .font(.custom("berkelium bitmap", size: 14))
                .foregroundStyle(pattern.isEmpty ? .gray : .white)
            
            // Dot / Dash controls
            HStack(spacing: 12) {
                Button {
                    pattern.append(".")
                    sendPatternPayload(action: "morsePreview", pattern: pattern)
                    WKInterfaceDevice.current().play(.click)
                } label: {
                    Text("Dot ·")
                        .font(.custom("berkelium bitmap", size: 16))
                        .foregroundStyle(Color(.neon))
                }
                
                Button {
                    pattern.append("-")
                    sendPatternPayload(action: "morsePreview", pattern: pattern)
                    WKInterfaceDevice.current().play(.directionUp)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                        WKInterfaceDevice.current().play(.directionUp)
                    }
                } label: {
                    Text("Dash –")
                        .font(.custom("berkelium bitmap", size: 16))
                        .foregroundStyle(Color(.neon))
                }
            }
            
            // Send / Clear controls
            HStack(spacing: 12) {
                Button {
                    guard !pattern.isEmpty else { return }
                    sendPatternPayload(action: "morseInput", pattern: pattern)
                    WKInterfaceDevice.current().play(.click)
                    pattern.removeAll()
                    sendPatternPayload(action: "morsePreview", pattern: pattern)
                } label: {
                    Text("Send")
                        .font(.custom("berkelium bitmap", size: 16))
                        .foregroundStyle(Color(.neon))
                }
                
                Button {
                    pattern.removeAll()
                    sendPatternPayload(action: "morsePreview", pattern: pattern)
                    WKInterfaceDevice.current().play(.click)
                } label: {
                    Text("Clear")
                        .font(.custom("berkelium bitmap", size: 16))
                        .foregroundStyle(Color(.neon))
                }
            }
        }
            .padding(.top, 75)
            
        .contentMargins(0)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }
}

#Preview{
    TapScreen()
}
