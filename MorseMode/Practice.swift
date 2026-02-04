//
//  Practice.swift
//  MorseMode
//
//  Created by Ishauna Marie Alexander on 1/28/26.
//

import SwiftUI

struct Practice: View {
    
    @ObservedObject var morseEngine: MorseEngine
    
    @State private var letterToShow: String = ""
            
    @State private var tappedImageName: String = "ImageA"
    
    let letter: Letter
            
    var body: some View {
        
        ZStack{
                Color.black
                    .ignoresSafeArea()
            VStack{
                ZStack{
                    Image("Tube")
                        .resizable()
                        .scaledToFit()
                        .overlay(
                            Group{
                                if !letterToShow.isEmpty {
                                    Text(letterToShow)
                                        .font(.custom("berkelium bitmap", size: 200))
                                        .foregroundStyle(.neonGreen)
                                }
                            }
                        )
                }
                HStack{
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                            Text("A")
                            .font(.custom("berkelium bitmap", size: 20))
                                .foregroundStyle(.neonGreen)
                    }
                    .onTapGesture {
                        morseEngine.performHaptic(for: .a)
                        self.letterToShow = "A"
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                            Text("B")
                            .font(.custom("berkelium bitmap", size: 20))
                                .foregroundStyle(.neonGreen)
                    }
                    .onTapGesture {
                        morseEngine.performHaptic(for: .b)
                        self.letterToShow = "B"
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                            Text("C")
                            .font(.custom("berkelium bitmap", size: 20))
                                .foregroundStyle(.neonGreen)
                    }
                    .onTapGesture {
                        morseEngine.performHaptic(for: .c)
                        self.letterToShow = "C"
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                            Text("D")
                            .font(.custom("berkelium bitmap", size: 20))
                                .foregroundStyle(.neonGreen)
                    }
                    .onTapGesture {
                        morseEngine.performHaptic(for: .d)
                        self.letterToShow = "D"
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                            Text("E")
                            .font(.custom("berkelium bitmap", size: 20))
                                .foregroundStyle(.neonGreen)
                    }
                    .onTapGesture {
                        morseEngine.performHaptic(for: .e)
                        self.letterToShow = "E"
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                            Text("F")
                            .font(.custom("berkelium bitmap", size: 20))
                                .foregroundStyle(.neonGreen)
                    }
                    .onTapGesture {
                        morseEngine.performHaptic(for: .f)
                        self.letterToShow = "F"
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                            Text("G")
                            .font(.custom("berkelium bitmap", size: 20))
                                .foregroundStyle(.neonGreen)
                    }
                    .onTapGesture {
                        morseEngine.performHaptic(for: .g)
                        self.letterToShow = "G"
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                            Text("H")
                            .font(.custom("berkelium bitmap", size: 20))
                                .foregroundStyle(.neonGreen)
                    }
                    .onTapGesture {
                        morseEngine.performHaptic(for: .h)
                        self.letterToShow = "H"
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                            Text("I")
                            .font(.custom("berkelium bitmap", size: 20))
                                .foregroundStyle(.neonGreen)
                    }
                    .onTapGesture {
                        morseEngine.performHaptic(for: .i)
                        self.letterToShow = "I"
                    }
                }
                
                HStack{
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                            Text("J")
                            .font(.custom("berkelium bitmap", size: 20))
                                .foregroundStyle(.neonGreen)
                    }
                    .onTapGesture {
                        morseEngine.performHaptic(for: .j)
                        self.letterToShow = "J"
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                            Text("K")
                            .font(.custom("berkelium bitmap", size: 20))
                                .foregroundStyle(.neonGreen)
                    }
                    .onTapGesture {
                        morseEngine.performHaptic(for: .k)
                        self.letterToShow = "K"
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                            Text("L")
                            .font(.custom("berkelium bitmap", size: 20))
                                .foregroundStyle(.neonGreen)
                    }
                    .onTapGesture {
                        morseEngine.performHaptic(for: .l)
                        self.letterToShow = "L"
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                            Text("M")
                            .font(.custom("berkelium bitmap", size: 20))
                                .foregroundStyle(.neonGreen)
                    }
                    .onTapGesture {
                        morseEngine.performHaptic(for: .m)
                        self.letterToShow = "M"
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                            Text("N")
                            .font(.custom("berkelium bitmap", size: 20))
                                .foregroundStyle(.neonGreen)
                    }
                    .onTapGesture {
                        morseEngine.performHaptic(for: .n)
                        self.letterToShow = "N"
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                            Text("O")
                            .font(.custom("berkelium bitmap", size: 20))
                                .foregroundStyle(.neonGreen)
                    }
                    .onTapGesture {
                        morseEngine.performHaptic(for: .o)
                        self.letterToShow = "O"
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                            Text("P")
                            .font(.custom("berkelium bitmap", size: 20))
                                .foregroundStyle(.neonGreen)
                    }
                    .onTapGesture {
                        morseEngine.performHaptic(for: .p)
                        self.letterToShow = "P"
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                            Text("Q")
                                .font(.custom("berkelium bitmap", size: 20))
                                .foregroundStyle(.neonGreen)
                    }
                    .onTapGesture {
                        morseEngine.performHaptic(for: .q)
                        self.letterToShow = "Q"
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                            Text("R")
                                .font(.custom("berkelium bitmap", size: 20))
                                .foregroundStyle(.neonGreen)
                    }
                    .onTapGesture {
                        morseEngine.performHaptic(for: .r)
                        self.letterToShow = "R"
                    }
                }
                
                HStack{
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                            Text("S")
                                .font(.custom("berkelium bitmap", size: 20))
                                .foregroundStyle(.neonGreen)
                    }
                    .onTapGesture {
                        morseEngine.performHaptic(for: .s)
                        self.letterToShow = "S"
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                            Text("T")
                                .font(.custom("berkelium bitmap", size: 20))
                                .foregroundStyle(.neonGreen)
                    }
                    .onTapGesture {
                        morseEngine.performHaptic(for: .t)
                        self.letterToShow = "T"
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                            Text("U")
                                .font(.custom("berkelium bitmap", size: 20))
                                .foregroundStyle(.neonGreen)
                    }
                    .onTapGesture {
                        morseEngine.performHaptic(for: .u)
                        self.letterToShow = "U"
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                            Text("V")
                                .font(.custom("berkelium bitmap", size: 20))
                                .foregroundStyle(.neonGreen)
                    }
                    .onTapGesture {
                        morseEngine.performHaptic(for: .v)
                        self.letterToShow = "V"
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                            Text("W")
                                .font(.custom("berkelium bitmap", size: 20))
                                .foregroundStyle(.neonGreen)
                    }
                    .onTapGesture {
                        morseEngine.performHaptic(for: .w)
                        self.letterToShow = "W"
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                            Text("X")
                                .font(.custom("berkelium bitmap", size: 20))
                                .foregroundStyle(.neonGreen)
                    }
                    .onTapGesture {
                        morseEngine.performHaptic(for: .x)
                        self.letterToShow = "X"
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                            Text("Y")
                                .font(.custom("berkelium bitmap", size: 20))
                                .foregroundStyle(.neonGreen)
                    }
                    .onTapGesture {
                        morseEngine.performHaptic(for: .y)
                        self.letterToShow = "Y"
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                            Text("Z")
                                .font(.custom("berkelium bitmap", size: 20))
                                .foregroundStyle(.neonGreen)
                    }
                    .onTapGesture {
                        morseEngine.performHaptic(for: .z)
                        self.letterToShow = "Z"
                    }
                }
            }
        }
    }
}

#Preview {
    let morseEngine = MorseEngine()
    Practice(morseEngine: morseEngine, letter: .a)
}
