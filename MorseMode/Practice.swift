//
//  Practice.swift
//  MorseMode
//
//  Created by Ishauna Marie Alexander on 1/28/26.
//

import SwiftUI

struct Practice: View {
    
    @ObservedObject var morseEngine: MorseEngine
    
    @State private var showLetter: Bool = false
            
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
                                if showLetter{
                                    Text(letterToShow)
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
                                .onAppear(
                                    perform: morseEngine.prepareEngine
                                )
                                .onTapGesture {
                                    morseEngine.performHaptic(for: .a)
                                    self.showLetter.toggle()
                                    self.letterToShow = self.showLetter ? "A" : ""
                                }
                            Text("A")
                                .foregroundStyle(.neonGreen)
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                                .onTapGesture {
                                    morseEngine.performHaptic(for: .b)
                                    self.showLetter.toggle()
                                    self.letterToShow = self.showLetter ? "B" : ""
                                }
                            Text("B")
                                .foregroundStyle(.neonGreen)
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                                .onTapGesture {
                                    morseEngine.performHaptic(for: .c)
                                    self.showLetter.toggle()
                                    self.letterToShow = self.showLetter ? "C" : ""
                                }
                            Text("C")
                                .foregroundStyle(.neonGreen)
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                                .onTapGesture {
                                    morseEngine.performHaptic(for: .d)
                                    self.showLetter.toggle()
                                    self.letterToShow = self.showLetter ? "D" : ""
                                }
                            Text("D")
                                .foregroundStyle(.neonGreen)
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                                .onTapGesture {
                                    morseEngine.performHaptic(for: .e)
                                    self.showLetter.toggle()
                                    self.letterToShow = self.showLetter ? "E" : ""
                                }
                            Text("E")
                                .foregroundStyle(.neonGreen)
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                                .onTapGesture {
                                    morseEngine.performHaptic(for: .f)
                                    self.showLetter.toggle()
                                    self.letterToShow = self.showLetter ? "F" : ""
                                }
                            Text("F")
                                .foregroundStyle(.neonGreen)
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                                .onTapGesture {
                                    morseEngine.performHaptic(for: .g)
                                    self.showLetter.toggle()
                                    self.letterToShow = self.showLetter ? "G" : ""
                                }
                            Text("G")
                                .foregroundStyle(.neonGreen)
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                                .onTapGesture {
                                    morseEngine.performHaptic(for: .h)
                                    self.showLetter.toggle()
                                    self.letterToShow = self.showLetter ? "H" : ""
                                }
                            Text("H")
                                .foregroundStyle(.neonGreen)
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                                .onTapGesture {
                                    morseEngine.performHaptic(for: .i)
                                    self.showLetter.toggle()
                                    self.letterToShow = self.showLetter ? "I" : ""
                                }
                            Text("I")
                                .foregroundStyle(.neonGreen)
                    }
                }
                
                HStack{
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                                .onTapGesture {
                                    morseEngine.performHaptic(for: .j)
                                    self.showLetter.toggle()
                                    self.letterToShow = self.showLetter ? "J" : ""
                                }
                            Text("J")
                                .foregroundStyle(.neonGreen)
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                                .onTapGesture {
                                    morseEngine.performHaptic(for: .k)
                                    self.showLetter.toggle()
                                    self.letterToShow = self.showLetter ? "K" : ""
                                }
                            Text("K")
                                .foregroundStyle(.neonGreen)
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                                .onTapGesture {
                                    morseEngine.performHaptic(for: .l)
                                    self.showLetter.toggle()
                                    self.letterToShow = self.showLetter ? "L" : ""
                                }
                            Text("L")
                                .foregroundStyle(.neonGreen)
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                                .onTapGesture {
                                    morseEngine.performHaptic(for: .m)
                                    self.showLetter.toggle()
                                    self.letterToShow = self.showLetter ? "M" : ""
                                }
                            Text("M")
                                .foregroundStyle(.neonGreen)
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                                .onTapGesture {
                                    morseEngine.performHaptic(for: .n)
                                    self.showLetter.toggle()
                                    self.letterToShow = self.showLetter ? "N" : ""
                                }
                            Text("N")
                                .foregroundStyle(.neonGreen)
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                                .onTapGesture {
                                    morseEngine.performHaptic(for: .o)
                                    self.showLetter.toggle()
                                    self.letterToShow = self.showLetter ? "O" : ""
                                }
                            Text("O")
                                .foregroundStyle(.neonGreen)
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                                .onTapGesture {
                                    morseEngine.performHaptic(for: .p)
                                    self.showLetter.toggle()
                                    self.letterToShow = self.showLetter ? "P" : ""
                                }
                            Text("P")
                                .foregroundStyle(.neonGreen)
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                                .onTapGesture {
                                    morseEngine.performHaptic(for: .q)
                                    self.showLetter.toggle()
                                    self.letterToShow = self.showLetter ? "Q" : ""
                                }
                            Text("Q")
                                .foregroundStyle(.neonGreen)
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                                .onTapGesture {
                                    morseEngine.performHaptic(for: .r)
                                    self.showLetter.toggle()
                                    self.letterToShow = self.showLetter ? "R" : ""
                                }
                            Text("R")
                                .foregroundStyle(.neonGreen)
                    }
                }
                
                HStack{
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                                .onTapGesture {
                                    morseEngine.performHaptic(for: .s)
                                    self.showLetter.toggle()
                                    self.letterToShow = self.showLetter ? "S" : ""
                                }
                            Text("S")
                                .foregroundStyle(.neonGreen)
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                                .onTapGesture {
                                    morseEngine.performHaptic(for: .t)
                                    self.showLetter.toggle()
                                    self.letterToShow = self.showLetter ? "T" : ""
                                }
                            Text("T")
                                .foregroundStyle(.neonGreen)
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                                .onTapGesture {
                                    morseEngine.performHaptic(for: .u)
                                    self.showLetter.toggle()
                                    self.letterToShow = self.showLetter ? "U" : ""
                                }
                            Text("U")
                                .foregroundStyle(.neonGreen)
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                                .onTapGesture {
                                    morseEngine.performHaptic(for: .v)
                                    self.showLetter.toggle()
                                    self.letterToShow = self.showLetter ? "V" : ""
                                }
                            Text("V")
                                .foregroundStyle(.neonGreen)
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                                .onTapGesture {
                                    morseEngine.performHaptic(for: .w)
                                    self.showLetter.toggle()
                                    self.letterToShow = self.showLetter ? "W" : ""
                                }
                            Text("W")
                                .foregroundStyle(.neonGreen)
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                                .onTapGesture {
                                    morseEngine.performHaptic(for: .x)
                                    self.showLetter.toggle()
                                    self.letterToShow = self.showLetter ? "X" : ""
                                }
                            Text("X")
                                .foregroundStyle(.neonGreen)
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                                .onTapGesture {
                                    morseEngine.performHaptic(for: .y)
                                    self.showLetter.toggle()
                                    self.letterToShow = self.showLetter ? "Y" : ""
                                }
                            Text("Y")
                                .foregroundStyle(.neonGreen)
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                                .onTapGesture {
                                    morseEngine.performHaptic(for: .z)
                                    self.showLetter.toggle()
                                    self.letterToShow = self.showLetter ? "Z" : ""
                                }
                            Text("Z")
                                .foregroundStyle(.neonGreen)
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
