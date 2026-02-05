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
    var incomingSelectedLetter: String?
    @EnvironmentObject var userProgress: UserProgress
    @EnvironmentObject var morseEngine: MorseEngine
    @State private var letter: String = ""
    private static let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    
    func createNewItem() {
        letter = String(Self.alphabet.randomElement() ?? " ")
    }
    
    func playHapticsForCurrentLetter() {
        guard let letterEnum = Letter(string: letter) else { return }
        morseEngine.performHaptic(for: letterEnum)
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
                ZStack{
                    Image("Tube")
                        .resizable()
                        .scaledToFit()
                    
                    Text(letter)
                        .font(.custom("berkelium bitmap", size: 200))
                        .foregroundStyle(.neonGreen)
                        .onAppear {
                            // Sets letter
                            if let incomingSelectedLetter {
                                letter = incomingSelectedLetter
                                playHapticsForCurrentLetter()
                            }
                        }
                        .onChange(of: incomingSelectedLetter) {
                            // Changes letter when selected on previous screen
                            guard let incomingSelectedLetter else { return }
                            letter = incomingSelectedLetter
                            playHapticsForCurrentLetter()
                        }
                }
                Button{
                    playHapticsForCurrentLetter()
                } label: {
                    ZStack{
                            Image("Radar")
                                .resizable()
                                .frame(width:75, height: 75)
                        }
                    }
                }
            .onAppear {
                if let incoming = incomingSelectedLetter, !incoming.isEmpty {
                    letter = String(incoming.prefix(1)).uppercased()
                    playHapticsForCurrentLetter()
                }
            }
            .onChange(of: incomingSelectedLetter) { _, newValue in
                if let newValue, !newValue.isEmpty {
                    letter = String(newValue.prefix(1)).uppercased()
                    playHapticsForCurrentLetter()
                }
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
    Learn2(incomingSelectedLetter: nil)
        .environmentObject(UserProgress())
}

