import SwiftUI
import WatchConnectivity
import WatchKit

final class WatchConnectivityManager: NSObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()

    override init() {
        super.init()
        activateWatchConnectivityIfNeeded()
    }

    private func activateWatchConnectivityIfNeeded() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        if session.activationState != .activated {
            session.activate()
        }
    }

    // MARK: - Public API
    func open(view: String) {
        let payload: [String: Any] = ["action": "openView", "view": view]
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(payload, replyHandler: nil) { error in
                print("Send failed: \(error)")
                do { try WCSession.default.updateApplicationContext(payload) } catch {
                    print("updateApplicationContext failed: \(error)")
                }
            }
        } else {
            do { try WCSession.default.updateApplicationContext(payload) } catch {
                print("updateApplicationContext failed: \(error)")
            }
        }
    }

    func resendMorse() {
        let resend: [String: Any] = ["action": "resendMorse"]
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(resend, replyHandler: nil) { error in
                print("resendMorse send failed: \(error)")
                do { try WCSession.default.updateApplicationContext(resend) } catch {
                    print("resendMorse updateApplicationContext failed: \(error)")
                }
            }
        } else {
            do { try WCSession.default.updateApplicationContext(resend) } catch {
                print("resendMorse updateApplicationContext failed: \(error)")
            }
        }
    }

    // MARK: - WCSessionDelegate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) { }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        handleIncoming(dict: message)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        handleIncoming(dict: userInfo)
    }
    private func playWord(_ word: String) {

        var delay: Double = 0

        for ch in word.uppercased() {

            guard let letter = Letter(string: String(ch)) else { continue }

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                MorseEngine.shared.performHaptic(for: letter)
            }

            delay += 0.5   // spacing between letters (adjust as needed)
        }
    }


    private func handleIncoming(dict: [String: Any]) {
        // 1) Handle the modern payload shape: ["action": "playMorse", "letter": "A"]
        if let action = dict["action"] as? String, action == "playMorse",
           let letterString = dict["letter"] as? String {
            let upper = letterString.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            let letter: Letter? = {
                if let l = Letter(string: upper) { return l }
                guard upper.count == 1, let ch = upper.first else { return nil }
                switch ch {
                case "A": return .a
                case "B": return .b
                case "C": return .c
                case "D": return .d
                case "E": return .e
                case "F": return .f
                case "G": return .g
                case "H": return .h
                case "I": return .i
                case "J": return .j
                case "K": return .k
                case "L": return .l
                case "M": return .m
                case "N": return .n
                case "O": return .o
                case "P": return .p
                case "Q": return .q
                case "R": return .r
                case "S": return .s
                case "T": return .t
                case "U": return .u
                case "V": return .v
                case "W": return .w
                case "X": return .x
                case "Y": return .y
                case "Z": return .z
                default: return nil
                }
            }()
            if let l = letter {
                DispatchQueue.main.async {
                    MorseEngine.shared.performHaptic(for: l)
                }
                return
            } else {
                print("[Watch] playMorse: Unable to map letter=\(letterString) to a Letter")
            }
        }
        // NEW: Play entire word sent from phone
        if let word = dict["word"] as? String {
            playWord(word)
        }
    }
}

