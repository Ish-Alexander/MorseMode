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
                        let payload: [String: Any] = ["action": "openView", "view": "Daily"]
                        if WCSession.default.isReachable {
                            WCSession.default.sendMessage(payload, replyHandler: nil) { error in
                                print("Send failed: \(error)")
                                do { try WCSession.default.updateApplicationContext(payload) } catch {
                                    print("updateApplicationContext failed: \(error)")
                                }
                            }
                        } else {
                            do { try WCSession.default.updateApplicationContext(payload) } catch {
                                print("updateApplicationContext failed: \(error)")
                            }
                        }
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

                        // Also request the phone to open Agency Academy
                        let payload: [String: Any] = ["action": "openView", "view": "Agency Academy"]
                        if WCSession.default.isReachable {
                            WCSession.default.sendMessage(payload, replyHandler: nil) { error in
                                print("Send failed: \(error)")
                                do { try WCSession.default.updateApplicationContext(payload) } catch {
                                    print("updateApplicationContext failed: \(error)")
                                }
                            }
                        } else {
                            do { try WCSession.default.updateApplicationContext(payload) } catch {
                                print("updateApplicationContext failed: \(error)")
                            }
                        }

                        WKInterfaceDevice.current().play(.click)
                    }) {
                        VStack {
                            Text("Agency Academy")
                                .font(.custom("berkelium bitmap", size: 12))
                                .foregroundStyle(Color(.neon))
                        }
                    }
                    
                    
                    Button(action: {
                        let payload: [String: Any] = ["action": "openView", "view": "Warehouse"]
                        if WCSession.default.isReachable {
                            WCSession.default.sendMessage(payload, replyHandler: nil) { error in
                                print("Send failed: \(error)")
                                do { try WCSession.default.updateApplicationContext(payload) } catch {
                                    print("updateApplicationContext failed: \(error)")
                                }
                            }
                        } else {
                            do { try WCSession.default.updateApplicationContext(payload) } catch {
                                print("updateApplicationContext failed: \(error)")
                            }
                        }
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
//        .padding()
    }
}

#Preview {
    ContentView()
}
