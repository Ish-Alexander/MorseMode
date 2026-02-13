import Foundation
import WatchConnectivity
import AVFoundation
import WatchKit

#if canImport(CoreHaptics)
import CoreHaptics
#endif

// Minimal Morse map for timing on watch
private let watchMorseMap: [Character: String] = [
    "A": ".-",   "B": "-...", "C": "-.-.", "D": "-..",  "E": ".",
    "F": "..-.", "G": "--.",  "H": "....", "I": "..",   "J": ".---",
    "K": "-.-",  "L": ".-..", "M": "--",   "N": "-.",  "O": "---",
    "P": ".--.","Q": "--.-", "R": ".-.",  "S": "...",  "T": "-",
    "U": "..-",  "V": "...-", "W": ".--",  "X": "-..-", "Y": "-.--",
    "Z": "--.."
]

final class WatchMorseController: NSObject, WCSessionDelegate {

    static let shared = WatchMorseController()

    private override init() {
        super.init()
        activate()
    }

    private var session: WCSession? {
        WCSession.isSupported() ? WCSession.default : nil
    }

    func activate() {
        guard let session = session else { return }
        session.delegate = self
        session.activate()
    }

    // MARK: - Playback helpers
    private let unit: TimeInterval = 0.08
    private var dot: TimeInterval { unit }
    private var dash: TimeInterval { unit * 3 }
    private var intraCharGap: TimeInterval { unit }
    private var interCharGap: TimeInterval { unit * 6 }
    private var wordGap: TimeInterval { unit * 7 }

    private func playLetterAudio(_ ch: Character) {
        WatchAudioPlayer.shared.play(letter: ch)
        // Light haptic nudge per letter
        WKInterfaceDevice.current().play(.click)
    }

    private func scheduleWordPlayback(_ word: String) {
        let letters = Array(word.uppercased())
        var start: TimeInterval = 0
        for (i, ch) in letters.enumerated() {
            if ch == " " { start += wordGap; continue }
            DispatchQueue.main.asyncAfter(deadline: .now() + start) {
                self.playLetterAudio(ch)
            }
            if let pattern = watchMorseMap[ch] {
                var letterDuration: TimeInterval = 0
                for (idx, sym) in pattern.enumerated() {
                    letterDuration += (sym == "-" ? self.dash : self.dot)
                    if idx < pattern.count - 1 { letterDuration += self.intraCharGap }
                }
                start += letterDuration
            }
            if i < letters.count - 1 {
                let next = letters[i + 1]
                start += (next == " " ? wordGap : interCharGap)
            }
        }
    }

    // MARK: - WCSessionDelegate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        handleIncoming(message)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        handleIncoming(userInfo)
    }

    private func handleIncoming(_ dict: [String: Any]) {
        if let action = dict["action"] as? String, action == "playMorse", let letterStr = dict["letter"] as? String, let ch = letterStr.uppercased().first {
            // Single letter playback
            DispatchQueue.main.async { self.playLetterAudio(ch) }
            return
        }
        if let clue = dict["morseClue"] as? String {
            // We prefer to schedule per-letter audio based on the target word if provided; otherwise, derive a best-effort from the clue
            if let word = dict["word"] as? String {
                DispatchQueue.main.async { self.scheduleWordPlayback(word) }
            } else {
                // Fallback: attempt to reconstruct word timing from clue by treating spaces as inter-letter and '/' as word gap
                var start: TimeInterval = 0
                DispatchQueue.main.asyncAfter(deadline: .now() + start) {
                    WKInterfaceDevice.current().play(.start)
                }
                for ch in clue {
                    switch ch {
                    case ".": start += dot + intraCharGap
                    case "-": start += dash + intraCharGap
                    case " ": start += (interCharGap - intraCharGap)
                    case "/": start += (wordGap - intraCharGap)
                    default: break
                    }
                }
                // No direct mapping to letters here; this is just a timing alignment for haptics prompt
            }
        }
    }
}
