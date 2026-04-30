import Foundation
import WatchConnectivity

final class PhoneConnectivity {
    static let shared = PhoneConnectivity()

    private init() {
        activate()
    }

    func activate() {
        MorseModePhoneConnectivity.shared.activate()
    }
}

// Initialize early (ensure this file is loaded by the app target)
@discardableResult
func _initializePhoneConnectivity() -> MorseModePhoneConnectivity {
    MorseModePhoneConnectivity.shared.activate()
    return MorseModePhoneConnectivity.shared
}
