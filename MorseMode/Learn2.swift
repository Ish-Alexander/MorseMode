//
//  Learn2.swift
//  MorseMode
//
//  Created by Ishauna Marie Alexander on 1/27/26.
//

import SwiftUI
import Foundation
import Combine
import WatchConnectivity
import AVFoundation

struct Learn2: View {
    var incomingSelectedLetter: String?
    @EnvironmentObject var userProgress: UserProgress
    // Shared data across the app
    @Environment(MorseEngine.self) private var morseEngine
    // Morse haptics system
    @State private var letter: String = ""
    // Current Letter
    @AppStorage("Learn2_isPracticeMode") private var isPracticeMode: Bool = true
    // Remembers practice mode between launches
    @State private var lastFeedback: String = ""
    // Shows exp gained as feedback
    @State private var rotationAngle: Double = 0
    // Rotates radar image
    @State private var lastExpAwardDate: Date? = nil
    @State private var audioPlayer: AVAudioPlayer? = nil
    // Stores audio player
    #if canImport(WatchConnectivity)
        private let watchDelegate = Learn2WatchDelegate()
    #endif

    // Simple Morse map for validation
    private let morseMap: [Character: String] = [
        // Checks if user inputs the correct morse code
        "A": ".-",   "B": "-...", "C": "-.-.", "D": "-..",  "E": ".",
        "F": "..-.", "G": "--.",  "H": "....", "I": "..",   "J": ".---",
        "K": "-.-",  "L": ".-..", "M": "--",   "N": "-.",  "O": "---",
        "P": ".--.","Q": "--.-", "R": ".-.",  "S": "...",  "T": "-",
        "U": "..-",  "V": "...-", "W": ".--",  "X": "-..-", "Y": "-.--",
        "Z": "--.."
    ]
    private static let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    
    func createNewItem() {
        letter = String(Self.alphabet.randomElement() ?? " ")
        // Picks a random letter
    }
    
    func playHapticsForCurrentLetter() {
        guard let letterEnum = Letter(string: letter) else { return }
        morseEngine.performHaptic(for: letterEnum)
        // Converts letter into enum, asks the engine to play haptics for said letter
    }
    
    func playSoundForCurrentLetter() {
        // Generalized playback: expects files named like "A_morse_code.<ext>" for letters A-Z.
        let upper = letter.uppercased()
        guard let first = upper.first, first.isLetter else {
            audioPlayer?.stop()
            audioPlayer = nil
            return
        }
        let baseName = "\(first)_morse_code"

        // Try a list of possible extensions in order, including the exact "ogg.mp3" case.
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
            print("[Audio] No audio file found for letter \(first). Tried: \(candidateExtensions.map { "\(baseName).\($0)" }.joined(separator: ", "))")
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
            print("[Audio] Failed to play \(url.lastPathComponent): \(error)")
        }
    }

    func sendHapticToWatch(_ letter: Letter) {

        let payload: [String: Any] = [
            "action": "playMorse",
            "letter": String(describing: letter)
        ]

        if WCSession.default.isReachable {
            WCSession.default.sendMessage(payload, replyHandler: nil)
        } else {
            try? WCSession.default.updateApplicationContext(payload)
        }
    }

    private func sendToWatch(_ payload: [String: Any]) {
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(payload, replyHandler: nil)
        } else {
            try? WCSession.default.updateApplicationContext(payload)
        }
    }

    private func handleIncomingMorsePattern(_ pattern: String) {
        print("[Phone] handleIncomingMorsePattern called with: \(pattern)")
        guard isPracticeMode else { return }
        let target = letter.uppercased()
        print("[Phone] Current target letter: \(target)")
        guard let targetChar = target.first, let expected = morseMap[targetChar] else {
            lastFeedback = "No target letter"
            return
        }
        print("[Phone] Expected pattern: \(expected) vs received: \(pattern)")
        if pattern == expected {
            print("[Phone] Pattern correct. Sending feedback: correct")
            lastFeedback = "Correct! +10 EXP"
            // Route EXP awards through a single pathway to avoid double-counting
            NotificationCenter.default.post(name: Notification.Name("MorseModeAwardEXP"), object: nil, userInfo: ["amount": 10])
            let feedbackPayload: [String: Any] = [
                "action": "feedback",
                "result": "correct",
                "amount": 10
                // Checks morse input from watch, sends message if correct
            ]
            sendToWatch(feedbackPayload)
            // Move to a new challenge after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                createNewItem()
                playSoundForCurrentLetter()
                lastFeedback = ""
            }
        } else {
            print("[Phone] Pattern incorrect. Sending feedback: incorrect")
            lastFeedback = "Incorrect - Try Again!"
            let feedbackPayload: [String: Any] = [
                "action": "feedback",
                "result": "incorrect"
                // With incorrect feedback from watch, sends a try again message.
            ]
            sendToWatch(feedbackPayload)
            // Fade the feedback after a moment
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                if lastFeedback.contains("Incorrect") { lastFeedback = "" }
            }
        }
    }
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            VStack{
                Text("Level: \(userProgress.level)")
                    .foregroundStyle(.neon)
                    .font(.custom("berkelium bitmap", size: 16))
                
                Text("EXP: \(userProgress.currentEXP)")
                    .foregroundStyle(.neon)
                    .font(.custom("berkelium bitmap", size: 16))
                
                // EXP Progress toward next level
                VStack(alignment: .leading, spacing: 6) {
                    let progress = min(max(Double(userProgress.currentEXP) / Double(max(userProgress.expNeededForNextLevel, 1)), 0), 1)
                    ProgressView(value: progress) {
                        Text("Next Level Progress")
                            .foregroundStyle(.neon.opacity(0.9))
                            .font(.custom("berkelium bitmap", size: 10))
                    }
                    .tint(.neon)
                    .progressViewStyle(.linear)

                    HStack {
                        Text("\(userProgress.currentEXP) / \(userProgress.expNeededForNextLevel) EXP")
                            .foregroundStyle(.neon.opacity(0.8))
                            .font(.custom("berkelium bitmap", size: 10))
                        Spacer()
                        Text("\(Int(progress * 100))%")
                            .foregroundStyle(.neon.opacity(0.8))
                            .font(.custom("berkelium bitmap", size: 10))
                    }
                }
                .padding(.horizontal)
                .padding(.top, 4)
                
                if !lastFeedback.isEmpty {
                    Text(lastFeedback)
                        .foregroundStyle(lastFeedback.contains("Correct") ? .green : .yellow)
                        .font(.subheadline)
                }
                
                ZStack{
                    Image("Tube")
                        .resizable()
                        .scaledToFit()

                    Text(letter)
                        .font(.custom("berkelium bitmap", size: 200))
                        .foregroundStyle(.neon)
                }
                Button {
                    playHapticsForCurrentLetter()
                    playSoundForCurrentLetter()
                    sendToWatch([
                        "action": "playMorse",
                        "letter": letter
                    ])
                } label: {
                    ZStack {
                        Image("Radar")
                            .resizable()
                            .frame(width: 75, height: 75)
                            .scaledToFit()
                            .ignoresSafeArea()
                            .rotationEffect(.degrees(rotationAngle))
                            .onAppear() {
                                withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false).speed(0.25)) {
                                    rotationAngle = 360
                                }
                            }
                    }
                }
            }
            .onAppear {
                createNewItem()
                playHapticsForCurrentLetter()
                playSoundForCurrentLetter()
                sendToWatch([
                    "action": "playMorse",
                    "letter": letter
                ])
                if WCSession.isSupported() {
                    let session = WCSession.default
                    if session.delegate == nil {
                        session.delegate = watchDelegate
                        print("[Phone] WCSession delegate set to Learn2WatchDelegate")
                    } else {
                        print("[Phone] WCSession delegate already set: \(String(describing: type(of: session.delegate!)))")
                    }
                    session.activate()
                    print("[Phone] WCSession activation requested")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        let payload: [String: Any] = ["action": "ping", "from": "phone"]
                        sendToWatch(payload)
                        print("[Phone] Sent ping to watch")
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("MorseModeWatchInput"))) { notification in
                print("[Phone] Learn2 received MorseModeWatchInput notification: \(String(describing: notification.userInfo))")
                guard isPracticeMode,
                      let userInfo = notification.userInfo as? [String: Any],
                      let action = userInfo["action"] as? String, action == "morseInput",
                      let pattern = userInfo["pattern"] as? String else { return }
                print("[Phone] Learn2 handling pattern: \(pattern)")
                handleIncomingMorsePattern(pattern)
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("MorseModeAwardEXP"))) { notification in
                print("[Phone] Learn2 received MorseModeAwardEXP notification: \(String(describing: notification.userInfo))")
                guard let userInfo = notification.userInfo as? [String: Any] else { return }
                let now = Date()
                if let last = lastExpAwardDate, now.timeIntervalSince(last) < 1.0 {
                    print("[Phone] Debounced EXP award (arrived too soon)")
                    return
                }
                lastExpAwardDate = now
                let amount = userInfo["amount"] as? Int ?? 10
                print("[Phone] Awarding EXP amount: \(amount)")
                userProgress.addEXP(amount)
                lastFeedback = "Awarded +\(amount) EXP"
            }
        }
    }
}

#if canImport(WatchConnectivity)
final class Learn2WatchDelegate: NSObject, WCSessionDelegate {
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("[Phone] didReceiveMessage: \(message)")
        if let action = message["action"] as? String, action == "morseInput",
           let pattern = message["pattern"] as? String {
            print("[Phone] Received morseInput via message: \(pattern)")
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name("MorseModeWatchInput"), object: nil, userInfo: ["action": action, "pattern": pattern])
                print("[Phone] Posted MorseModeWatchInput notification (message path)")
            }
        }
        if let action = message["action"] as? String, action == "awardEXP" {
            let amount = message["amount"] as? Int ?? 10
            print("[Phone] Received awardEXP via message: amount=\(amount)")
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name("MorseModeAwardEXP"), object: nil, userInfo: ["amount": amount])
                print("[Phone] Posted MorseModeAwardEXP notification (message path)")
            }
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        if let action = applicationContext["action"] as? String, action == "morseInput",
           let pattern = applicationContext["pattern"] as? String {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name("MorseModeWatchInput"), object: nil, userInfo: ["action": action, "pattern": pattern])
            }
        }
        if let action = applicationContext["action"] as? String, action == "awardEXP" {
            let amount = applicationContext["amount"] as? Int ?? 10
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name("MorseModeAwardEXP"), object: nil, userInfo: ["amount": amount])
            }
        }
    }

    // WCSessionDelegate logging
    func sessionDidBecomeInactive(_ session: WCSession) {
    }

    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }
}
#endif

/// SharedDefaults provides a tiny convenience API around the App Group UserDefaults
/// so both iOS and watchOS targets can read/write shared values like EXP.
struct SharedDefaults {
    /// Update this to your actual App Group identifier in both targets' capabilities.
    static let suiteName = "group.com.yourcompany.morsemode" // TODO: set your real App Group ID
    static let expKey = "sharedEXP"

    /// Returns the shared UserDefaults for the App Group, or nil if misconfigured.
    static var store: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    /// Saves the EXP value to the shared store.
    static func setEXP(_ value: Int) {
        store?.set(value, forKey: expKey)
        store?.synchronize()
    }

    /// Loads the EXP value from the shared store. Returns 0 if missing/unavailable.
    static func getEXP() -> Int {
        guard let store else { return 0 }
        if store.object(forKey: expKey) == nil { return 0 }
        return store.integer(forKey: expKey)
    }
}

private struct PersistedProgress: Codable {
    var level: Int
    var currentEXP: Int
    var expNeededForNextLevel: Int
}

class UserProgress: ObservableObject{
    private let groupSuite = "group.com.yourcompany.morsemode" // TODO: set your real App Group ID
    private let sharedEXPKey = "sharedEXP"
    private var sharedDefaults: UserDefaults? { UserDefaults(suiteName: groupSuite) }

    private let storageKey = "UserProgress.persisted"
    
    @Published var level: Int = 1
    @Published var currentEXP: Int = 0
    @Published var expNeededForNextLevel: Int = 100
    
    init() {
        load()
        loadSharedEXPIfAvailable()
    }
    
    func addEXP(_ amount: Int) {
        currentEXP += amount
        checkLevelUp()
        save()
        saveSharedEXP()
    }
    
    func checkLevelUp() {
        var leveled = false
        while currentEXP >= expNeededForNextLevel {
            currentEXP -= expNeededForNextLevel
            level += 1
            expNeededForNextLevel = Int(Double(expNeededForNextLevel) * 1.5)
            leveled = true
            print("Level Up! New Level: \(level)")
        }
        if leveled {
            save()
            saveSharedEXP()
            // Level up system
        }
    }
    
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        if let decoded = try? JSONDecoder().decode(PersistedProgress.self, from: data) {
            self.level = decoded.level
            self.currentEXP = decoded.currentEXP
            self.expNeededForNextLevel = decoded.expNeededForNextLevel
        }
    }
    
    private func save() {
        let payload = PersistedProgress(level: level, currentEXP: currentEXP, expNeededForNextLevel: expNeededForNextLevel)
        if let data = try? JSONEncoder().encode(payload) {
            UserDefaults.standard.set(data, forKey: storageKey)
            // Mirror currentEXP to shared App Group so watch/iOS stay in sync
            saveSharedEXP()
        }
    }

    private func saveSharedEXP() {
        sharedDefaults?.set(currentEXP, forKey: sharedEXPKey)
        // synchronize is optional; modern UserDefaults is eventually consistent
        sharedDefaults?.synchronize()
    }

    private func loadSharedEXPIfAvailable() {
        guard let shared = sharedDefaults else { return }
        // Only override if the key exists in the shared container
        if shared.object(forKey: sharedEXPKey) != nil {
            let sharedValue = shared.integer(forKey: sharedEXPKey)
            self.currentEXP = sharedValue
        }
    }
}

extension MorseEngine: Observable {}

#Preview {
    Learn2(incomingSelectedLetter: nil)
        .environmentObject(UserProgress())
        .environment(MorseEngine())
}

