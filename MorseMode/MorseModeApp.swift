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
    // Handles communication between the phone and watch
    @Published var requestedView: String?
    let objectWillChange = ObservableObjectPublisher()

    static let shared = MorseModeConnectivity()
    // Creates one instance across views

    override init() {
        super.init()
        activate()
        // automaically starts connection to watch
    }

    func activate() {
        // Sets up watch connection
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
        // Watches for devices that cannot connect to watch
    }

    func send(_ data: [String: Any]) {
        // Sends a dictionary
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
        _ = _initializePhoneConnectivity()
        print("[App] PhoneConnectivity initialized at launch")
    }
    // Runs when app launches

    @StateObject private var morseEngine = MorseEngine()
    // Creates one engine for whole app
    @StateObject private var userProgress = UserProgress()
    // Tracks user level

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    // Checks if user has seen the onboarding page

    var body: some Scene {
        WindowGroup {
            if hasSeenOnboarding {
                ContentView()
                    .environmentObject(morseEngine)
                    .environmentObject(userProgress)
            } else {
                OnboardingView(items: onboardingData) {
                    hasSeenOnboarding = true
                }
            }
        }
    }
}

