import Foundation
import WatchConnectivity
import Combine

final class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("[WatchConnectivity] sessionDidBecomeInactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("[WatchConnectivity] sessionDidDeactivate — reactivating")
        WCSession.default.activate()
    }
    
    static let shared = WatchConnectivityManager()
    // Creates one global instance

    @Published var isReachable: Bool = false
    // Checks if watch is reachable

    private override init() {
        super.init()
        activate()
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        print("[WatchConnectivity] Activating WCSession...")
        session.activate()
    }

    func sendMorseInput(pattern: String) {
        let payload: [String: Any] = [
            "action": "morseInput",
            "pattern": pattern
        ]
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(payload, replyHandler: nil)
        } else {
            // Fallback path; iPhone may receive via applicationContext when it next wakes
            try? WCSession.default.updateApplicationContext(payload)
        }
    }
    
    func requestOpenView(_ viewName: String) {
        let payload: [String: Any] = [
            "action": "openView",
            "view": viewName
            // Tells watch to switch to a specific screen
        ]
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(payload, replyHandler: nil) { error in
                print("[WatchConnectivity] openView sendMessage error: \(error)")
            }
        } else {
            do {
                try WCSession.default.updateApplicationContext(payload)
            } catch {
                print("[WatchConnectivity] openView updateApplicationContext error: \(error)")
            }
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("[WatchConnectivity] activationDidComplete: state=\(activationState.rawValue), error=\(String(describing: error))")
        DispatchQueue.main.async { [weak self] in
            self?.isReachable = session.isReachable
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        print("[WatchConnectivity] reachability changed: \(session.isReachable)")
        DispatchQueue.main.async { [weak self] in
            self?.isReachable = session.isReachable
            // Watches for when the watch goes online/offline
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("[WatchConnectivity] didReceiveMessage: \(message)")
        handleIncomingPayload(message)
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print("[WatchConnectivity] didReceiveApplicationContext: \(applicationContext)")
        handleIncomingPayload(applicationContext)
    }
    
    private func handleIncomingPayload(_ payload: [String: Any]) {
        // Reads incoming commands
        guard let action = payload["action"] as? String else { return }
        switch action {
        case "playMorse":
            if let letterString = payload["letter"] as? String {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: Notification.Name("WatchPlayMorse"),
                        object: nil,
                        userInfo: ["letter": letterString]
                    )
                }
            }
        case "feedback":
            if let result = payload["result"] as? String {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: Notification.Name("WatchFeedback"),
                        object: nil,
                        userInfo: ["result": result]
                    )
                }
            }
        default:
            print("[WatchConnectivity] Unhandled action: \(action)")
        }
    }
}
