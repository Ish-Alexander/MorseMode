//
//  Practice.swift
//  MorseMode
//
//  Created by Ishauna Marie Alexander on 1/28/26.
//

import SwiftUI
import WatchConnectivity
import AVFoundation

struct Practice: View {
    
    @ObservedObject var morseEngine: MorseEngine
    
    @State private var letterToShow: String = ""
            
    @State private var tappedImageName: String = "ImageA"
    
    @State private var message: String = ""
    @State private var isPlayingMessage: Bool = false
    @State private var audioPlayer: AVAudioPlayer? = nil
    
    let letter: Letter
    
    // Morse code mapping and timing (units)
    private let morseMap: [Character: String] = [
        "a": ".-",   "b": "-...", "c": "-.-.", "d": "-..",  "e": ".",
        "f": "..-.", "g": "--.",  "h": "....", "i": "..",   "j": ".---",
        "k": "-.-",  "l": ".-..", "m": "--",   "n": "-.",  "o": "---",
        "p": ".--.", "q": "--.-", "r": ".-.",  "s": "...", "t": "-",
        "u": "..-",  "v": "...-", "w": ".--",  "x": "-..-", "y": "-.--",
        "z": "--.."
    ]

    // Base time unit for Morse (adjust to taste)
    private let unitDuration: UInt64 = 120_000_000 // 0.12s per unit
    
    private let interLetterUnits: UInt64 = 4  // delay between letters
    private let wordGapUnits: UInt64 = 7      // delay between words (spaces)
    
    private func lowercaseCharacter(_ ch: Character) -> Character? {
        return ch.lowercased().first
    }
    
    private func letter(from character: Character) -> Letter? {
        switch character.lowercased() {
        case "a": return .a
        case "b": return .b
        case "c": return .c
        case "d": return .d
        case "e": return .e
        case "f": return .f
        case "g": return .g
        case "h": return .h
        case "i": return .i
        case "j": return .j
        case "k": return .k
        case "l": return .l
        case "m": return .m
        case "n": return .n
        case "o": return .o
        case "p": return .p
        case "q": return .q
        case "r": return .r
        case "s": return .s
        case "t": return .t
        case "u": return .u
        case "v": return .v
        case "w": return .w
        case "x": return .x
        case "y": return .y
        case "z": return .z
        default: return nil
        }
    }
    
    private func playSound(for character: Character) {
        let upper = String(character).uppercased()
        guard let first = upper.first, first.isLetter else {
            audioPlayer?.stop()
            audioPlayer = nil
            return
        }
        let baseName = "\(first)_morse_code"
        let candidateExtensions = ["ogg.mp3", "mp3", "ogg", "wav", "m4a"]
        var foundURL: URL? = nil
        for ext in candidateExtensions {
            if let url = Bundle.main.url(forResource: baseName, withExtension: ext) {
                foundURL = url
                break
            }
        }
        guard let url = foundURL else {
            if audioPlayer?.isPlaying == true { audioPlayer?.stop() }
            audioPlayer = nil
            print("[Audio][Practice] No audio file for letter \(first). Tried: \(candidateExtensions.map { "\(baseName).\($0)" }.joined(separator: ", "))")
            return
        }
        do {
            if let player = audioPlayer, player.url == url {
                player.currentTime = 0
                player.play()
            } else {
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                player.play()
                audioPlayer = player
            }
        } catch {
            print("[Audio][Practice] Failed to play \(url.lastPathComponent): \(error)")
        }
    }
    
    private func playLetterMorse(_ ch: Character) async {
        guard let lower = lowercaseCharacter(ch), let pattern = morseMap[lower] else { return }
        morseEngine.startMorseAudio()
        // Update display to current letter
        letterToShow = String(ch).uppercased()
        playSound(for: ch)
        // Send to watch once per letter
        if let l = letter(from: ch) {
            sendToWatch(l)
        }
        // For each symbol: dot=1 unit on, dash=3 units on, 1 unit off between symbols
        for (idx, symbol) in pattern.enumerated() {
            // Trigger haptic for the whole letter if engine only supports per-letter
            // If your engine has per-symbol API, replace this with dot/dash specific calls
            // For now, we reuse performHaptic(for:) to ensure a feel per letter
            if idx == 0, let l = letter(from: ch) {
                morseEngine.performHaptic(for: l)
            }
            // Simulate symbol-on duration
            let onUnits: UInt64 = (symbol == "-") ? 3 : 1
            try? await Task.sleep(nanoseconds: onUnits * unitDuration)
            // Intra-character gap (1 unit) except after last symbol
            if idx < pattern.count - 1 {
                try? await Task.sleep(nanoseconds: 1 * unitDuration)
            }
        }
    }
    
    private func playMessage(_ text: String) {
        guard !isPlayingMessage else { return }
        morseEngine.startMorseAudio()
        let characters = Array(text)
        isPlayingMessage = true
        Task { @MainActor in
            for (idx, ch) in characters.enumerated() {
                if ch == " " { // word gap = 7 units
                    letterToShow = ""
                    try? await Task.sleep(nanoseconds: wordGapUnits * unitDuration)
                    continue
                }
                // Skip unsupported characters
                guard let lower = lowercaseCharacter(ch), morseMap[lower] != nil else { continue }
                await playLetterMorse(ch)
                // Inter-letter gap = 3 units, unless next char is space or end
                if idx < characters.count - 1 {
                    let next = characters[idx + 1]
                    if next != " " { // only add letter gap if next isn't a word gap
                        try? await Task.sleep(nanoseconds: interLetterUnits * unitDuration)
                    }
                }
            }
            letterToShow = ""
            morseEngine.stopMorseAudioPlayback()
            isPlayingMessage = false
        }
    }
            
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
                ZStack {
                    GeometryReader { geo in
                        let h = geo.size.height
                        Image("Tube")
                            .resizable()
                            .scaledToFit()
                            .overlay(
                                Group {
                                    if !letterToShow.isEmpty {
                                        let lowerChar = letterToShow.lowercased().first
                                        let pattern = lowerChar.flatMap { morseMap[$0] } ?? ""
                                        VStack(spacing: max(1, h * 0.01)) {
                                            Text(letterToShow)
                                                .font(.custom("berkelium bitmap", size: max(10, h * 0.4)))
                                                .minimumScaleFactor(0.2)
                                                .lineLimit(1)
                                                .foregroundStyle(.neon)
                                            if !pattern.isEmpty {
                                                Text(pattern)
                                                    .font(.custom("berkelium bitmap", size: max(8, h * 0.12)))
                                                    .minimumScaleFactor(0.3)
                                                    .lineLimit(1)
                                                    .foregroundStyle(.neon)
                                            }
                                        }
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                                    }
                                }
                            )
                    }
                }
                
                VStack(spacing: 12) {
                    HStack {
                        TextField("Type a message", text: $message)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .padding(10)
                            .background(Color.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .foregroundStyle(.neon)
                        Button(action: {
                            playMessage(message)
                        }) {
                            Text(isPlayingMessage ? "Playing…" : "Play")
                                .font(.headline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(isPlayingMessage ? Color.gray.opacity(0.3) : Color.blue.opacity(0.6))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .disabled(isPlayingMessage || message.isEmpty)
                    }
                }
                .padding(.horizontal)
                
                HStack{
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                            Text("A")
                            .font(.custom("berkelium bitmap", size: 20))
                                .foregroundStyle(.neon)
                    }
                    .onTapGesture {
                        morseEngine.performHaptic(for: .a)
                        sendToWatch(.a)
                        self.letterToShow = "A"
                        playSound(for: "A")
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                            Text("B")
                            .font(.custom("berkelium bitmap", size: 20))
                                .foregroundStyle(.neon)
                    }
                    .onTapGesture {
                        morseEngine.performHaptic(for: .b)
                        sendToWatch(.b)
                        self.letterToShow = "B"
                        playSound(for: "B")
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                            Text("C")
                            .font(.custom("berkelium bitmap", size: 20))
                                .foregroundStyle(.neon)
                    }
                    .onTapGesture {
                        morseEngine.performHaptic(for: .c)
                        sendToWatch(.c)
                        self.letterToShow = "C"
                        playSound(for: "C")
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                            Text("D")
                            .font(.custom("berkelium bitmap", size: 20))
                                .foregroundStyle(.neon)
                    }
                    .onTapGesture {
                        morseEngine.performHaptic(for: .d)
                        sendToWatch(.d)
                        self.letterToShow = "D"
                        playSound(for: "D")
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                            Text("E")
                            .font(.custom("berkelium bitmap", size: 20))
                                .foregroundStyle(.neon)
                    }
                    .onTapGesture {
                        morseEngine.performHaptic(for: .e)
                        sendToWatch(.e)
                        self.letterToShow = "E"
                        playSound(for: "E")
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                            Text("F")
                            .font(.custom("berkelium bitmap", size: 20))
                                .foregroundStyle(.neon)
                    }
                    .onTapGesture {
                        morseEngine.performHaptic(for: .f)
                        sendToWatch(.f)
                        self.letterToShow = "F"
                        playSound(for: "F")
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                            Text("G")
                            .font(.custom("berkelium bitmap", size: 20))
                                .foregroundStyle(.neon)
                    }
                    .onTapGesture {
                        morseEngine.performHaptic(for: .g)
                        sendToWatch(.g)
                        self.letterToShow = "G"
                        playSound(for: "G")
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                            Text("H")
                            .font(.custom("berkelium bitmap", size: 20))
                                .foregroundStyle(.neon)
                    }
                    .onTapGesture {
                        morseEngine.performHaptic(for: .h)
                        sendToWatch(.h)
                        self.letterToShow = "H"
                        playSound(for: "H")
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                            Text("I")
                            .font(.custom("berkelium bitmap", size: 20))
                                .foregroundStyle(.neon)
                    }
                    .onTapGesture {
                        morseEngine.performHaptic(for: .i)
                        sendToWatch(.i)
                        self.letterToShow = "I"
                        playSound(for: "I")
                    }
                }
                
                HStack{
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                            Text("J")
                            .font(.custom("berkelium bitmap", size: 20))
                                .foregroundStyle(.neon)
                    }
                    .onTapGesture {
                        morseEngine.performHaptic(for: .j)
                        sendToWatch(.j)
                        self.letterToShow = "J"
                        playSound(for: "J")
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                            Text("K")
                            .font(.custom("berkelium bitmap", size: 20))
                                .foregroundStyle(.neon)
                    }
                    .onTapGesture {
                        morseEngine.performHaptic(for: .k)
                        sendToWatch(.k)
                        self.letterToShow = "K"
                        playSound(for: "K")
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                            Text("L")
                            .font(.custom("berkelium bitmap", size: 20))
                                .foregroundStyle(.neon)
                    }
                    .onTapGesture {
                        morseEngine.performHaptic(for: .l)
                        sendToWatch(.l)
                        self.letterToShow = "L"
                        playSound(for: "L")
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                            Text("M")
                            .font(.custom("berkelium bitmap", size: 20))
                                .foregroundStyle(.neon)
                    }
                    .onTapGesture {
                        morseEngine.performHaptic(for: .m)
                        sendToWatch(.m)
                        self.letterToShow = "M"
                        playSound(for: "M")
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                            Text("N")
                            .font(.custom("berkelium bitmap", size: 20))
                                .foregroundStyle(.neon)
                    }
                    .onTapGesture {
                        morseEngine.performHaptic(for: .n)
                        sendToWatch(.n)
                        self.letterToShow = "N"
                        playSound(for: "N")
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                            Text("O")
                            .font(.custom("berkelium bitmap", size: 20))
                                .foregroundStyle(.neon)
                    }
                    .onTapGesture {
                        morseEngine.performHaptic(for: .o)
                        sendToWatch(.o)
                        self.letterToShow = "O"
                        playSound(for: "O")
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                            Text("P")
                            .font(.custom("berkelium bitmap", size: 20))
                                .foregroundStyle(.neon)
                    }
                    .onTapGesture {
                        morseEngine.performHaptic(for: .p)
                        sendToWatch(.p)
                        self.letterToShow = "P"
                        playSound(for: "P")
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                            Text("Q")
                                .font(.custom("berkelium bitmap", size: 20))
                                .foregroundStyle(.neon)
                    }
                    .onTapGesture {
                        morseEngine.performHaptic(for: .q)
                        sendToWatch(.q)
                        self.letterToShow = "Q"
                        playSound(for: "Q")
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                            Text("R")
                                .font(.custom("berkelium bitmap", size: 20))
                                .foregroundStyle(.neon)
                    }
                    .onTapGesture {
                        morseEngine.performHaptic(for: .r)
                        sendToWatch(.r)
                        self.letterToShow = "R"
                        playSound(for: "R")
                    }
                }
                
                HStack{
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                            Text("S")
                                .font(.custom("berkelium bitmap", size: 20))
                                .foregroundStyle(.neon)
                    }
                    .onTapGesture {
                        morseEngine.performHaptic(for: .s)
                        sendToWatch(.s)
                        self.letterToShow = "S"
                        playSound(for: "S")
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                            Text("T")
                                .font(.custom("berkelium bitmap", size: 20))
                                .foregroundStyle(.neon)
                    }
                    .onTapGesture {
                        morseEngine.performHaptic(for: .t)
                        sendToWatch(.t)
                        self.letterToShow = "T"
                        playSound(for: "T")
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                            Text("U")
                                .font(.custom("berkelium bitmap", size: 20))
                                .foregroundStyle(.neon)
                    }
                    .onTapGesture {
                        morseEngine.performHaptic(for: .u)
                        sendToWatch(.u)
                        self.letterToShow = "U"
                        playSound(for: "U")
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                            Text("V")
                                .font(.custom("berkelium bitmap", size: 20))
                                .foregroundStyle(.neon)
                    }
                    .onTapGesture {
                        morseEngine.performHaptic(for: .v)
                        sendToWatch(.v)
                        self.letterToShow = "V"
                        playSound(for: "V")
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                            Text("W")
                                .font(.custom("berkelium bitmap", size: 20))
                                .foregroundStyle(.neon)
                    }
                    .onTapGesture {
                        morseEngine.performHaptic(for: .w)
                        sendToWatch(.w)
                        self.letterToShow = "W"
                        playSound(for: "W")
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                            Text("X")
                                .font(.custom("berkelium bitmap", size: 20))
                                .foregroundStyle(.neon)
                    }
                    .onTapGesture {
                        morseEngine.performHaptic(for: .x)
                        sendToWatch(.x)
                        self.letterToShow = "X"
                        playSound(for: "X")
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                            Text("Y")
                                .font(.custom("berkelium bitmap", size: 20))
                                .foregroundStyle(.neon)
                    }
                    .onTapGesture {
                        morseEngine.performHaptic(for: .y)
                        sendToWatch(.y)
                        self.letterToShow = "Y"
                        playSound(for: "Y")
                    }
                    
                    ZStack{
                            Image("Circle")
                                .resizable()
                                .scaledToFit()
                            Text("Z")
                                .font(.custom("berkelium bitmap", size: 20))
                                .foregroundStyle(.neon)
                    }
                    .onTapGesture {
                        morseEngine.performHaptic(for: .z)
                        sendToWatch(.z)
                        self.letterToShow = "Z"
                        playSound(for: "Z")
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

