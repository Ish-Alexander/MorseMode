//
//  ContentView.swift
//  MorseMode Watch App
//
//  Created by Ishauna Marie Alexander on 1/22/26.
//

import SwiftUI
import WatchConnectivity
import WatchKit

struct ContentView: View {
    @State private var showTapScreen = false

    var body: some View {
        NavigationStack{
            ScrollView{
                VStack {
                    Button(action: {
                        WatchConnectivityManager.shared.open(view: "Daily")
                        WKInterfaceDevice.current().play(.click)
                    }) {
                        VStack {
                            Text("Daily Intercept")
                                .font(.custom("berkelium bitmap", size: 14))
                                .foregroundStyle(Color(.neon))
                        }
                    }
                    Button(action: {
                        WatchConnectivityManager.shared.open(view: "Warehouse")
                        WKInterfaceDevice.current().play(.click)
                    }) {
                        VStack {
                            Text("Warehouse")
                                .font(.custom("berkelium bitmap", size: 14))
                                .foregroundStyle(Color(.neon))
                        }
                    }

                    Button(action: {
                        showTapScreen = true
                        WatchConnectivityManager.shared.open(view: "Agents Journey")
                        WKInterfaceDevice.current().play(.click)
                    }) {
                        VStack {
                            Text("Agents Journey")
                                .font(.custom("berkelium bitmap", size: 14))
                                .foregroundStyle(Color(.neon))
                        }
                    }
                }
            }
            .navigationDestination(isPresented: $showTapScreen) {
                TapScreen()
            }
        }
        .onAppear { _ = WatchConnectivityManager.shared }
//        .padding()
    }
}

#Preview {
    ContentView()
}
