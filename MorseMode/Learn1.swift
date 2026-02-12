//
//  Learn1.swift
//  MorseMode
//
//  Created by Ishauna Marie Alexander on 1/27/26.
//

import SwiftUI
import WatchConnectivity

let alphabet = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]

struct Learn1: View {
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            ScrollView {
                VStack {
                    ForEach(alphabet, id: \.self) { letter in
                        NavigationLink(destination: Learn2(incomingSelectedLetter: letter)) {
                            ZStack {
                                Image("Header")
                                Text(letter)
                            }
                            .font(.custom("berkelium bitmap", size: 20))
                            .foregroundStyle(.neon)
                        }
                    }
                }
                .padding(.vertical)
            }
        }
    }
}

#Preview {
    NavigationStack {
        Learn1()
    }
}
