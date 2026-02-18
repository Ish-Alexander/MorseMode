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
                        WatchConnectivityManager.shared.resendMorse()
                        WKInterfaceDevice.current().play(.click)
                    }) {
                        VStack {
                            Text("Daily Intercept")
                                .font(.custom("berkelium bitmap", size: 14))
                                .foregroundStyle(Color(.neon))
                        }
                    }
                    
                    
                    Button(action: {
                        // Open locally on watch
                        showTapScreen = true
                        WatchConnectivityManager.shared.open(view: "Agency Academy")
                        WKInterfaceDevice.current().play(.click)
                    }) {
                        VStack {
                            Text("Agency Academy")
                                .font(.custom("berkelium bitmap", size: 12))
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
