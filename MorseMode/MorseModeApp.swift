//
//  MorseModeApp.swift
//  MorseMode
//
//  Created by Ishauna Marie Alexander on 1/22/26.
//

import SwiftUI
import AVFoundation
import WatchConnectivity
import Combine
import GameKit

#if canImport(UIKit)
import UIKit
#endif

struct SharedDefaults {
    static let suiteName = "com.Ishauna.MorseModeTest"
    static let expKey = "sharedEXP"

    static var store: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    static func setEXP(_ value: Int) {
        store?.set(value, forKey: expKey)
        store?.synchronize()
    }

    static func getEXP() -> Int {
        guard let store else { return 0 }
        if store.object(forKey: expKey) == nil { return 0 }
        return store.integer(forKey: expKey)
    }
}

private struct PersistedProgress: Codable {
    var level: Int
    var currentEXP: Int
    var expNeededForNextLevel: Int
    var completedLevels: [Int]?
}

class UserProgress: ObservableObject {
    private let groupSuite = "com.Ishauna.MorseModeTest"
    private let sharedEXPKey = "sharedEXP"
    private var sharedDefaults: UserDefaults? { UserDefaults(suiteName: groupSuite) }

    private let storageKey = "UserProgress.persisted"

    @Published var level: Int = 1
    @Published var currentEXP: Int = 0
    @Published var expNeededForNextLevel: Int = 100
    @Published var completedLevels: Set<Int> = []

    init() {
        load()
        loadSharedEXPIfAvailable()
    }

    func addEXP(_ amount: Int) {
        guard amount > 0 else { return }
        currentEXP += amount
        checkLevelUp()
        save()
        saveSharedEXP()
    }

    func isLevelCompleted(_ level: Int) -> Bool {
        completedLevels.contains(level)
    }

    func isLevelUnlocked(_ level: Int) -> Bool {
        if level <= 1 {
            return true
        }
        return completedLevels.contains(level - 1)
    }

    func completeLevel(_ level: Int) {
        guard level > 0 else { return }
        let isFirstCompletion = !completedLevels.contains(level)
        completedLevels.insert(level)
        if isFirstCompletion {
            addEXP(journeyEXPReward(for: level))
        } else {
            save()
        }
    }

    private func journeyEXPReward(for level: Int) -> Int {
        switch level {
        case 1...13:
            return 100
        case 14:
            return 150
        default:
            return 0
        }
    }

    private func checkLevelUp() {
        var leveled = false
        while currentEXP >= expNeededForNextLevel {
            currentEXP -= expNeededForNextLevel
            level += 1
            expNeededForNextLevel = Int(Double(expNeededForNextLevel) * 1.5)
            leveled = true
            print("Level Up! New Level: \(level)")
        }
        if leveled {
            save()
            saveSharedEXP()
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        if let decoded = try? JSONDecoder().decode(PersistedProgress.self, from: data) {
            self.level = decoded.level
            self.currentEXP = decoded.currentEXP
            self.expNeededForNextLevel = decoded.expNeededForNextLevel
            if let storedCompleted = decoded.completedLevels {
                self.completedLevels = Set(storedCompleted)
            }
        }
    }

    private func save() {
        let payload = PersistedProgress(
            level: level,
            currentEXP: currentEXP,
            expNeededForNextLevel: expNeededForNextLevel,
            completedLevels: Array(completedLevels).sorted()
        )
        if let data = try? JSONEncoder().encode(payload) {
            UserDefaults.standard.set(data, forKey: storageKey)
            saveSharedEXP()
        }
    }

    private func saveSharedEXP() {
        sharedDefaults?.set(currentEXP, forKey: sharedEXPKey)
        sharedDefaults?.synchronize()
    }

    private func loadSharedEXPIfAvailable() {
        guard let shared = sharedDefaults else { return }
        if shared.object(forKey: sharedEXPKey) != nil {
            let sharedValue = shared.integer(forKey: sharedEXPKey)
            self.currentEXP = sharedValue
        }
    }
}

#if canImport(WatchConnectivity)
final class MorseWatchInputDelegate: NSObject, WCSessionDelegate {
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("[Phone] didReceiveMessage: \(message)")
        if let action = message["action"] as? String, action == "morseInput",
           let pattern = message["pattern"] as? String {
            print("[Phone] Received morseInput via message: \(pattern)")
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name("MorseModeWatchInput"), object: nil, userInfo: ["action": action, "pattern": pattern])
                print("[Phone] Posted MorseModeWatchInput notification (message path)")
            }
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        if let action = applicationContext["action"] as? String, action == "morseInput",
           let pattern = applicationContext["pattern"] as? String {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name("MorseModeWatchInput"), object: nil, userInfo: ["action": action, "pattern": pattern])
            }
        }
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
    }

    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
    #endif

    func sessionReachabilityDidChange(_ session: WCSession) {
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }
}
#endif

extension MorseEngine: Observable {}

struct GameCenterLeaderboardRow: Identifiable {
    let id: String
    let rank: Int
    let displayName: String
    let score: Int
    let isCurrentPlayer: Bool
}

final class GameCenterManager: NSObject, ObservableObject {
    static let shared = GameCenterManager()
    static let dailyInterceptLeaderboardID = "daily_intercept_time"

    @Published private(set) var isAuthenticated = false
    @Published private(set) var leaderboardRows: [GameCenterLeaderboardRow] = []
    @Published private(set) var localPlayerRow: GameCenterLeaderboardRow?
    @Published private(set) var lastErrorMessage: String?
    @Published private(set) var isLoadingLeaderboard = false

    private override init() {
        super.init()
    }

    func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { viewController, error in
            if let error {
                DispatchQueue.main.async {
                    self.lastErrorMessage = error.localizedDescription
                    self.isAuthenticated = GKLocalPlayer.local.isAuthenticated
                }
            }

            #if canImport(UIKit)
            if let viewController {
                Self.topViewController()?.present(viewController, animated: true)
                return
            }
            #endif

            DispatchQueue.main.async {
                self.isAuthenticated = GKLocalPlayer.local.isAuthenticated
            }

            if GKLocalPlayer.local.isAuthenticated {
                self.submitTodayIfAvailable()
                self.loadDailyInterceptLeaderboard()
            }
        }
    }

    func submitDailyInterceptTime(seconds: Int) {
        guard GKLocalPlayer.local.isAuthenticated else { return }

        GKLeaderboard.submitScore(
            seconds,
            context: 0,
            player: GKLocalPlayer.local,
            leaderboardIDs: [Self.dailyInterceptLeaderboardID]
        ) { error in
            DispatchQueue.main.async {
                if let error {
                    self.lastErrorMessage = error.localizedDescription
                    return
                }
                self.lastErrorMessage = nil
                self.loadDailyInterceptLeaderboard()
            }
        }
    }

    func submitTodayIfAvailable() {
        guard let completionSeconds = DailyMorseViewModel.completionSecondsForToday() else { return }
        submitDailyInterceptTime(seconds: completionSeconds)
    }

    func loadDailyInterceptLeaderboard() {
        guard GKLocalPlayer.local.isAuthenticated else {
            DispatchQueue.main.async {
                self.isAuthenticated = false
                self.leaderboardRows = []
                self.localPlayerRow = nil
            }
            return
        }

        DispatchQueue.main.async {
            self.isLoadingLeaderboard = true
        }

        GKLeaderboard.loadLeaderboards(IDs: [Self.dailyInterceptLeaderboardID]) { leaderboards, error in
            if let error {
                DispatchQueue.main.async {
                    self.isLoadingLeaderboard = false
                    self.lastErrorMessage = error.localizedDescription
                }
                return
            }

            guard let leaderboard = leaderboards?.first else {
                DispatchQueue.main.async {
                    self.isLoadingLeaderboard = false
                    self.leaderboardRows = []
                    self.localPlayerRow = nil
                    self.lastErrorMessage = "Leaderboard not found. Check the Game Center leaderboard identifier."
                }
                return
            }

            leaderboard.loadEntries(
                for: .global,
                timeScope: .today,
                range: NSRange(location: 1, length: 25)
            ) { localPlayerEntry, entries, _, error in
                if let error {
                    DispatchQueue.main.async {
                        self.isLoadingLeaderboard = false
                        self.lastErrorMessage = error.localizedDescription
                    }
                    return
                }

                let rows = (entries ?? []).map { entry in
                    GameCenterLeaderboardRow(
                        id: entry.player.gamePlayerID,
                        rank: entry.rank,
                        displayName: entry.player.displayName,
                        score: entry.score,
                        isCurrentPlayer: entry.player.gamePlayerID == GKLocalPlayer.local.gamePlayerID
                    )
                }

                let localRow = localPlayerEntry.map { entry in
                    GameCenterLeaderboardRow(
                        id: entry.player.gamePlayerID,
                        rank: entry.rank,
                        displayName: entry.player.displayName,
                        score: entry.score,
                        isCurrentPlayer: true
                    )
                }

                DispatchQueue.main.async {
                    self.isLoadingLeaderboard = false
                    self.lastErrorMessage = nil
                    self.leaderboardRows = rows
                    self.localPlayerRow = localRow
                }
            }
        }
    }

    #if canImport(UIKit)
    private static func topViewController(base: UIViewController? = {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController
    }()) -> UIViewController? {
        if let navigationController = base as? UINavigationController {
            return topViewController(base: navigationController.visibleViewController)
        }
        if let tabBarController = base as? UITabBarController {
            return topViewController(base: tabBarController.selectedViewController)
        }
        if let presentedViewController = base?.presentedViewController {
            return topViewController(base: presentedViewController)
        }
        return base
    }
    #endif
}

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
        GameCenterManager.shared.authenticate()
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
