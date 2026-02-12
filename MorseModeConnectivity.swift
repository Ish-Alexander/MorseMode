#if os(iOS) || targetEnvironment(macCatalyst)
import Foundation
import WatchConnectivity
import Combine
// Renamed to avoid redeclaration conflicts with watchOS counterpart

final class MorseModePhoneConnectivity: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = MorseModePhoneConnectivity()
    
    @Published var requestedView: String?
    
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
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(payload, replyHandler: nil)
        } else {
            do {
                try WCSession.default.updateApplicationContext(payload)
            } catch {
                print("[PhoneConnectivity] updateApplicationContext error: \(error)")
            }
        }
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
            DispatchQueue.main.async {
                self.requestedView = payload["view"] as? String
            }
        case "morseInput":
            NotificationCenter.default.post(name: Notification.Name("MorseModeWatchInput"), object: nil, userInfo: payload)
        case "awardEXP":
            NotificationCenter.default.post(name: Notification.Name("MorseModeAwardEXP"), object: nil, userInfo: payload)
        default:
            print("[PhoneConnectivity] handleIncomingPayload: Unhandled action '\(action)'")
        }
    }
}
#endif
