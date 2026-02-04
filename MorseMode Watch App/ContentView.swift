//
//  ContentView.swift
//  MorseMode Watch App
//
//  Created by Ishauna Marie Alexander on 1/22/26.
//

import SwiftUI

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
                    
                    
                        NavigationLink(destination: TapScreen(), label: {
                            ZStack{
                            Image("Header")
                                .resizable()
                                .scaledToFit()
                                Text("Agency Academy")
                                    .font(.custom("berkelium bitmap", size: 12))
                            }
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
                    }
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
