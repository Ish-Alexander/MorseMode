//
//  MorseModeApp.swift
//  MorseMode
//
//  Created by Ishauna Marie Alexander on 1/22/26.
//

import SwiftUI
import Foundation
import WatchConnectivity
import Combine

class MorseModeConnectivity: NSObject, ObservableObject, WCSessionDelegate {
    @Published var requestedView: String?
    let objectWillChange = ObservableObjectPublisher()

    static let shared = MorseModeConnectivity()

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
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) { }

    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
    #endif

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        DispatchQueue.main.async { [weak self] in
            if let action = applicationContext["action"] as? String,
               action == "openView",
               let view = applicationContext["view"] as? String {
                self?.requestedView = view
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async { [weak self] in
            if let action = message["action"] as? String,
               action == "openView",
               let view = message["view"] as? String {
                self?.requestedView = view
            }
        }
    }

    // Optional: handle queued deliveries if using transferUserInfo on the watch
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        DispatchQueue.main.async { [weak self] in
            if let action = userInfo["action"] as? String,
               action == "openView",
               let view = userInfo["view"] as? String {
                self?.requestedView = view
            }
        }
    }
}

@main
struct MorseModeApp: App {
    init() {
        MorseModeConnectivity.shared.activate()
    }

    @StateObject private var morseEngine = MorseEngine()
    @StateObject private var userProgress = UserProgress()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(morseEngine)
                .environmentObject(userProgress)
        }
    }
}

