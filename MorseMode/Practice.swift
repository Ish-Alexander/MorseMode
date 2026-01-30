//
//  Practice.swift
//  MorseMode
//
//  Created by Ishauna Marie Alexander on 1/28/26.
//

import SwiftUI

struct Practice: View {
    
    @State private var showLetter: Bool = false
            
            @State private var letterToShow: String = ""
            
            @State private var tappedImageName: String = "ImageA"
            
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
                                        .foregroundColor(.neonGreen)
                                }
                            }
                        )
                }
                HStack{
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                                .onTapGesture {
                                    self.showLetter.toggle()
                                    self.letterToShow = self.showLetter ? "A" : ""
                                }
                            Text("A",)
                                .foregroundStyle(.neonGreen)
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                                .onTapGesture {
                                    self.showLetter.toggle()
                                    self.letterToShow = self.showLetter ? "B" : ""
                                }
                            Text("B",)
                                .foregroundStyle(.neonGreen)
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                                .onTapGesture {
                                    self.showLetter.toggle()
                                    self.letterToShow = self.showLetter ? "C" : ""
                                }
                            Text("C",)
                                .foregroundStyle(.neonGreen)
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                                .onTapGesture {
                                    self.showLetter.toggle()
                                    self.letterToShow = self.showLetter ? "D" : ""
                                }
                            Text("D",)
                                .foregroundStyle(.neonGreen)
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                                .onTapGesture {
                                    self.showLetter.toggle()
                                    self.letterToShow = self.showLetter ? "E" : ""
                                }
                            Text("E",)
                                .foregroundStyle(.neonGreen)
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                                .onTapGesture {
                                    self.showLetter.toggle()
                                    self.letterToShow = self.showLetter ? "F" : ""
                                }
                            Text("F",)
                                .foregroundStyle(.neonGreen)
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                                .onTapGesture {
                                    self.showLetter.toggle()
                                    self.letterToShow = self.showLetter ? "G" : ""
                                }
                            Text("G",)
                                .foregroundStyle(.neonGreen)
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                                .onTapGesture {
                                    self.showLetter.toggle()
                                    self.letterToShow = self.showLetter ? "H" : ""
                                }
                            Text("H",)
                                .foregroundStyle(.neonGreen)
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                                .onTapGesture {
                                    self.showLetter.toggle()
                                    self.letterToShow = self.showLetter ? "I" : ""
                                }
                            Text("I",)
                                .foregroundStyle(.neonGreen)
                    }
                }
                
                HStack{
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                                .onTapGesture {
                                    self.showLetter.toggle()
                                    self.letterToShow = self.showLetter ? "J" : ""
                                }
                            Text("J",)
                                .foregroundStyle(.neonGreen)
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                                .onTapGesture {
                                    self.showLetter.toggle()
                                    self.letterToShow = self.showLetter ? "K" : ""
                                }
                            Text("K",)
                                .foregroundStyle(.neonGreen)
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                                .onTapGesture {
                                    self.showLetter.toggle()
                                    self.letterToShow = self.showLetter ? "L" : ""
                                }
                            Text("L",)
                                .foregroundStyle(.neonGreen)
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                                .onTapGesture {
                                    self.showLetter.toggle()
                                    self.letterToShow = self.showLetter ? "M" : ""
                                }
                            Text("M",)
                                .foregroundStyle(.neonGreen)
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                                .onTapGesture {
                                    self.showLetter.toggle()
                                    self.letterToShow = self.showLetter ? "N" : ""
                                }
                            Text("N",)
                                .foregroundStyle(.neonGreen)
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                                .onTapGesture {
                                    self.showLetter.toggle()
                                    self.letterToShow = self.showLetter ? "O" : ""
                                }
                            Text("O",)
                                .foregroundStyle(.neonGreen)
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                                .onTapGesture {
                                    self.showLetter.toggle()
                                    self.letterToShow = self.showLetter ? "P" : ""
                                }
                            Text("P",)
                                .foregroundStyle(.neonGreen)
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                                .onTapGesture {
                                    self.showLetter.toggle()
                                    self.letterToShow = self.showLetter ? "Q" : ""
                                }
                            Text("Q",)
                                .foregroundStyle(.neonGreen)
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                                .onTapGesture {
                                    self.showLetter.toggle()
                                    self.letterToShow = self.showLetter ? "R" : ""
                                }
                            Text("R",)
                                .foregroundStyle(.neonGreen)
                    }
                }
                
                HStack{
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                                .onTapGesture {
                                    self.showLetter.toggle()
                                    self.letterToShow = self.showLetter ? "S" : ""
                                }
                            Text("S",)
                                .foregroundStyle(.neonGreen)
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                                .onTapGesture {
                                    self.showLetter.toggle()
                                    self.letterToShow = self.showLetter ? "T" : ""
                                }
                            Text("T",)
                                .foregroundStyle(.neonGreen)
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                                .onTapGesture {
                                    self.showLetter.toggle()
                                    self.letterToShow = self.showLetter ? "U" : ""
                                }
                            Text("U",)
                                .foregroundStyle(.neonGreen)
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                                .onTapGesture {
                                    self.showLetter.toggle()
                                    self.letterToShow = self.showLetter ? "V" : ""
                                }
                            Text("V",)
                                .foregroundStyle(.neonGreen)
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                                .onTapGesture {
                                    self.showLetter.toggle()
                                    self.letterToShow = self.showLetter ? "W" : ""
                                }
                            Text("W",)
                                .foregroundStyle(.neonGreen)
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                                .onTapGesture {
                                    self.showLetter.toggle()
                                    self.letterToShow = self.showLetter ? "X" : ""
                                }
                            Text("X",)
                                .foregroundStyle(.neonGreen)
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                                .onTapGesture {
                                    self.showLetter.toggle()
                                    self.letterToShow = self.showLetter ? "Y" : ""
                                }
                            Text("Y",)
                                .foregroundStyle(.neonGreen)
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                                .onTapGesture {
                                    self.showLetter.toggle()
                                    self.letterToShow = self.showLetter ? "Z" : ""
                                }
                            Text("Z",)
                                .foregroundStyle(.neonGreen)
                    }
                }
            }
        }
    }
}

#Preview {
    Practice()
}
