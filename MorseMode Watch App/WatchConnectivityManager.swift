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
        print("[WatchConnectivity] activateWatchConnectivityIfNeeded activationState=\(session.activationState.rawValue) reachable=\(session.isReachable)")
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
        print("[Watch->Phone] resendMorse tapped reachable=\(WCSession.default.isReachable)")
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(resend, replyHandler: nil) { error in
                print("[Watch->Phone] resendMorse sendMessage FAILED error=\(error)")
                do { try WCSession.default.updateApplicationContext(resend) } catch {
                    print("[Watch->Phone] resendMorse updateApplicationContext FAILED error=\(error)")
                }
            }
        } else {
            do { try WCSession.default.updateApplicationContext(resend) } catch {
                print("[Watch->Phone] resendMorse updateApplicationContext FAILED error=\(error)")
            }
        }
    }

    // MARK: - WCSessionDelegate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("[WatchConnectivity] activationDidComplete state=\(activationState.rawValue) reachable=\(session.isReachable) error=\(String(describing: error))")
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("[Watch<-Phone] didReceiveMessage payload=\(message)")
        handleIncoming(dict: message)
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print("[Watch<-Phone] didReceiveApplicationContext payload=\(applicationContext)")
        handleIncoming(dict: applicationContext)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        print("[Watch<-Phone] didReceiveUserInfo payload=\(userInfo)")
        handleIncoming(dict: userInfo)
    }

    private func playFeedback(result: String) {
        print("[WatchHaptics] playFeedback result=\(result)")
        DispatchQueue.main.async {
            switch result {
            case "correct":
                WKInterfaceDevice.current().play(.success)
            case "incorrect":
                WKInterfaceDevice.current().play(.failure)
            default:
                break
            }
        }
    }

    private func playbackRate(from dict: [String: Any]) -> Double {
        if let rate = dict["playbackRate"] as? Double {
            return rate
        }
        if let rate = dict["playbackRate"] as? NSNumber {
            return rate.doubleValue
        }
        return 1
    }

    private func playMorseClue(_ morse: String, playbackRate: Double = 1) {
        print("[WatchHaptics] playMorseClue morse=\(morse) playbackRate=\(playbackRate)")
        let unit: TimeInterval = 0.15
        let timeScale = 1 / max(playbackRate, 0.01)
        let dot = unit
        let dash = unit * 4
        let intraCharGap = unit
        let interCharGap = unit * 3
        let wordGap = unit * 7
        var delay: TimeInterval = 0

        DispatchQueue.main.async {
            print("[WatchHaptics] start pulse")
            WKInterfaceDevice.current().play(.start)
        }

        for ch in morse {
            switch ch {
            case ".":
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    print("[WatchHaptics] dot at delay=\(delay)")
                    WKInterfaceDevice.current().play(.click)
                }
                delay += (dot + intraCharGap) * timeScale
            case "-":
                let pulseOffsets: [TimeInterval] = [0, 0.08]
                for offset in pulseOffsets {
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay + (offset * timeScale)) {
                        print("[WatchHaptics] dash pulse at delay=\(delay + offset)")
                        WKInterfaceDevice.current().play(.directionUp)
                    }
                }
                delay += (dash + intraCharGap) * timeScale
            case " ":
                delay += interCharGap * timeScale
            case "/":
                delay += wordGap * timeScale
            default:
                break
            }
        }
    }

    private func playWord(_ word: String, playbackRate: Double = 1) {

        var delay: Double = 0
        let timeScale = 1 / max(playbackRate, 0.01)

        for ch in word.uppercased() {

            guard let letter = Letter(string: String(ch)) else { continue }

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                MorseEngine.shared.performHaptic(for: letter, playbackRate: playbackRate)
            }

            delay += 0.5 * timeScale   // spacing between letters (adjust as needed)
        }
    }


    private func handleIncoming(dict: [String: Any]) {
        print("[WatchConnectivity] handleIncoming dict=\(dict)")
        if let action = dict["action"] as? String {
            switch action {
            case "feedback":
                if let result = dict["result"] as? String {
                    print("[WatchConnectivity] action=feedback result=\(result)")
                    playFeedback(result: result)
                    return
                }
            case "playWatchHaptics":
                if let morse = dict["morse"] as? String {
                    print("[WatchConnectivity] action=playWatchHaptics morse=\(morse)")
                    playMorseClue(morse, playbackRate: playbackRate(from: dict))
                    return
                }
            case "playMorse":
                print("[WatchConnectivity] action=playMorse letter=\(dict["letter"] as? String ?? "nil")")
                break
            default:
                print("[WatchConnectivity] unhandled action=\(action)")
                break
            }
        }

        if let result = dict["result"] as? String {
            playFeedback(result: result)
            return
        }

        if let morse = dict["morseClue"] as? String {
            playMorseClue(morse, playbackRate: playbackRate(from: dict))
            return
        }

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
                    MorseEngine.shared.performHaptic(for: l, playbackRate: self.playbackRate(from: dict))
                }
                return
            } else {
                print("[Watch] playMorse: Unable to map letter=\(letterString) to a Letter")
            }
        }
    }
}
