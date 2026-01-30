//
//  Learn1.swift
//  MorseMode
//
//  Created by Ishauna Marie Alexander on 1/27/26.
//

import SwiftUI

let alphabet = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]

struct Learn1: View {
    var body: some View {
        ZStack {
            Color.navy
                .ignoresSafeArea()
            
            ScrollView {
                NavigationStack{
                    VStack{
                        NavigationLink(destination: Learn2(), label:  {
                            ZStack {
                                Image("Header")
                                    .resizable()
                                    .scaledToFit()
                                Text("A")
                            }
                        })
                        
                        NavigationLink(destination: Learn2(), label: {
                            ZStack{
                                Image("Header")
                                    .resizable()
                                    .scaledToFit()
                                Text("B")
                            }
                        })
                        
                        NavigationLink(destination: Learn2(), label: {
                            ZStack{
                                Image("Header")
                                    .resizable()
                                    .scaledToFit()
                                Text("C")
                            }
                        })
                        
                        NavigationLink(destination: Learn2(), label: {
                            ZStack{
                                Image("Header")
                                    .resizable()
                                    .scaledToFit()
                                Text("D")
                            }
                        })
                        
                        NavigationLink(destination: Learn2(), label: {
                            ZStack{
                                Image("Header")
                                    .resizable()
                                    .scaledToFit()
                                Text("E")
                            }
                        })
                        
                        NavigationLink(destination: Learn2(), label: {
                            ZStack{
                                Image("Header")
                                    .resizable()
                                    .scaledToFit()
                                Text("F")
                            }
                        })
                        
                        NavigationLink(destination: Learn2(), label: {
                            ZStack{
                                Image("Header")
                                    .resizable()
                                    .scaledToFit()
                                Text("G")
                            }
                        })
                        
                        NavigationLink(destination: Learn2(), label: {
                            ZStack{
                                Image("Header")
                                    .resizable()
                                    .scaledToFit()
                                Text("H")
                            }
                        })
                        
                        NavigationLink(destination: Learn2(), label: {
                            ZStack{
                                Image("Header")
                                    .resizable()
                                    .scaledToFit()
                                Text("I")
                            }
                        })
                        
                        NavigationLink(destination: Learn2(), label: {
                            ZStack{
                                Image("Header")
                                    .resizable()
                                    .scaledToFit()
                                Text("J")
                            }
                        })
                        
                        NavigationLink(destination: Learn2(), label: {
                            ZStack{
                                Image("Header")
                                    .resizable()
                                    .scaledToFit()
                                Text("K")
                            }
                        })
                        
                        NavigationLink(destination: Learn2(), label: {
                            ZStack{
                                Image("Header")
                                    .resizable()
                                    .scaledToFit()
                                Text("L")
                            }
                        })
                        
                        NavigationLink(destination: Learn2(), label: {
                            ZStack{
                                Image("Header")
                                    .resizable()
                                    .scaledToFit()
                                Text("M")
                            }
                        })
                        
                        NavigationLink(destination: Learn2(), label: {
                            ZStack{
                                Image("Header")
                                    .resizable()
                                    .scaledToFit()
                                Text("N")
                            }
                        })
                        
                        NavigationLink(destination: Learn2(), label: {
                            ZStack{
                                Image("Header")
                                    .resizable()
                                    .scaledToFit()
                                Text("O")
                            }
                        })
                        
                        NavigationLink(destination: Learn2(), label: {
                            ZStack{
                                Image("Header")
                                    .resizable()
                                    .scaledToFit()
                                Text("P")
                            }
                        })
                        
                        NavigationLink(destination: Learn2(), label: {
                            ZStack{
                                Image("Header")
                                    .resizable()
                                    .scaledToFit()
                                Text("Q")
                            }
                        })
                        
                        NavigationLink(destination: Learn2(), label: {
                            ZStack{
                                Image("Header")
                                    .resizable()
                                    .scaledToFit()
                                Text("R")
                            }
                        })
                        
                        NavigationLink(destination: Learn2(), label: {
                            ZStack{
                                Image("Header")
                                    .resizable()
                                    .scaledToFit()
                                Text("S")
                            }
                        })
                        
                        NavigationLink(destination: Learn2(), label: {
                            ZStack{
                                Image("Header")
                                    .resizable()
                                    .scaledToFit()
                                Text("T")
                            }
                        })
                        
                        NavigationLink(destination: Learn2(), label: {
                            ZStack{
                                Image("Header")
                                    .resizable()
                                    .scaledToFit()
                                Text("U")
                            }
                        })
                        
                        NavigationLink(destination: Learn2(), label: {
                            ZStack{
                                Image("Header")
                                    .resizable()
                                    .scaledToFit()
                                Text("V")
                            }
                        })
                        
                        NavigationLink(destination: Learn2(), label: {
                            ZStack{
                                Image("Header")
                                    .resizable()
                                    .scaledToFit()
                                Text("W")
                            }
                        })
                        
                        NavigationLink(destination: Learn2(), label: {
                            ZStack{
                                Image("Header")
                                    .resizable()
                                    .scaledToFit()
                                Text("X")
                            }
                        })
                        
                        NavigationLink(destination: Learn2(), label: {
                            ZStack{
                                Image("Header")
                                    .resizable()
                                    .scaledToFit()
                                Text("Y")
                            }
                        })
                        
                        NavigationLink(destination: Learn2(), label: {
                            ZStack{
                                Image("Header")
                                    .resizable()
                                    .scaledToFit()
                                Text("Z")
                            }
                        })
                        
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack{
        Learn1()
    }
}
