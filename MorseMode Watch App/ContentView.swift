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
                                    .font(.body)
                            }
                        })
                    
                    
                        NavigationLink(destination: TapScreen(), label: {
                            ZStack{
                            Image("Header")
                                .resizable()
                                .scaledToFit()
                                Text("Agency Academy")
                                    .font(.body)
                            }
                        })
                    
                    
                        NavigationLink(destination: TapScreen(), label: {
                            ZStack {
                            Image("Header")
                                .resizable()
                                .scaledToFit()
                                Text("Warehouse")
                                    .font(.body)
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
