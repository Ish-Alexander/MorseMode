import SwiftUI
import Combine

final class LevelFlow: ObservableObject {
    @Published var activeLevel: Int? = nil

    func open(_ level: Int) {
        activeLevel = level
    }

    func goToNextLevel() {
        guard let activeLevel else { return }
        self.activeLevel = activeLevel < 14 ? activeLevel + 1 : nil
    }

    func exitToLevelSelect() {
        activeLevel = nil
    }
}

struct ActiveLevelScreen: View {
    @EnvironmentObject private var levelFlow: LevelFlow

    @ViewBuilder
    var body: some View {
        if let activeLevel = levelFlow.activeLevel {
            LevelDestination(levelNumber: activeLevel)
        } else {
            EmptyView()
        }
    }
}

struct LevelDestination: View {
    let levelNumber: Int

    @ViewBuilder
    var body: some View {
        switch levelNumber {
        case 1:
            LevelET()
        case 2:
            LevelAN()
        case 3:
            LevelIM()
        case 4:
            LevelSO()
        case 5:
            LevelDU()
        case 6:
            LevelRK()
        case 7:
            LevelCP()
        case 8:
            LevelBG()
        case 9:
            LevelWL()
        case 10:
            LevelQH()
        case 11:
            LevelZV()
        case 12:
            LevelXJ()
        case 13:
            LevelFY()
        case 14:
            LevelAlphabet()
        default:
            EmptyView()
        }
    }
}
