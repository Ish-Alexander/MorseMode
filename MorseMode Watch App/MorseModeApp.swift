//
//  MorseModeApp.swift
//  MorseMode Watch App
//
//  Created by Ishauna Marie Alexander on 1/22/26.
//

import SwiftUI
import Foundation
import WatchConnectivity
import Combine

class MorseModeApp: NSObject, ObservableObject, WCSessionDelegate {
    

    static let shared = MorseModeApp()

    override init() {
        super.init()
        activate()
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    func send(_ data: [String: Any]) {
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(data, replyHandler: nil)
        } else {
            print("Watch not reachable")
        }
    }

    func session(_ session: WCSession,
                 didReceiveMessage message: [String : Any]) {
        guard let action = message["action"] as? String else { return }

                if action == "playMorse",
                   let letterString = message["letter"] as? String,
                   let letter = Letter(string: letterString) {

                    MorseEngine.shared.performHaptic(for: letter)
                }

        DispatchQueue.main.async {
            print("Received:", message)
        }
    }

    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {}

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {}
    #endif
}
@main
struct MorseMode_Watch_AppApp: App {
    init() {
        MorseModeApp.shared.activate()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
