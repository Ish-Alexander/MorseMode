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
import UserNotifications

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
            // How is the morse code being presented? Sound, haptics, or both?
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
    // Stores user settings
    static let storageKey = "PlaybackSettings.mode"
    static let digitalRainEnabledKey = "PlaybackSettings.digitalRainEnabled"

    @Published var mode: PhonePlaybackMode {
        didSet {
            UserDefaults.standard.set(mode.rawValue, forKey: Self.storageKey)
        }
        // Remembers settings even when the app closes
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

final class DailyNotificationManager {
    static let shared = DailyNotificationManager()
    // Notification controls

    private let center = UNUserNotificationCenter.current()
    private let notificationIdentifierPrefix = "MorseMode.dailyPracticeReminder"
    private let reminderHour = 7
    private let reminderMinute = 0
    // What time the notification pops up
    private let scheduledDayCount = 60
    // How many days in advance it schedules reminders
    private var completionObserver: NSObjectProtocol?

    private init() {
        completionObserver = NotificationCenter.default.addObserver(
            forName: .dailyInterceptCompleted,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            Task {
                await self?.syncWithSavedSetting()
            }
        }
    }

    deinit {
        if let completionObserver {
            NotificationCenter.default.removeObserver(completionObserver)
        }
    }

    func syncWithSavedSetting() async {
        guard ProfileExtras.load().notificationsEnabled else {
            cancelDailyReminders()
            return
        }

        _ = await scheduleDailyReminders()
    }

    func setDailyReminderEnabled(_ isEnabled: Bool) async -> Bool {
        guard isEnabled else {
            cancelDailyReminders()
            return true
        }

        return await scheduleDailyReminders()
    }

    func cancelDailyReminders() {
        center.removePendingNotificationRequests(withIdentifiers: scheduledNotificationIdentifiers())
    }

    private func scheduleDailyReminders() async -> Bool {
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            break
        case .notDetermined:
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                // Tells the phone to ask if the user wants notifications
                guard granted else { return false }
            } catch {
                print("[Notifications] Authorization failed: \(error)")
                return false
            }
        case .denied:
            return false
        @unknown default:
            return false
        }

        cancelDailyReminders()

        for reminderDate in nextReminderDates() {
            let dayKey = dateKey(for: reminderDate)
            guard !isDailyInterceptSolved(on: reminderDate) else { continue }
            // Checks if the daily intercept has been solved
            let content = UNMutableNotificationContent()
            content.title = "Daily Intercept Ready"
            content.body = "Crack today's Daily Intercept or keep leveling up your Morse skills."
            content.sound = .default

            let triggerComponents = Calendar(identifier: .gregorian).dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: reminderDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
            let request = UNNotificationRequest(
                identifier: notificationIdentifier(for: dayKey),
                content: content,
                trigger: trigger
            )

            do {
                try await center.add(request)
            } catch {
                print("[Notifications] Failed to schedule daily reminder: \(error)")
                return false
            }
        }

        return true
    }

    private func nextReminderDates(from now: Date = Date()) -> [Date] {
        let calendar = Calendar(identifier: .gregorian)
        let todayStart = calendar.startOfDay(for: now)
        return (0..<scheduledDayCount).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: todayStart),
                  let reminderDate = calendar.date(bySettingHour: reminderHour, minute: reminderMinute, second: 0, of: day),
                  reminderDate > now
            else { return nil }
            return reminderDate
        }
    }

    private func scheduledNotificationIdentifiers(from date: Date = Date()) -> [String] {
        let calendar = Calendar(identifier: .gregorian)
        let cleanupStart = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: date)) ?? date
        let dayIdentifiers = (0...scheduledDayCount).compactMap { offset -> String? in
            guard let day = calendar.date(byAdding: .day, value: offset, to: cleanupStart) else { return nil }
            return notificationIdentifier(for: dateKey(for: day))
        }

        return [notificationIdentifierPrefix] + dayIdentifiers
    }

    private func notificationIdentifier(for dayKey: String) -> String {
        "\(notificationIdentifierPrefix).\(dayKey)"
    }

    private func isDailyInterceptSolved(on date: Date) -> Bool {
        UserDefaults.standard.bool(forKey: "dailySolved_\(dateKey(for: date))")
    }

    private func dateKey(for date: Date) -> String {
        let calendar = Calendar(identifier: .gregorian)
        let startOfDay = calendar.startOfDay(for: date)
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: startOfDay)
    }
}

enum MorseLetterAudio {
    private static let candidateExtensions = ["ogg.mp3", "mp3", "ogg", "wav", "m4a"]
    // Plays sound file for selected letter

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

    static func playbackDuration(for character: Character, playbackRate: Double = ProfileExtras.load().difficulty.speedMultiplier) -> TimeInterval {
        guard let url = audioURL(for: character) else { return 0 }
        do {
            return try AVAudioPlayer(contentsOf: url).duration / max(playbackRate, 0.01)
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
        logPrefix: String,
        playbackRate: Double = ProfileExtras.load().difficulty.speedMultiplier
    ) -> (player: AVAudioPlayer?, duration: TimeInterval) {
        let upper = String(character).uppercased()
        guard let first = upper.first, first.isLetter else {
            return (stop(currentPlayer), 0)
        }

        guard let url = audioURL(for: first) else {
            return (stop(currentPlayer), 0)
        }

        do {
            let rate = Float(max(playbackRate, 0.01))
            if let player = currentPlayer, player.url == url {
                player.currentTime = 0
                player.enableRate = true
                player.rate = rate
                player.play()
                return (player, player.duration / Double(rate))
            } else {
                let player = try AVAudioPlayer(contentsOf: url)
                player.enableRate = true
                player.rate = rate
                player.prepareToPlay()
                player.play()
                return (player, player.duration / Double(rate))
            }
        } catch {
            print("[Audio][\(logPrefix)] Failed to play \(url.lastPathComponent): \(error)")
            return (currentPlayer, 0)
        }
    }
}

struct JourneyLevelTopBar: View {
    // Top bar inside levels
    @EnvironmentObject private var levelFlow: LevelFlow
    @EnvironmentObject private var userProgress: UserProgress
    @EnvironmentObject private var playbackSettings: PlaybackSettings
    @EnvironmentObject private var morseEngine: MorseEngine
    @State private var isShowingProfileSettings = false

    var body: some View {
        HStack {
            Button {
                levelFlow.exitToLevelSelect()
                // Exits from levels to level map
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
                isShowingProfileSettings = true
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
            .sheet(isPresented: $isShowingProfileSettings) {
                NavigationStack {
                    ProfileView(initiallyShowingSettings: true)
                }
                    .environmentObject(userProgress)
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
        completedLevels.insert(level)
        addEXP(journeyEXPReward(for: level))
    }

    private func journeyEXPReward(for level: Int) -> Int {
        switch level {
        case 1...13:
            return 100
        case 14:
            return 150
        case 15:
            return 200
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

extension MorseEngine: Observable {}

struct GameCenterLeaderboardRow: Identifiable {
    let id: String
    let rank: Int
    let displayName: String
    let score: Int
    let incorrectGuesses: Int
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

    private var pendingCompletion: (seconds: Int, incorrectGuesses: Int)?

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
                if let pendingCompletion = self.pendingCompletion {
                    self.submitDailyInterceptTime(
                        seconds: pendingCompletion.seconds,
                        incorrectGuesses: pendingCompletion.incorrectGuesses
                    )
                } else {
                    self.submitTodayIfAvailable()
                }
                self.loadDailyInterceptLeaderboard()
            }
        }
    }

    func submitDailyInterceptTime(seconds: Int, incorrectGuesses: Int = 0) {
        pendingCompletion = (seconds, incorrectGuesses)
        guard GKLocalPlayer.local.isAuthenticated else { return }

        optimisticallyUpdateLocalPlayerRow(seconds: seconds, incorrectGuesses: incorrectGuesses)

        GKLeaderboard.submitScore(
            seconds,
            context: incorrectGuesses,
            player: GKLocalPlayer.local,
            leaderboardIDs: [Self.dailyInterceptLeaderboardID]
        ) { error in
            DispatchQueue.main.async {
                if let error {
                    self.lastErrorMessage = error.localizedDescription
                    return
                }
                self.pendingCompletion = nil
                self.lastErrorMessage = nil
                self.loadDailyInterceptLeaderboard()
            }
        }
    }

    func submitTodayIfAvailable() {
        guard let completionSeconds = DailyMorseViewModel.completionSecondsForToday() else { return }
        submitDailyInterceptTime(
            seconds: completionSeconds,
            incorrectGuesses: incorrectGuessesForToday()
        )
    }

    private func incorrectGuessesForToday() -> Int {
        let calendar = Calendar(identifier: .gregorian)
        let startOfDay = calendar.startOfDay(for: Date())
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        let suffix = formatter.string(from: startOfDay)
        let key = "dailyWrongGuesses_\(suffix)"
        guard let array = UserDefaults.standard.array(forKey: key) as? [String] else { return 0 }
        return array.count
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
                        incorrectGuesses: entry.context,
                        isCurrentPlayer: entry.player.gamePlayerID == GKLocalPlayer.local.gamePlayerID
                    )
                }

                let localRow = localPlayerEntry.map { entry in
                    GameCenterLeaderboardRow(
                        id: entry.player.gamePlayerID,
                        rank: entry.rank,
                        displayName: entry.player.displayName,
                        score: entry.score,
                        incorrectGuesses: entry.context,
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
        let incorrectGuesses = notification.userInfo?["incorrectGuesses"] as? Int ?? 0
        DispatchQueue.main.async {
            self.submitDailyInterceptTime(seconds: seconds, incorrectGuesses: incorrectGuesses)
        }
    }

    private func optimisticallyUpdateLocalPlayerRow(seconds: Int, incorrectGuesses: Int) {
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
                incorrectGuesses: incorrectGuesses,
                isCurrentPlayer: true
            )
        }

        localPlayerRow = GameCenterLeaderboardRow(
            id: playerID,
            rank: localPlayerRow?.rank ?? leaderboardRows.first(where: { $0.id == playerID })?.rank ?? 0,
            displayName: displayName.isEmpty ? "You" : displayName,
            score: seconds,
            incorrectGuesses: incorrectGuesses,
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

@main
struct MorseModeApp: App {
    init() {
        MorseModePhoneConnectivity.shared.activate()
        GameCenterManager.shared.authenticate()
        Task {
            await DailyNotificationManager.shared.syncWithSavedSetting()
        }
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
