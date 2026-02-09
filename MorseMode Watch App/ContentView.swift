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
    var body: some View {
        NavigationStack{
            ScrollView{
                VStack {
                    
                        NavigationLink(destination: TapScreen(), label: {
                            ZStack{
                            Image("Header")
                                .resizable()
                                .scaledToFit()
                            Text("Daily Intercept")
                                    .font(.custom("berkelium bitmap", size: 14))
                            }
                        })
                        .simultaneousGesture(TapGesture().onEnded {
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
                        })
                    
                    
                        NavigationLink(destination: TapScreen(), label: {
                            ZStack{
                            Image("Header")
                                .resizable()
                                .scaledToFit()
                                Text("Agency Academy")
                                    .font(.custom("berkelium bitmap", size: 12))
                            }
                        })
                        .simultaneousGesture(TapGesture().onEnded {
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
                        })
                    
                    
                        NavigationLink(destination: TapScreen(), label: {
                            ZStack {
                            Image("Header")
                                .resizable()
                                .scaledToFit()
                                Text("Warehouse")
                                    .font(.custom("berkelium bitmap", size: 14))
                            }
                        })
                        .simultaneousGesture(TapGesture().onEnded {
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
                        })
                    }
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
