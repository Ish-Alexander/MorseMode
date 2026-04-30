//
//  LeaderboardView.swift
//  MorseMode
//
//  Created by Codex on 4/14/26.
//

import SwiftUI

struct LeaderboardView: View {
    @StateObject private var gameCenter = GameCenterManager.shared
    // Game center connectivity

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 18) {
                Text("Leaderboard")
                    .font(.custom("berkelium bitmap", size: 14))
                    .foregroundStyle(.neon)
                    .padding(.top, 6)
                // Title of screen

                Image("Leader")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 430)
                    .padding(.horizontal, 12)

                VStack(spacing: 8) {
                    Text("Field Ranking")
                        .font(.custom("berkelium bitmap", size: 18))
                        .foregroundStyle(.neon)

                    Text(statusMessage)
                        .font(.custom("berkelium bitmap", size: 11))
                        .foregroundStyle(Color.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                    // Shows a message on wha you should do to get a ranking
                }
                .padding(.horizontal, 24)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(rankedRows) { rankedRow in
                            leaderboardRow(rankedRow.entry, placement: rankedRow.placement)
                            // Displays all players
                        }

                        if shouldShowEmptyState {
                            leaderboardEmptyState
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 16)
                }

                myRankingSpot
                    .padding(.horizontal, 18)
                    .padding(.bottom, 12)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            gameCenter.authenticate()
            gameCenter.submitTodayIfAvailable()
            gameCenter.loadDailyInterceptLeaderboard()
        }
    }

    private var rankedRows: [RankedLeaderboardRow] {
        // Builds final list of players
        let entries = ([gameCenter.localPlayerRow].compactMap { $0 } + gameCenter.leaderboardRows)
            .filter(shouldIncludeInLeaderboard)
            .reduce(into: [String: GameCenterLeaderboardRow]()) { bestRowsByPlayerID, entry in
                // Keeps the best score of each player
                guard let existing = bestRowsByPlayerID[entry.id] else {
                    bestRowsByPlayerID[entry.id] = entry
                    return
                }

                if leaderboardPrecedes(entry, existing) || (entry.score == existing.score && entry.isCurrentPlayer) {
                    bestRowsByPlayerID[entry.id] = entry
                }
            }
            .values
            .sorted(by: leaderboardPrecedes)

        return entries.enumerated().map { index, entry in
            RankedLeaderboardRow(entry: entry, placement: index + 1)
            // Shows rank for 1 player
        }
    }

    private var hasPlayedDailyIntercept: Bool {
        DailyMorseViewModel.completionSecondsForToday() != nil
    }

    private func shouldIncludeInLeaderboard(_ entry: GameCenterLeaderboardRow) -> Bool {
        !entry.isCurrentPlayer || entry.rank > 0 || entry.score > 0 || hasPlayedDailyIntercept
    }

    private func shouldShowCrown(for entry: GameCenterLeaderboardRow, placement: Int) -> Bool {
        placement <= 3 && (!entry.isCurrentPlayer || hasPlayedDailyIntercept || entry.rank > 0 || entry.score > 0)
    }

    private func leaderboardPrecedes(_ lhs: GameCenterLeaderboardRow, _ rhs: GameCenterLeaderboardRow) -> Bool {
        if lhs.score != rhs.score {
            return lhs.score < rhs.score
            // Sorts by fastest completion time first
        }

        if sortRank(for: lhs) != sortRank(for: rhs) {
            return sortRank(for: lhs) < sortRank(for: rhs)
        }

        if lhs.incorrectGuesses != rhs.incorrectGuesses {
            return lhs.incorrectGuesses < rhs.incorrectGuesses
        }

        return lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
    }

    private func sortRank(for entry: GameCenterLeaderboardRow) -> Int {
        entry.rank > 0 ? entry.rank : Int.max
    }

    private var shouldShowEmptyState: Bool {
        gameCenter.isLoadingLeaderboard || !gameCenter.isAuthenticated || rankedRows.isEmpty
    }

    private var myRankingRow: RankedLeaderboardRow? {
        rankedRows.first { $0.entry.isCurrentPlayer }
    }

    private var statusMessage: String {
        if gameCenter.isLoadingLeaderboard {
            return "Loading today's Game Center Daily Intercept leaderboard."
        }
        if let message = gameCenter.lastErrorMessage, !message.isEmpty {
            return message
        }
        if !gameCenter.isAuthenticated {
            return "Sign in to Game Center to sync Daily Intercept times across devices."
        }
        return "Track the fastest Daily Intercept completion times from Game Center."
    }

    private var myRankingSpot: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                Text("My Ranking")
                    .font(.custom("berkelium bitmap", size: 12))
                    .foregroundStyle(.neon)

                Text(myRankingMessage)
                    .font(.custom("berkelium bitmap", size: 10))
                    .foregroundStyle(Color.white.opacity(0.72))
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            if let myRankingRow {
                VStack(alignment: .trailing, spacing: 5) {
                    HStack(spacing: 7) {
                        if shouldShowCrown(for: myRankingRow.entry, placement: myRankingRow.placement) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(crownColor(for: myRankingRow.placement))
                        }

                        Text("#\(myRankingRow.placement)")
                            .font(.custom("berkelium bitmap", size: 18))
                            .foregroundStyle(.neon)
                    }

                    Text(format(seconds: myRankingRow.entry.score))
                        .font(.custom("berkelium bitmap", size: 10))
                        .foregroundStyle(Color.white.opacity(0.72))
                }
            } else {
                Text("--")
                    .font(.custom("berkelium bitmap", size: 18))
                    .foregroundStyle(Color.white.opacity(0.42))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.neon.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.neon.opacity(0.75), lineWidth: 1.5)
                )
        )
    }

    private var myRankingMessage: String {
        if gameCenter.isLoadingLeaderboard {
            return "Checking your current Daily Intercept position."
        }
        if !gameCenter.isAuthenticated {
            return "Sign in to Game Center to see your rank."
        }
        guard let myRankingRow else {
            return "Finish today's intercept to post your time."
        }
        return "\(myRankingRow.entry.displayName)  •  \(format(seconds: myRankingRow.entry.score))"
    }

    private func leaderboardRow(_ entry: GameCenterLeaderboardRow, placement: Int) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(entry.isCurrentPlayer ? Color.neon : Color.white.opacity(0.12))
                    .frame(width: 46, height: 46)

                Text("#\(placement)")
                    .font(.custom("berkelium bitmap", size: 12))
                    .foregroundStyle(entry.isCurrentPlayer ? Color.black : .white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.displayName)
                    .font(.custom("berkelium bitmap", size: 16))
                    .foregroundStyle(entry.isCurrentPlayer ? .neon : .white)

                Text("Daily Intercept  •  \(format(seconds: entry.score))  •  \(entry.incorrectGuesses) wrong")
                    .font(.custom("berkelium bitmap", size: 10))
                    .foregroundStyle(Color.white.opacity(0.72))
            }

            Spacer(minLength: 0)

            if shouldShowCrown(for: entry, placement: placement) {
                Image(systemName: "crown.fill")
                    .foregroundStyle(crownColor(for: placement))
                // Shows a crown for the top 3 placements for players
            } else if entry.isCurrentPlayer {
                Text("YOU")
                    .font(.custom("berkelium bitmap", size: 10))
                    .foregroundStyle(.neon)
              // Makes the current player stand out
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(entry.isCurrentPlayer ? Color.neon.opacity(0.12) : Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(entry.isCurrentPlayer ? Color.neon : Color.white.opacity(0.12), lineWidth: 1.5)
            )
        )
    }

    private func crownColor(for placement: Int) -> Color {
        switch placement {
        case 1:
            return Color(red: 1.0, green: 0.78, blue: 0.18)
        case 2:
            return Color(red: 0.78, green: 0.82, blue: 0.88)
        case 3:
            return Color(red: 0.78, green: 0.46, blue: 0.22)
        default:
            return .clear
            // The color of the crowns
        }
    }

    private var leaderboardEmptyState: some View {
        VStack(spacing: 8) {
            Text(emptyStateTitle)
                .font(.custom("berkelium bitmap", size: 14))
                .foregroundStyle(.white)

            Text(emptyStateBody)
                .font(.custom("berkelium bitmap", size: 10))
                .foregroundStyle(Color.white.opacity(0.68))
                .multilineTextAlignment(.center)
        }
        // Shows what to do instead of a blank screen
        .padding(.horizontal, 18)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    private var emptyStateTitle: String {
        if gameCenter.isLoadingLeaderboard {
            return "Loading Leaderboard"
        }
        if !gameCenter.isAuthenticated {
            return "Game Center Required"
        }
        return "No Other Entries Yet"
    }

    private var emptyStateBody: String {
        if let message = gameCenter.lastErrorMessage, !message.isEmpty {
            return message
        }
        if !gameCenter.isAuthenticated {
            return "Sign in to Game Center and create the Daily Intercept leaderboard in App Store Connect to share scores across devices."
        }
        return "Only real Game Center Daily Intercept times appear here. Finish today's intercept to post your run."
    }

    private func format(seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

private struct RankedLeaderboardRow: Identifiable {
    let entry: GameCenterLeaderboardRow
    let placement: Int

    var id: String { entry.id }
}

#Preview {
    LeaderboardView()
        .environmentObject(UserProgress())
}
