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

private enum AppDestination: Hashable {
    case daily
    case academy
    case warehouse
}

struct ContentView: View {
    @StateObject private var morseEngine = MorseEngine()
    @EnvironmentObject var userProgress: UserProgress

    @StateObject private var connectivity = MorseModeConnectivity.shared
    @State private var path = NavigationPath()

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
                                .foregroundStyle(.neonGreen)
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
                                .foregroundStyle(.neonGreen)
                        }
                    })

                    NavigationLink(destination: Learn1(), label: {
                        ZStack{
                            Image("Header")
                                .resizable()
                                .scaledToFit()
                            Text("Agency Academy")
                                .font(.custom("berkelium bitmap", size: 24))
                                .foregroundStyle(.neonGreen)
                        }
                    })

                    NavigationLink(destination: Practice(morseEngine: MorseEngine(), letter: .a), label: {
                        ZStack {
                            Image("Header")
                                .resizable()
                                .scaledToFit()
                            Text("The Warehouse")
                                .font(.custom("berkelium bitmap", size: 24))
                                .foregroundStyle(.neonGreen)
                        }
                    })
                }
                .padding()
            }
            .onReceive(connectivity.$requestedView.compactMap { $0 }) { requested in
                if let destination = mapRequestedView(requested) {
                    path.append(destination)
                    DispatchQueue.main.async {
                        connectivity.requestedView = nil
                    }
                } else {
                    print("Unknown requested view: \(requested)")
                }
            }
            .navigationDestination(for: AppDestination.self) { destination in
                switch destination {
                case .daily:
                    Daily()
                case .academy:
                    Learn1()
                case .warehouse:
                    Practice(morseEngine: MorseEngine(), letter: .a)
                }
            }
        }
    }

    private func mapRequestedView(_ view: String) -> AppDestination? {
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
    
    // MARK: - Haptics
    private func replayHaptics() {
        // If your MorseEngine exposes a replay method, call it here.
        // Uncomment and implement as needed:
        // morseEngine.replayLastHaptics()

        // Fallback: provide a quick haptic so the button has immediate feedback.
        #if canImport(UIKit)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif
    }
}

#Preview {
    ContentView()
        .environmentObject(UserProgress())
}
