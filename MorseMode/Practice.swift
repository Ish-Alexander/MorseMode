//
//  Practice.swift
//  MorseMode
//
//  Created by Ishauna Marie Alexander on 1/28/26.
//

import SwiftUI
import WatchConnectivity

struct Practice: View {
    
    @ObservedObject var morseEngine: MorseEngine
    
    @State private var letterToShow: String = ""
            
    @State private var tappedImageName: String = "ImageA"
    
    let letter: Letter
    
    private func sendToWatch(_ letter: Letter) {
        MorseModeConnectivity.shared.send([
            "action": "playMorse",
            "letter": String(describing: letter).uppercased()
        ])
    }
            
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
                        sendToWatch(.a)
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
                        sendToWatch(.b)
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
                        sendToWatch(.c)
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
                        sendToWatch(.d)
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
                        sendToWatch(.e)
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
                        sendToWatch(.f)
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
                        sendToWatch(.g)
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
                        sendToWatch(.h)
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
                        sendToWatch(.i)
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
                        sendToWatch(.j)
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
                        sendToWatch(.k)
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
                        sendToWatch(.l)
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
                        sendToWatch(.m)
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
                        sendToWatch(.n)
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
                        sendToWatch(.o)
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
                        sendToWatch(.p)
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
                        sendToWatch(.q)
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
                        sendToWatch(.r)
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
                        sendToWatch(.s)
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
                        sendToWatch(.t)
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
                        sendToWatch(.u)
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
                        sendToWatch(.v)
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
                        sendToWatch(.w)
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
                        sendToWatch(.x)
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
                        sendToWatch(.y)
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
                        sendToWatch(.z)
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

