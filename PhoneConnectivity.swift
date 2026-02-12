import Foundation
import WatchConnectivity

final class PhoneConnectivity: NSObject, WCSessionDelegate {
    static let shared = PhoneConnectivity()

    private override init() {
        super.init()
        activate()
    }

    func activate() {
        guard WCSession.isSupported() else {
            print("[PhoneConnectivity] WCSession not supported")
            return
        }
        let session = WCSession.default
        if session.delegate == nil || !(session.delegate is PhoneConnectivity) {
            session.delegate = self
            print("[PhoneConnectivity] WCSession delegate set to PhoneConnectivity")
        } else {
            print("[PhoneConnectivity] WCSession delegate already set: \(String(describing: type(of: session.delegate!)))")
        }
        session.activate()
        print("[PhoneConnectivity] WCSession activation requested")
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("[PhoneConnectivity] didReceiveMessage: \(message)")
        // Forward morseInput to app via notification
        if let action = message["action"] as? String, action == "morseInput",
           let pattern = message["pattern"] as? String {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name("MorseModeWatchInput"), object: nil, userInfo: ["action": action, "pattern": pattern])
                print("[PhoneConnectivity] Posted MorseModeWatchInput notification (message path)")
            }
            return
        }
        // Forward awardEXP to app via notification
        if let action = message["action"] as? String, action == "awardEXP" {
            let amount = message["amount"] as? Int ?? 1
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name("MorseModeAwardEXP"), object: nil, userInfo: ["amount": amount])
                print("[PhoneConnectivity] Posted MorseModeAwardEXP notification (message path)")
            }
            return
        }
        // Catch-all
        print("[PhoneConnectivity] didReceiveMessage (unhandled): \(message)")
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print("[PhoneConnectivity] didReceiveApplicationContext: \(applicationContext)")
        if let action = applicationContext["action"] as? String, action == "morseInput",
           let pattern = applicationContext["pattern"] as? String {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name("MorseModeWatchInput"), object: nil, userInfo: ["action": action, "pattern": pattern])
                print("[PhoneConnectivity] Posted MorseModeWatchInput notification (context path)")
            }
            return
        }
        if let action = applicationContext["action"] as? String, action == "awardEXP" {
            let amount = applicationContext["amount"] as? Int ?? 1
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name("MorseModeAwardEXP"), object: nil, userInfo: ["amount": amount])
                print("[PhoneConnectivity] Posted MorseModeAwardEXP notification (context path)")
            }
            return
        }
        print("[PhoneConnectivity] didReceiveApplicationContext (unhandled): \(applicationContext)")
    }

    // Activation lifecycle
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("[PhoneConnectivity] activationDidComplete: state=\(activationState.rawValue), error=\(String(describing: error))")
        print("[PhoneConnectivity] isReachable after activation: \(session.isReachable)")
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        print("[PhoneConnectivity] didBecomeInactive")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        print("[PhoneConnectivity] didDeactivate; re-activating...")
        WCSession.default.activate()
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        print("[PhoneConnectivity] reachability changed: isReachable=\(session.isReachable)")
    }
}

// Initialize early (ensure this file is loaded by the app target)
@discardableResult
func _initializePhoneConnectivity() -> PhoneConnectivity {
    return PhoneConnectivity.shared
}
