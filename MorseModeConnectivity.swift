#if os(iOS) || targetEnvironment(macCatalyst)
import Foundation
import WatchConnectivity
import Combine
// Renamed to avoid redeclaration conflicts with watchOS counterpart

final class MorseModePhoneConnectivity: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = MorseModePhoneConnectivity()
    static let resendDailyMorseNotification = Notification.Name("ResendDailyMorse")
    
    @Published var requestedView: String?
    private var lastWatchHapticsPayload: [String: Any]?
    
    private override init() {
        super.init()
        activate()
    }
    
    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        print("[PhoneConnectivity] Activating WCSession...")
        WCSession.default.activate()
    }
    
    func send(_ payload: [String: Any]) {
        let action = payload["action"] as? String ?? "unknown"
        if WCSession.default.isReachable {
            print("[Phone->Watch] sendMessage action=\(action) reachable=true payload=\(payload)")
            WCSession.default.sendMessage(payload, replyHandler: nil)
        } else {
            do {
                print("[Phone->Watch] updateApplicationContext action=\(action) reachable=false payload=\(payload)")
                try WCSession.default.updateApplicationContext(payload)
            } catch {
                print("[Phone->Watch] updateApplicationContext FAILED action=\(action) error=\(error)")
            }
        }
    }

    func sendWatchHaptics(morse: String, word: String) {
        let payload: [String: Any] = [
            "action": "playWatchHaptics",
            "morse": morse,
            "morseClue": morse,
            "word": word
        ]
        lastWatchHapticsPayload = payload
        print("[Phone->Watch] caching watch haptics morse=\(morse) word=\(word)")
        send(payload)
    }
    
    // MARK: - WCSessionDelegate
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("[PhoneConnectivity] activationDidCompleteWith state: \(activationState.rawValue), error: \(String(describing: error))")
        print("[PhoneConnectivity] isReachable: \(session.isReachable)")
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        print("[PhoneConnectivity] sessionReachabilityDidChange isReachable: \(session.isReachable)")
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("[PhoneConnectivity] sessionDidBecomeInactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("[PhoneConnectivity] sessionDidDeactivate")
        WCSession.default.activate()
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("[PhoneConnectivity] didReceiveMessage: \(message)")
        handleIncomingPayload(message)
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print("[PhoneConnectivity] didReceiveApplicationContext: \(applicationContext)")
        handleIncomingPayload(applicationContext)
    }
    
    // MARK: - Private Payload Handling
    
    private func handleIncomingPayload(_ payload: [String: Any]) {
        guard let action = payload["action"] as? String else {
            print("[PhoneConnectivity] handleIncomingPayload: Missing action in payload")
            return
        }
        
        switch action {
        case "openView":
            print("[PhoneConnectivity] handleIncomingPayload openView view=\(payload["view"] as? String ?? "nil")")
            DispatchQueue.main.async {
                self.requestedView = payload["view"] as? String
            }
        case "resendMorse":
            print("[PhoneConnectivity] handleIncomingPayload resendMorse cachedPayloadExists=\(lastWatchHapticsPayload != nil)")
            if let payload = lastWatchHapticsPayload {
                send(payload)
            }
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Self.resendDailyMorseNotification, object: nil)
            }
        case "morseInput":
            print("[PhoneConnectivity] handleIncomingPayload morseInput pattern=\(payload["pattern"] as? String ?? "nil")")
            NotificationCenter.default.post(name: Notification.Name("MorseModeWatchInput"), object: nil, userInfo: payload)
        case "awardEXP":
            print("[PhoneConnectivity] handleIncomingPayload awardEXP amount=\(payload["amount"] as? Int ?? 1)")
            NotificationCenter.default.post(name: Notification.Name("MorseModeAwardEXP"), object: nil, userInfo: payload)
        default:
            print("[PhoneConnectivity] handleIncomingPayload: Unhandled action '\(action)'")
        }
    }
}
#endif
