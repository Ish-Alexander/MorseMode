//
//  MorseModeApp.swift
//  MorseMode
//
//  Created by Ishauna Marie Alexander on 1/22/26.
//

import SwiftUI



@main
struct MorseModeApp: App {
    
    @StateObject private var morseEngine = MorseEngine()
    @StateObject private var userProgress = UserProgress()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(morseEngine)
                .environmentObject(userProgress)
        }
    }
}
