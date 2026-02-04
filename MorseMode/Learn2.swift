//
//  Learn2.swift
//  MorseMode
//
//  Created by Ishauna Marie Alexander on 1/27/26.
//

import SwiftUI
import Foundation
import Combine

struct Learn2: View {
    @EnvironmentObject var userProgress: UserProgress
    @State private var letter: String = ""
    private static let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    
    func createNewItem() {
        letter = String(Self.alphabet.randomElement() ?? " ")
    }
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            VStack{
                
                Text("Level: \(userProgress.level)")
                    .foregroundStyle(.white)
                
                Text("EXP: \(userProgress.currentEXP)")
                    .foregroundStyle(.white)
                
                Image("Tube")
                    .resizable()
                    .scaledToFit()
                
                Image("Radar")
                    .resizable()
                    .frame(width:75, height: 75)
            }
        }
    }
}
class UserProgress: ObservableObject{
    @Published var level: Int = 1
    @Published var currentEXP: Int = 0
    @Published var expNeededForNextLevel: Int = 100
    
    func addEXP(_ amount: Int) {
        currentEXP += amount
        checkLevelUp()
        }
    func checkLevelUp() {
        while currentEXP >= expNeededForNextLevel{
            currentEXP -= expNeededForNextLevel
            level += 1
            expNeededForNextLevel = Int(Double(expNeededForNextLevel) * 1.5)
            print("Level Up! New Level: \(level)")
        }
    }
}
#Preview {
    Learn2()
        .environmentObject(UserProgress())
}

