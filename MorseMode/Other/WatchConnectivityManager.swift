import Foundation
import WatchConnectivity
import Combine

final class WatchConnectivityManager: ObservableObject {
    static let shared = WatchConnectivityManager()
    // Creates one global instance

    @Published var isReachable: Bool = false
    // Checks if watch is reachable

    private var cancellable: AnyCancellable?

    private init() {
        cancellable = MorseModePhoneConnectivity.shared.$isReachable
            .receive(on: DispatchQueue.main)
            .assign(to: \.isReachable, on: self)
        activate()
    }

    func activate() {
        MorseModePhoneConnectivity.shared.activate()
        isReachable = MorseModePhoneConnectivity.shared.isReachable
    }

    func sendMorseInput(pattern: String) {
        let payload: [String: Any] = [
            "action": "morseInput",
            "pattern": pattern
        ]
        MorseModePhoneConnectivity.shared.send(payload)
    }
    
    func requestOpenView(_ viewName: String) {
        let payload: [String: Any] = [
            "action": "openView",
            "view": viewName
            // Tells watch to switch to a specific screen
        ]
        MorseModePhoneConnectivity.shared.send(payload)
    }
}
