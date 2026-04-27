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

enum PhonePlaybackMode: String, CaseIterable, Identifiable {
    case hapticsOnly
    case soundOnly
    case hapticsAndSound

    var id: String { rawValue }

    var title: String {
        switch self {
        case .hapticsOnly:
            return "Haptics Only"
        case .soundOnly:
            return "Sound Only"
        case .hapticsAndSound:
            return "Haptics and Sound"
        }
    }

    var detail: String {
        switch self {
        case .hapticsOnly:
            return "Feel each Morse pattern without phone audio."
        case .soundOnly:
            return "Play Morse audio without phone vibration."
        case .hapticsAndSound:
            return "Use both phone vibration and audio together."
        }
    }

    var allowsHaptics: Bool {
        self != .soundOnly
    }

    var allowsSound: Bool {
        self != .hapticsOnly
    }
}

@MainActor
final class PlaybackSettings: ObservableObject {
    static let storageKey = "PlaybackSettings.mode"
    static let digitalRainEnabledKey = "PlaybackSettings.digitalRainEnabled"

    @Published var mode: PhonePlaybackMode {
        didSet {
            UserDefaults.standard.set(mode.rawValue, forKey: Self.storageKey)
        }
    }

    @Published var isDigitalRainEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isDigitalRainEnabled, forKey: Self.digitalRainEnabledKey)
        }
    }

    init() {
        mode = PhonePlaybackMode(
            rawValue: UserDefaults.standard.string(forKey: Self.storageKey) ?? ""
        ) ?? .hapticsAndSound
        if UserDefaults.standard.object(forKey: Self.digitalRainEnabledKey) == nil {
            isDigitalRainEnabled = true
        } else {
            isDigitalRainEnabled = UserDefaults.standard.bool(forKey: Self.digitalRainEnabledKey)
        }
    }
}

enum MorseLetterAudio {
    private static let candidateExtensions = ["ogg.mp3", "mp3", "ogg", "wav", "m4a"]

    static func audioURL(for character: Character) -> URL? {
        let upper = String(character).uppercased()
        guard let first = upper.first, first.isLetter else { return nil }

        let baseName = "\(first)_morse_code"
        for ext in candidateExtensions {
            if let url = Bundle.main.url(forResource: baseName, withExtension: ext) {
                return url
            }
        }
        return nil
    }

    static func playbackDuration(for character: Character) -> TimeInterval {
        guard let url = audioURL(for: character) else { return 0 }
        do {
            return try AVAudioPlayer(contentsOf: url).duration
        } catch {
            return 0
        }
    }

    static func stop(_ player: AVAudioPlayer?) -> AVAudioPlayer? {
        player?.stop()
        return nil
    }

    static func play(
        character: Character,
        reusing currentPlayer: AVAudioPlayer?,
        logPrefix: String
    ) -> (player: AVAudioPlayer?, duration: TimeInterval) {
        let upper = String(character).uppercased()
        guard let first = upper.first, first.isLetter else {
            return (stop(currentPlayer), 0)
        }

        guard let url = audioURL(for: first) else {
            return (stop(currentPlayer), 0)
        }

        do {
            if let player = currentPlayer, player.url == url {
                player.currentTime = 0
                player.play()
                return (player, player.duration)
            } else {
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                player.play()
                return (player, player.duration)
            }
        } catch {
            print("[Audio][\(logPrefix)] Failed to play \(url.lastPathComponent): \(error)")
            return (currentPlayer, 0)
        }
    }
}

struct PlaybackSettingsSheet: View {
    @EnvironmentObject private var playbackSettings: PlaybackSettings
    @EnvironmentObject private var morseEngine: MorseEngine
    @Environment(\.dismiss) private var dismiss
    @State private var audioPlayer: AVAudioPlayer?

    private func preview(_ mode: PhonePlaybackMode) {
        if mode.allowsHaptics {
            morseEngine.performHaptic(for: .t)
        }

        if mode.allowsSound {
            let playback = MorseLetterAudio.play(
                character: "T",
                reusing: audioPlayer,
                logPrefix: "PlaybackSettings"
            )
            audioPlayer = playback.player
        } else {
            audioPlayer = MorseLetterAudio.stop(audioPlayer)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Choose how Morse feedback should play on your phone.")
                        .font(.custom("berkelium bitmap", size: 12))
                        .foregroundStyle(Color.white.opacity(0.72))
                        .listRowBackground(Color.black)
                }

                Section("Phone Playback") {
                    ForEach(PhonePlaybackMode.allCases) { mode in
                        Button {
                            playbackSettings.mode = mode
                            preview(mode)
                        } label: {
                            HStack(spacing: 14) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(mode.title)
                                        .font(.custom("berkelium bitmap", size: 15))
                                        .foregroundStyle(.neon)
                                    Text(mode.detail)
                                        .font(.custom("berkelium bitmap", size: 10))
                                        .foregroundStyle(Color.white.opacity(0.72))
                                        .multilineTextAlignment(.leading)
                                }

                                Spacer()

                                Image(systemName: playbackSettings.mode == mode ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 44, weight: .semibold))
                                    .foregroundStyle(playbackSettings.mode == mode ? .neon : Color.white.opacity(0.3))
                            }
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.black)
                    }
                }

                Section("Background") {
                    Toggle(isOn: $playbackSettings.isDigitalRainEnabled) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Digital Rain")
                                .font(.custom("berkelium bitmap", size: 15))
                                .foregroundStyle(.neon)
                            Text("Turn the animated background on or off.")
                                .font(.custom("berkelium bitmap", size: 10))
                                .foregroundStyle(Color.white.opacity(0.72))
                        }
                    }
                    .tint(.neon)
                    .listRowBackground(Color.black)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(.neon)
                }
            }
        }
    }
}

struct JourneyLevelTopBar: View {
    @EnvironmentObject private var levelFlow: LevelFlow
    @EnvironmentObject private var playbackSettings: PlaybackSettings
    @EnvironmentObject private var morseEngine: MorseEngine
    @State private var isShowingPlaybackSettings = false

    var body: some View {
        HStack {
            Button {
                levelFlow.exitToLevelSelect()
            } label: {
                Text("Back")
                    .font(.custom("berkelium bitmap", size: 12))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.neon)
                    )
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                isShowingPlaybackSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.neon)
                    .padding(10)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.neon.opacity(0.85), lineWidth: 1.2)
                    )
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $isShowingPlaybackSettings) {
                PlaybackSettingsSheet()
                    .environmentObject(playbackSettings)
                    .environmentObject(morseEngine)
                    .preferredColorScheme(.dark)
            }
        }
    }
}

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

extension Notification.Name {
    static let dailyInterceptCompleted = Notification.Name("DailyInterceptCompleted")
}

final class GameCenterManager: NSObject, ObservableObject {
    static let shared = GameCenterManager()
    static let dailyInterceptLeaderboardID = "daily_intercept_time"

    @Published private(set) var isAuthenticated = false
    @Published private(set) var leaderboardRows: [GameCenterLeaderboardRow] = []
    @Published private(set) var localPlayerRow: GameCenterLeaderboardRow?
    @Published private(set) var lastErrorMessage: String?
    @Published private(set) var isLoadingLeaderboard = false

    private var pendingCompletionSeconds: Int?

    private override init() {
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDailyInterceptCompleted(_:)),
            name: .dailyInterceptCompleted,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
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
                if let pendingCompletionSeconds = self.pendingCompletionSeconds {
                    self.submitDailyInterceptTime(seconds: pendingCompletionSeconds)
                } else {
                    self.submitTodayIfAvailable()
                }
                self.loadDailyInterceptLeaderboard()
            }
        }
    }

    func submitDailyInterceptTime(seconds: Int) {
        pendingCompletionSeconds = seconds
        guard GKLocalPlayer.local.isAuthenticated else { return }

        optimisticallyUpdateLocalPlayerRow(seconds: seconds)

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
                self.pendingCompletionSeconds = nil
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

    @objc
    private func handleDailyInterceptCompleted(_ notification: Notification) {
        guard let seconds = notification.userInfo?["seconds"] as? Int else { return }
        DispatchQueue.main.async {
            self.submitDailyInterceptTime(seconds: seconds)
        }
    }

    private func optimisticallyUpdateLocalPlayerRow(seconds: Int) {
        guard GKLocalPlayer.local.isAuthenticated else { return }

        let playerID = GKLocalPlayer.local.gamePlayerID
        let displayName = GKLocalPlayer.local.displayName

        if let existingIndex = leaderboardRows.firstIndex(where: { $0.id == playerID }) {
            let existing = leaderboardRows[existingIndex]
            leaderboardRows[existingIndex] = GameCenterLeaderboardRow(
                id: existing.id,
                rank: existing.rank,
                displayName: existing.displayName,
                score: seconds,
                isCurrentPlayer: true
            )
        }

        localPlayerRow = GameCenterLeaderboardRow(
            id: playerID,
            rank: localPlayerRow?.rank ?? leaderboardRows.first(where: { $0.id == playerID })?.rank ?? 0,
            displayName: displayName.isEmpty ? "You" : displayName,
            score: seconds,
            isCurrentPlayer: true
        )
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
    @StateObject private var playbackSettings = PlaybackSettings()

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    // Checks if user has seen the onboarding page

    var body: some Scene {
        WindowGroup {
            if hasSeenOnboarding {
                ContentView()
                    .environmentObject(morseEngine)
                    .environmentObject(userProgress)
                    .environmentObject(playbackSettings)
            } else {
                OnboardingView(items: onboardingData) {
                    hasSeenOnboarding = true
                }
                .environmentObject(playbackSettings)
            }
        }
    }
}
