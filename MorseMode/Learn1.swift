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
        NavigationStack{
            ZStack {
                Color.navy
                    .ignoresSafeArea()
            
                ScrollView {
                    VStack{
                        ForEach(alphabet, id: \.self) {letter in
                            NavigationLink(destination: Learn2(), label:  {
                                ZStack {
                                    Image("Header")
                                    Text(letter)}
                            }
                    )}
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
