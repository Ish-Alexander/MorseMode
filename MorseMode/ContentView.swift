//
//  ContentView.swift
//  MorseMode
//
//  Created by Ishauna Marie Alexander on 1/22/26.
//

import SwiftUI
import WatchConnectivity
import Combine

// Define destinations you can navigate to programmatically
private enum AppDestination: Hashable {
    case daily
    case academy
    case warehouse
}

struct ContentView: View {
    @StateObject private var morseEngine = MorseEngine()
    @EnvironmentObject var userProgress: UserProgress

    // Observe the shared connectivity singleton
    @StateObject private var connectivity = MorseModeConnectivity.shared
    // Path for programmatic navigation
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
                            Text("Level: \(userProgress.level)")
                                .font(.custom("Berkelium Bitmap", size: 18))
                                .bold()
                                .foregroundStyle(.neonGreen)
                        }
                    }

                    // Your existing links remain usable locally
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
            // Listen for requests coming from the watch
            .onReceive(connectivity.$requestedView.compactMap { $0 }) { requested in
                if let destination = mapRequestedView(requested) {
                    // Push the destination
                    path.append(destination)
                    // Reset so the same request can trigger again
                    DispatchQueue.main.async {
                        connectivity.requestedView = nil
                    }
                } else {
                    // Helpful debug if strings don't match
                    print("Unknown requested view: \(requested)")
                }
            }
            // Define the destinations for programmatic navigation
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

    // Map the strings coming from the watch to your destinations
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
}

#Preview {
    ContentView()
        .environmentObject(UserProgress())
}
