//
//  Journey.swift
//  MorseMode
//
//  Created by Ishauna Marie Alexander on 4/6/26.
//

import SwiftUI

struct Journey: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var userProgress: UserProgress

    @State private var selectedLevel: Int = 1
    @State private var showLevelET: Bool = false
    @State private var showLevelAN: Bool = false
    @State private var showLevelIM: Bool = false
    @State private var showLevelSO: Bool = false

    private let levels = Array(1...13)

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Image("Leader")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 430)
                    .overlay {
                        Text("AGENTS JOURNEY")
                            .font(.custom("berkelium bitmap", size: 14))
                            .foregroundStyle(.neon)
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                            .padding(.horizontal, 78)
                            .offset(y: -4)
                            .zIndex(1)
                    }
                .padding(.top, 6)
                .padding(.horizontal, 12)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        headerSummary
                        journeyMap
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
                    .padding(.bottom, 16)
                }

                selectedLevelCard
                    .padding(.horizontal, 18)
                    .padding(.bottom, 12)

                footerBar
            }
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $showLevelET) {
            LevelET()
        }
        .fullScreenCover(isPresented: $showLevelAN) {
            LevelAN()
        }
        .fullScreenCover(isPresented: $showLevelIM) {
            LevelIM()
        }
        .fullScreenCover(isPresented: $showLevelSO) {
            LevelSO()
        }
        .onAppear {
            let highestUnlocked = levels.last(where: { userProgress.isLevelUnlocked($0) }) ?? 1
            selectedLevel = min(max(highestUnlocked, 1), levels.count)
        }
    }

    private var headerSummary: some View {
        VStack(spacing: 8) {
            Text("Current Level: \(userProgress.level)")
                .font(.custom("berkelium bitmap", size: 14))
                .foregroundStyle(Color.white.opacity(0.9))
        }
    }

    private var journeyMap: some View {
        GeometryReader { geometry in
            let points = levelPoints(in: geometry.size)

            ZStack {
                JourneyConnector(points: points)
                    .stroke(
                        Color.neon.opacity(0.9),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [10, 10])
                    )

                ForEach(Array(levels.enumerated()), id: \.element) { index, level in
                    let point = points[index]
                    let unlocked = userProgress.isLevelUnlocked(level)
                    let completed = userProgress.isLevelCompleted(level)
                    let isSelected = selectedLevel == level

                    Button {
                        selectedLevel = level
                    } label: {
                        LevelTab(
                            level: level,
                            isUnlocked: unlocked,
                            isSelected: isSelected,
                            isCompleted: completed
                        )
                    }
                    .buttonStyle(.plain)
                    .position(point)
                }
            }
        }
        .frame(height: 1120)
    }

    private var selectedLevelCard: some View {
        let isUnlocked = userProgress.isLevelUnlocked(selectedLevel)
        let isCompleted = userProgress.isLevelCompleted(selectedLevel)

        return VStack(spacing: 10) {
            Text("Selected Level \(selectedLevel)")
                .font(.custom("berkelium bitmap", size: 16))
                .foregroundStyle(.neon)

            Text(statusText(isUnlocked: isUnlocked, isCompleted: isCompleted))
                .font(.custom("berkelium bitmap", size: 14))
                .foregroundStyle(Color.white.opacity(0.78))
                .multilineTextAlignment(.center)

            if selectedLevel == 1 && isUnlocked {
                Button {
                    showLevelET = true
                } label: {
                    actionLabel(title: "Start Level 1", isUnlocked: isUnlocked)
                }
                .buttonStyle(.plain)
            } else if selectedLevel == 2 && isUnlocked {
                Button {
                    showLevelAN = true
                } label: {
                    actionLabel(title: "Start Level 2", isUnlocked: isUnlocked)
                }
                .buttonStyle(.plain)
            } else if selectedLevel == 3 && isUnlocked {
                Button {
                    showLevelIM = true
                } label: {
                    actionLabel(title: "Start Level 3", isUnlocked: isUnlocked)
                }
                .buttonStyle(.plain)
            } else if selectedLevel == 4 && isUnlocked {
                Button {
                    showLevelSO = true
                } label: {
                    actionLabel(title: "Start Level 4", isUnlocked: isUnlocked)
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    selectedLevel = min(selectedLevel, levels.count)
                } label: {
                    actionLabel(
                        title: isUnlocked ? "Start Level \(selectedLevel)" : "Level Locked",
                        isUnlocked: isUnlocked
                    )
                }
                .buttonStyle(.plain)
                .disabled(!isUnlocked)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }

    private func statusText(isUnlocked: Bool, isCompleted: Bool) -> String {
        if isCompleted {
            return "Completed. The next level is now unlocked."
        }
        if isUnlocked {
            return "Unlocked and ready for play."
        }
        return "Locked. Finish the previous level to unlock."
    }

    @ViewBuilder
    private func actionLabel(title: String, isUnlocked: Bool) -> some View {
        Text(title)
            .font(.custom("berkelium bitmap", size: 12))
            .foregroundStyle(isUnlocked ? .black : Color.white.opacity(0.7))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isUnlocked ? Color.neon : Color.white.opacity(0.15))
            )
    }

    private var footerBar: some View {
        ZStack {
            Image("Footer")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 430)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    private func levelPoints(in size: CGSize) -> [CGPoint] {
        let usableWidth = size.width - 110
        let leftX = 55.0
        let rightX = leftX + usableWidth
        let centerX = size.width / 2
        let topInset = 70.0
        let bottomInset = 78.0
        let verticalSpacing = (size.height - topInset - bottomInset) / Double(levels.count - 1)

        return levels.indices.map { index in
            let y = topInset + (Double(index) * verticalSpacing)
            let x: Double

            switch index % 3 {
            case 0:
                x = centerX
            case 1:
                x = leftX
            default:
                x = rightX
            }

            return CGPoint(x: x, y: y)
        }
    }
}

private struct LevelTab: View {
    let level: Int
    let isUnlocked: Bool
    let isSelected: Bool
    let isCompleted: Bool

    var body: some View {
        ZStack {
            Image("Tab")
                .resizable()
                .scaledToFit()
                .frame(width: 96)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(isSelected ? Color.neon : Color.clear, lineWidth: 3)
                        .padding(8)
                )

            VStack(spacing: 4) {
                Text("LEVEL")
                    .font(.custom("berkelium bitmap", size: 10))
                    .foregroundStyle(.black.opacity(0.85))

                Text("\(level)")
                    .font(.custom("berkelium bitmap", size: 24))
                    .foregroundStyle(.black)
            }

            if isCompleted {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.black)
                    .offset(x: 20, y: 4)
            }

            if !isUnlocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 50, weight: .bold))
                    .foregroundStyle(.black)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.75))
                    )
            }
        }
        .scaleEffect(isSelected ? 1.06 : 1)
        .shadow(color: isSelected ? Color.neon.opacity(0.45) : .clear, radius: 10)
    }
}

private struct JourneyConnector: Shape {
    let points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard let first = points.first else { return path }

        path.move(to: first)

        for index in 1..<points.count {
            let previous = points[index - 1]
            let current = points[index]
            let midY = (previous.y + current.y) / 2

            path.addCurve(
                to: current,
                control1: CGPoint(x: previous.x, y: midY),
                control2: CGPoint(x: current.x, y: midY)
            )
        }

        return path
    }
}

#Preview {
    Journey()
        .environmentObject(UserProgress())
}
