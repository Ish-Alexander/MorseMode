//
//  ContentView.swift
//  MorseMode
//
//  Created by Ishauna Marie Alexander on 1/22/26.
//

import SwiftUI
import WatchConnectivity
import Combine

#if canImport(UIKit)
import UIKit
#endif

private struct IsInOnboardingKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var isInOnboarding: Bool {
        get { self[IsInOnboardingKey.self] }
        set { self[IsInOnboardingKey.self] = newValue }
    }
}

private enum AppDestination: Hashable {
    // Defines possible destinations
    case daily
    case academy
    case warehouse
}

struct ContentView: View {
    @StateObject private var morseEngine = MorseEngine()
    // Manages Morse code logic
    @EnvironmentObject var userProgress: UserProgress
    // Shared global data

    @StateObject private var connectivity = MorseModePhoneConnectivity.shared
    // Connects phone to watch
    @State private var path = NavigationPath()
    
    // Set Environment(\.isInOnboarding) = true from your Onboarding view to disable watch-driven navigation while onboarding is active.
    @State private var isInOnboarding: Bool = false

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                VStack {
                    HStack(alignment: .top){
                        ZStack{
                            
                            Image("Level")
                                .resizable()
                                .scaledToFit()
                                .font(.largeTitle)
                            
                            Image("Icon")
                                .resizable()
                                .scaledToFit()
                                .offset(x: -109, y: -10)
                                .frame(width: 90)
                            
                            Text("Level: \(userProgress.level)")
                                .font(.custom("Berkelium Bitmap", size: 18))
                                .bold()
                                .foregroundStyle(.neon)
                                .offset(x: 33)
                        }
                    }

                    NavigationLink(destination: Daily(), label: {
                        ZStack{
                            Image("Header")
                                .resizable()
                                .scaledToFit()
                            Text("The Daily Intercept")
                                .font(.custom("berkelium bitmap", size: 22))
                                .foregroundStyle(.neon)
                        }
                    })

                    NavigationLink(destination: Learn2(incomingSelectedLetter: nil), label: {
                        ZStack{
                            Image("Header")
                                .resizable()
                                .scaledToFit()
                            Text("Agency Academy")
                                .font(.custom("berkelium bitmap", size: 24))
                                .foregroundStyle(.neon)
                        }
                    })

                    NavigationLink(destination: Practice(morseEngine: MorseEngine(), letter: .a), label: {
                        ZStack {
                            Image("Header")
                                .resizable()
                                .scaledToFit()
                            Text("The Warehouse")
                                .font(.custom("berkelium bitmap", size: 24))
                                .foregroundStyle(.neon)
                        }
                    })
                }
                .padding()
            }
            .onReceive(connectivity.$requestedView.compactMap { $0 }) { requested in
                // If onboarding is active, ignore watch-driven navigation changes
                guard !isInOnboarding else {
                    DispatchQueue.main.async { connectivity.requestedView = nil }
                    return
                }

                if let destination = mapRequestedView(requested) {
                    // Pop to root first so all screens return to ContentView
                    path = NavigationPath()
                    // Then navigate to the requested destination from root
                    path.append(destination)
                    DispatchQueue.main.async {
                        connectivity.requestedView = nil
                    }
                } else {
                    print("Unknown requested view: \(requested)")
                }
            }
            .navigationDestination(for: AppDestination.self) { destination in
                //Shows matching view
                switch destination {
                case .daily:
                    Daily()
                case .academy:
                    Learn2(incomingSelectedLetter: nil)
                case .warehouse:
                    Practice(morseEngine: MorseEngine(), letter: .a)
                }
            }
        }
        // Propagate onboarding flag so onboarding screens can opt out of watch-driven navigation
        .environment(\.isInOnboarding, isInOnboarding)
    }

    private func mapRequestedView(_ view: String) -> AppDestination? {
        // Converts strings into enum values
        switch view {
        case "Daily":
            return .daily
        case "Agency Academy":
            return .academy
        case "Warehouse":
            return .warehouse
        default:
            return nil
        }
    }
    private func replayHaptics() {
        // Triggers haptic feedback
        #if canImport(UIKit)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif
    }
}

#Preview {
    ContentView()
        .environmentObject(UserProgress())
        .environment(\.isInOnboarding, false)
}

