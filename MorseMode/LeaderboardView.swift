//
//  LeaderboardView.swift
//  MorseMode
//
//  Created by Codex on 4/14/26.
//

import SwiftUI

struct LeaderboardView: View {
    @StateObject private var gameCenter = GameCenterManager.shared

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 18) {
                Image("Leader")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 430)
                    .overlay {
                        Text("LEADERBOARD")
                            .font(.custom("berkelium bitmap", size: 14))
                            .foregroundStyle(.neon)
                            .padding(.horizontal, 90)
                            .offset(y: -4)
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 6)

                VStack(spacing: 8) {
                    Text("Field Ranking")
                        .font(.custom("berkelium bitmap", size: 18))
                        .foregroundStyle(.neon)

                    Text(statusMessage)
                        .font(.custom("berkelium bitmap", size: 11))
                        .foregroundStyle(Color.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        if let localPlayerRow {
                            leaderboardRow(localPlayerRow)
                        }

                        ForEach(otherRows) { entry in
                            leaderboardRow(entry)
                        }

                        if shouldShowEmptyState {
                            leaderboardEmptyState
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 16)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            gameCenter.authenticate()
            gameCenter.submitTodayIfAvailable()
            gameCenter.loadDailyInterceptLeaderboard()
        }
    }

    private var localPlayerRow: GameCenterLeaderboardRow? {
        gameCenter.localPlayerRow ?? gameCenter.leaderboardRows.first(where: \.isCurrentPlayer)
    }

    private var otherRows: [GameCenterLeaderboardRow] {
        gameCenter.leaderboardRows.filter { !$0.isCurrentPlayer }
    }

    private var shouldShowEmptyState: Bool {
        gameCenter.isLoadingLeaderboard || !gameCenter.isAuthenticated || gameCenter.leaderboardRows.isEmpty
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

    private func leaderboardRow(_ entry: GameCenterLeaderboardRow) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(entry.isCurrentPlayer ? Color.neon : Color.white.opacity(0.12))
                    .frame(width: 46, height: 46)

                Text("#\(entry.rank)")
                    .font(.custom("berkelium bitmap", size: 12))
                    .foregroundStyle(entry.isCurrentPlayer ? Color.black : .white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.displayName)
                    .font(.custom("berkelium bitmap", size: 16))
                    .foregroundStyle(entry.isCurrentPlayer ? .neon : .white)

                Text("Daily Intercept  •  \(format(seconds: entry.score))")
                    .font(.custom("berkelium bitmap", size: 10))
                    .foregroundStyle(Color.white.opacity(0.72))
            }

            Spacer(minLength: 0)

            if entry.rank <= 3 {
                Image(systemName: "crown.fill")
                    .foregroundStyle(.yellow)
            } else if entry.isCurrentPlayer {
                Text("YOU")
                    .font(.custom("berkelium bitmap", size: 10))
                    .foregroundStyle(.neon)
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

#Preview {
    LeaderboardView()
        .environmentObject(UserProgress())
}
