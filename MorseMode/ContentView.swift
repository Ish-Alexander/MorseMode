//
//  ContentView.swift
//  MorseMode
//
//  Created by Ishauna Marie Alexander on 1/22/26.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject private var morseEngine = MorseEngine()
    @EnvironmentObject var userProgress: UserProgress
    
    var body: some View {
    
        NavigationStack{
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
        }
    }
}
#Preview {
    ContentView()
        .environmentObject(UserProgress())
}

