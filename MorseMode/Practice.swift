//
//  Practice.swift
//  MorseMode
//
//  Created by Ishauna Marie Alexander on 1/28/26.
//

import SwiftUI
import WatchConnectivity
import AVFoundation

private enum WarehouseSavedWordsStore {
    static let storageKey = "Warehouse.savedMessages"
    static let maxSavedMessages = 20

    static func load() -> [String] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let savedMessages = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return Array(savedMessages.prefix(maxSavedMessages))
    }

    static func save(_ messages: [String]) {
        let trimmedMessages = Array(messages.prefix(maxSavedMessages))
        guard let data = try? JSONEncoder().encode(trimmedMessages) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}

struct Practice: View {
    @ObservedObject var morseEngine: MorseEngine
    
    @State private var letterToShow: String = ""
            
    @State private var tappedImageName: String = "ImageA"
    
    @State private var message: String = ""
    @State private var savedMessages: [String] = WarehouseSavedWordsStore.load()
    @State private var warehouseStatusMessage: String?
    @State private var isShowingSavedWordsPopup: Bool = false
    @State private var isPlayingMessage: Bool = false
    @State private var audioPlayer: AVAudioPlayer? = nil
    
    let letter: Letter?
    
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

    private var normalizedMessage: String {
        message
            .split(whereSeparator: \.isWhitespace)
            .map(String.init)
            .joined(separator: " ")
    }

    private var canSaveMessage: Bool {
        !normalizedMessage.isEmpty
    }

    private var canPlayMessage: Bool {
        !normalizedMessage.isEmpty
    }
    
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
        let candidateExtensions = ["ogg.mp3", "mp3", "ogg"]
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
        let normalizedText = text
            .split(whereSeparator: \.isWhitespace)
            .map(String.init)
            .joined(separator: " ")
        guard !normalizedText.isEmpty else { return }
        morseEngine.startMorseAudio()
        let characters = Array(normalizedText)
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

    private func saveCurrentMessage() {
        let candidate = normalizedMessage
        guard !candidate.isEmpty else {
            warehouseStatusMessage = "Type a word to save."
            return
        }

        savedMessages.removeAll { $0.caseInsensitiveCompare(candidate) == .orderedSame }
        savedMessages.insert(candidate, at: 0)

        if savedMessages.count > WarehouseSavedWordsStore.maxSavedMessages {
            savedMessages = Array(savedMessages.prefix(WarehouseSavedWordsStore.maxSavedMessages))
        }

        WarehouseSavedWordsStore.save(savedMessages)
        warehouseStatusMessage = savedMessages.count == WarehouseSavedWordsStore.maxSavedMessages
            ? "Saved. Warehouse is holding 20 words."
            : "Saved to warehouse."
    }

    private func deleteSavedMessage(_ savedMessage: String) {
        savedMessages.removeAll { $0 == savedMessage }
        WarehouseSavedWordsStore.save(savedMessages)
        warehouseStatusMessage = "Removed from warehouse."
    }
    // Plays entire typed message
            
    private func sendToWatch(_ letter: Letter) {
        MorseModeConnectivity.shared.send([
            "action": "playMorse",
            "letter": String(describing: letter).uppercased()
            // Sends message to apple watch
        ])
    }

    private func activateWatchSessionIfNeeded() {
        guard WCSession.isSupported() else { return }
        if WCSession.default.activationState != .activated {
            MorseModeConnectivity.shared.activate()
        }
    }

    private func playInitialLetter() {
        guard let letter else { return }
        let initialLetter = String(describing: letter).uppercased()
        letterToShow = initialLetter
        morseEngine.performHaptic(for: letter)
        sendToWatch(letter)
        if let character = initialLetter.first {
            playSound(for: character)
        }
    }

    private var savedWordsPopup: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    VStack(spacing: 0) {
                        HStack(spacing: 10) {
                            Text("Word")
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text("Actions")
                                .frame(width: 120, alignment: .center)
                        }
                        .font(.custom("berkelium bitmap", size: 11))
                        .foregroundStyle(Color.white.opacity(0.7))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.08))

                        if savedMessages.isEmpty {
                            Text("Save up to 20 custom words to replay.")
                                .font(.custom("berkelium bitmap", size: 12))
                                .foregroundStyle(Color.white.opacity(0.7))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 14)
                                .background(Color.white.opacity(0.04))
                        } else {
                            ScrollView {
                                VStack(spacing: 0) {
                                    ForEach(Array(savedMessages.enumerated()), id: \.element) { index, savedMessage in
                                        HStack(spacing: 10) {
                                            Text(savedMessage)
                                                .font(.custom("berkelium bitmap", size: 12))
                                                .foregroundStyle(.white)
                                                .lineLimit(1)
                                                .frame(maxWidth: .infinity, alignment: .leading)

                                            HStack(spacing: 8) {
                                                Button(action: {
                                                    message = savedMessage
                                                    isShowingSavedWordsPopup = false
                                                    playMessage(savedMessage)
                                                }) {
                                                    Text("Replay")
                                                        .font(.custom("berkelium bitmap", size: 11))
                                                        .foregroundStyle(.neon)
                                                        .padding(.horizontal, 10)
                                                        .padding(.vertical, 6)
                                                        .background(Color.white.opacity(0.08))
                                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                                }
                                                .disabled(isPlayingMessage)

                                                Button(action: {
                                                    deleteSavedMessage(savedMessage)
                                                }) {
                                                    Image(systemName: "trash")
                                                        .foregroundStyle(Color.red.opacity(0.9))
                                                        .padding(8)
                                                        .background(Color.white.opacity(0.06))
                                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                                }
                                            }
                                            .frame(width: 120, alignment: .center)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
                                        .background(index.isMultiple(of: 2) ? Color.white.opacity(0.03) : Color.white.opacity(0.06))
                                    }
                                }
                            }
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )

                    Spacer(minLength: 0)
                }
                .padding()
            }
            .navigationTitle("Saved Words")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        isShowingSavedWordsPopup = false
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    var body: some View {
        
        ZStack{
                Color.black
                    .ignoresSafeArea()
            VStack(spacing: 30){
                ZStack {
                    GeometryReader { geo in
                        let h = geo.size.height
                        // Makes it so the image keeps its shape
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
                            playMessage(normalizedMessage)
                        }) {
                            Text(isPlayingMessage ? "Playing…" : "Play")
                                .font(.headline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(isPlayingMessage ? Color.gray.opacity(0.3) : Color.blue.opacity(0.6))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .disabled(isPlayingMessage || !canPlayMessage)
                    }

                    HStack(spacing: 12) {
                        Button(action: saveCurrentMessage) {
                            Text("Save")
                                .font(.headline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(canSaveMessage ? Color.neon.opacity(0.25) : Color.gray.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .disabled(isPlayingMessage || !canSaveMessage)

                        Text("\(savedMessages.count)/\(WarehouseSavedWordsStore.maxSavedMessages) saved")
                            .font(.custom("berkelium bitmap", size: 12))
                            .foregroundStyle(Color.white.opacity(0.75))

                        Button(action: {
                            isShowingSavedWordsPopup = true
                        }) {
                            Text("Saved Words")
                                .font(.custom("berkelium bitmap", size: 12))
                                .foregroundStyle(.neon)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }

                        Spacer()
                    }

                    if let warehouseStatusMessage {
                        Text(warehouseStatusMessage)
                            .font(.custom("berkelium bitmap", size: 12))
                            .foregroundStyle(.neon)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                }
                .padding(.horizontal)
                .onAppear {
                    activateWatchSessionIfNeeded()
                    playInitialLetter()
                }
                .sheet(isPresented: $isShowingSavedWordsPopup) {
                    savedWordsPopup
                }
                
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
                        playSound(for: "A".first!)
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
                        playSound(for: "B".first!)
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
                        playSound(for: "C".first!)
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
                        playSound(for: "D".first!)
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
                        playSound(for: "E".first!)
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
                        playSound(for: "F".first!)
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
                        playSound(for: "G".first!)
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
                        playSound(for: "H".first!)
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
                        playSound(for: "I".first!)
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
                        playSound(for: "J".first!)
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
                        playSound(for: "K".first!)
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
                        playSound(for: "L".first!)
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
                        playSound(for: "M".first!)
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
                        playSound(for: "N".first!)
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
                        playSound(for: "O".first!)
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
                        playSound(for: "P".first!)
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
                        playSound(for: "Q".first!)
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
                        playSound(for: "R".first!)
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
                        playSound(for: "S".first!)
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
                        playSound(for: "T".first!)
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
                        playSound(for: "U".first!)
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
                        playSound(for: "V".first!)
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
                        playSound(for: "W".first!)
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
                        playSound(for: "X".first!)
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
                        playSound(for: "Y".first!)
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
                        playSound(for: "Z".first!)
                    }
                }
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

#Preview {
    let morseEngine = MorseEngine()
    Practice(morseEngine: morseEngine, letter: nil)
}
