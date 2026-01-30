//
//  ContentView.swift
//  MorseMode
//
//  Created by Ishauna Marie Alexander on 1/22/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack{
            ZStack {
                Color.navy
                    .ignoresSafeArea()
                VStack {
                    
                    NavigationLink(destination: Daily(), label: {
                        ZStack{
                            Image("Header")
                                .resizable()
                                .scaledToFit()
                            Text("The Daily Intercept")
                                .font(.custom("kkberkbm", size: 24))
                            
                        }
                    })
                    
                    NavigationLink(destination: Learn1(), label: {
                        ZStack{
                            Image("Header")
                                .resizable()
                                .scaledToFit()
                            Text("Agency Academy")
                                .font(.custom("kkberkbm", size: 24))
                        }
                    })
                    
                    NavigationLink(destination: Practice(), label: {
                        ZStack {
                            Image("Header")
                                .resizable()
                                .scaledToFit()
                            Text("The Warehouse")
                                .font(.custom("kkberkbm", size: 24))
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
}
