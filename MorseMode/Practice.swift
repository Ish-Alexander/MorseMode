//
//  Practice.swift
//  MorseMode
//
//  Created by Ishauna Marie Alexander on 1/28/26.
//

import SwiftUI
import WatchConnectivity
import AVFoundation

@MainActor
private enum WarehouseSavedWordsStore {
    static let storageKey = "Warehouse.savedMessages"
    static let maxSavedMessages = 20

    static func sanitized(_ text: String) -> String {
        let filtered = text.filter { character in
            character == " " || character.isASCII && character.isLetter
        }
        return filtered
            .split(whereSeparator: \.isWhitespace)
            .map(String.init)
            .joined(separator: " ")
    }

    static func load() -> [String] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let savedMessages = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        let cleanedMessages = savedMessages
            .map(sanitized)
            .filter { !$0.isEmpty }
        return Array(cleanedMessages.prefix(maxSavedMessages))
    }

    static func save(_ messages: [String]) {
        let trimmedMessages = Array(
            messages
                .map(sanitized)
                .filter { !$0.isEmpty }
                .prefix(maxSavedMessages)
        )
        guard let data = try? JSONEncoder().encode(trimmedMessages) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}

@MainActor
struct Practice: View {
    @ObservedObject var morseEngine: MorseEngine
    @EnvironmentObject private var playbackSettings: PlaybackSettings
    
    @State private var letterToShow: String = ""
    
    @State private var message: String = ""
    @State private var savedMessages: [String] = WarehouseSavedWordsStore.load()
    @State private var warehouseStatusMessage: String?
    @State private var warehouseStatusDismissTask: Task<Void, Never>?
    @State private var isShowingSavedWordsPopup: Bool = false
    @State private var isPlayingMessage: Bool = false
    @State private var audioPlayer: AVAudioPlayer? = nil
    @State private var letterDisplayResetTask: Task<Void, Never>?
    @State private var messagePlaybackTask: Task<Void, Never>?
    
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
    
    private let interLetterUnits: UInt64 = 3  // delay between letters
    private let wordGapUnits: UInt64 = 7      // delay between words (spaces)
    private let keyboardLetterFontSize: CGFloat = 20
    private let keyboardCircleScale: CGFloat = 2.0
    private let letterRows: [[Letter]] = [
        [.q, .w, .e, .r, .t, .y, .u, .i, .o, .p],
        [.a, .s, .d, .f, .g, .h, .j, .k, .l],
        [.z, .x, .c, .v, .b, .n, .m]
    ]

    private var normalizedMessage: String {
        WarehouseSavedWordsStore.sanitized(message)
    }

    private var canSaveMessage: Bool {
        !normalizedMessage.isEmpty
    }

    private var canPlayMessage: Bool {
        !normalizedMessage.isEmpty
    }

    private var messageDisplayText: String {
        normalizedMessage.isEmpty ? "Tap letters below" : normalizedMessage
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
        let playback = MorseLetterAudio.play(
            character: character,
            reusing: audioPlayer,
            logPrefix: "Practice"
        )
        audioPlayer = playback.player
    }
    
    private func playLetterMorse(_ ch: Character) async {
        guard lowercaseCharacter(ch).flatMap({ morseMap[$0] }) != nil,
              let letterEnum = letter(from: ch) else { return }
        guard !Task.isCancelled else { return }

        let visibleLetter = String(ch).uppercased()
        letterToShow = visibleLetter
        if playbackSettings.mode.allowsSound {
            morseEngine.startMorseAudio()
            playSound(for: ch)
        }

        sendToWatch(letterEnum)
        if playbackSettings.mode.allowsHaptics {
            morseEngine.performHaptic(for: letterEnum)
        }

        let playbackDuration = morseEngine.playbackDuration(for: letterEnum)
        if playbackDuration > 0 {
            try? await Task.sleep(for: .seconds(playbackDuration))
        }
        guard !Task.isCancelled else { return }
    }
    
    private func playMessage(_ text: String) {
        guard !isPlayingMessage else { return }
        let normalizedText = WarehouseSavedWordsStore.sanitized(text)
        guard !normalizedText.isEmpty else { return }
        if playbackSettings.mode.allowsSound {
            morseEngine.startMorseAudio()
        }
        let characters = Array(normalizedText)
        isPlayingMessage = true
        messagePlaybackTask?.cancel()
        messagePlaybackTask = Task { @MainActor in
            for (idx, ch) in characters.enumerated() {
                guard !Task.isCancelled else { break }
                if ch == " " { // word gap = 7 units
                    letterToShow = ""
                    try? await Task.sleep(nanoseconds: wordGapUnits * unitDuration)
                    continue
                }
                // Skip unsupported characters
                guard lowercaseCharacter(ch).flatMap({ morseMap[$0] }) != nil else { continue }
                await playLetterMorse(ch)
                // Inter-letter gap = 3 units, unless next char is space or end
                if idx < characters.count - 1 {
                    let next = characters[idx + 1]
                    if next != " " { // only add letter gap if next isn't a word gap
                        try? await Task.sleep(nanoseconds: interLetterUnits * unitDuration)
                    }
                }
            }
            guard !Task.isCancelled else { return }
            letterToShow = ""
            morseEngine.stopMorseAudioPlayback()
            isPlayingMessage = false
            messagePlaybackTask = nil
        }
    }

    private func stopActivePlayback() {
        messagePlaybackTask?.cancel()
        messagePlaybackTask = nil
        audioPlayer?.stop()
        audioPlayer = nil
        morseEngine.stopMorseAudioPlayback()
        isPlayingMessage = false
        letterToShow = ""
    }

    private func saveCurrentMessage() {
        let candidate = normalizedMessage
        guard !candidate.isEmpty else {
            showWarehouseStatus("Type a word to save.")
            return
        }

        savedMessages.removeAll { $0.caseInsensitiveCompare(candidate) == .orderedSame }
        savedMessages.insert(candidate, at: 0)

        if savedMessages.count > WarehouseSavedWordsStore.maxSavedMessages {
            savedMessages = Array(savedMessages.prefix(WarehouseSavedWordsStore.maxSavedMessages))
        }

        WarehouseSavedWordsStore.save(savedMessages)
        showWarehouseStatus(savedMessages.count == WarehouseSavedWordsStore.maxSavedMessages
            ? "Saved. Warehouse is holding 20 words."
            : "Saved to Warehouse")
    }

    private func deleteSavedMessage(_ savedMessage: String) {
        savedMessages.removeAll { $0 == savedMessage }
        WarehouseSavedWordsStore.save(savedMessages)
        showWarehouseStatus("Removed from Warehouse")
    }

    private func showWarehouseStatus(_ message: String) {
        warehouseStatusDismissTask?.cancel()
        warehouseStatusMessage = message
        warehouseStatusDismissTask = Task {
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            warehouseStatusMessage = nil
            warehouseStatusDismissTask = nil
        }
    }

    private func showLetterForPlayback(_ letter: Letter, character: String) {
        letterDisplayResetTask?.cancel()
        letterToShow = character

        let playbackDuration = morseEngine.playbackDuration(for: letter)
        guard playbackDuration > 0 else { return }

        letterDisplayResetTask = Task {
            try? await Task.sleep(for: .seconds(playbackDuration))
            guard !Task.isCancelled else { return }
            guard !isPlayingMessage, letterToShow == character else { return }
            letterToShow = ""
            letterDisplayResetTask = nil
        }
    }

    private func inputLetter(_ letter: Letter) {
        let character = String(describing: letter).uppercased()
        message += character
        warehouseStatusMessage = nil
        letterDisplayResetTask?.cancel()
        letterDisplayResetTask = nil
        letterToShow = character
    }

    private func inputSpace() {
        guard !message.isEmpty, !message.hasSuffix(" ") else { return }
        message += " "
        warehouseStatusMessage = nil
        letterToShow = ""
    }

    private func deleteLastInput() {
        guard !message.isEmpty else { return }
        message.removeLast()
        warehouseStatusMessage = nil
    }

    private func clearInput() {
        guard !message.isEmpty else { return }
        message = ""
        warehouseStatusMessage = nil
        letterDisplayResetTask?.cancel()
        letterToShow = ""
    }

    private func label(for letter: Letter) -> String {
        String(describing: letter).uppercased()
    }

    private func letterInputButton(for letter: Letter) -> some View {
        let label = label(for: letter)
        let circleSize = keyboardLetterFontSize * keyboardCircleScale
        return Button(action: {
            inputLetter(letter)
        }) {
            ZStack {
                Image("Circle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: circleSize, height: circleSize)
                Text(label)
                    .font(.custom("berkelium bitmap", size: keyboardLetterFontSize))
                    .foregroundStyle(.neon)
            }
        }
        .buttonStyle(.plain)
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
        if playbackSettings.mode.allowsHaptics {
            morseEngine.performHaptic(for: letter)
        }
        sendToWatch(letter)
        showLetterForPlayback(letter, character: initialLetter)
        if playbackSettings.mode.allowsSound, let character = initialLetter.first {
            playSound(for: character)
        }
    }

    private var savedWordsPopup: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    Text("\(savedMessages.count)/\(WarehouseSavedWordsStore.maxSavedMessages) saved")
                        .font(.custom("berkelium bitmap", size: 12))
                        .foregroundStyle(Color.white.opacity(0.75))

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
                                                        .font(.custom("berkelium bitmap", size: 7))
                                                        .foregroundStyle(.neon)
                                                        .frame(minWidth: 44, minHeight: 44)
                                                        .padding(.horizontal, 10)
                                                        .background(Color.white.opacity(0.08))
                                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                                }
                                                .disabled(isPlayingMessage)

                                                Button(action: {
                                                    deleteSavedMessage(savedMessage)
                                                }) {
                                                    Image(systemName: "trash")
                                                        .foregroundStyle(Color.red.opacity(0.9))
                                                        .frame(minWidth: 44, minHeight: 44)
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

    private var topToolbar: some View {
        ZStack {
            HStack {
                Spacer(minLength: 0)

                Button(action: {
                    isShowingSavedWordsPopup = true
                }) {
                    Text("Saved Words")
                        .font(.custom("berkelium bitmap", size: 12))
                        .foregroundStyle(.neon)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }

            Button(action: saveCurrentMessage) {
                Text("Save")
                    .font(.custom("berkelium bitmap", size: 12))
                    .foregroundStyle(canSaveMessage && !isPlayingMessage ? .neon : Color.white.opacity(0.45))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(canSaveMessage && !isPlayingMessage ? Color.white.opacity(0.08) : Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(isPlayingMessage || !canSaveMessage)
            .offset(x: -28)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.96))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)
        }
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
                            .frame(width: 380, height: 320)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
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
                .frame(maxWidth: .infinity)
                .frame(height: 320)
                
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Text(messageDisplayText)
                            .font(.custom("berkelium bitmap", size: 14))
                            .foregroundStyle(canPlayMessage ? Color.neon : Color.white.opacity(0.55))
                            .frame(maxWidth: .infinity, minHeight: 42, alignment: .leading)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(Color.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        Button(action: {
                            playMessage(normalizedMessage)
                        }) {
                            Text(isPlayingMessage ? "Playing…" : "Play")
                                .font(.custom("berkelium bitmap", size: 14, relativeTo: .body))
                                .foregroundStyle(isPlayingMessage || !canPlayMessage ? Color.white.opacity(0.45) : .neon)
                                .frame(minWidth: 76, minHeight: 42)
                                .padding(.horizontal, 8)
                                .background(isPlayingMessage || !canPlayMessage ? Color.white.opacity(0.04) : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(isPlayingMessage || !canPlayMessage ? Color.white.opacity(0.08) : Color.neon, lineWidth: 1)
                                )
                        }
                        .disabled(isPlayingMessage || !canPlayMessage)
                    }

                    HStack(spacing: 12) {
                        Button(action: deleteLastInput) {
                            Text("Delete")
                                .font(.custom("berkelium bitmap", size: 14, relativeTo: .body))
                                .foregroundStyle(message.isEmpty ? Color.white.opacity(0.45) : .neon)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(message.isEmpty ? Color.white.opacity(0.04) : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(message.isEmpty ? Color.white.opacity(0.08) : Color.neon, lineWidth: 1)
                                )
                        }
                        .disabled(message.isEmpty)

                        Button(action: clearInput) {
                            Text("Clear")
                                .font(.custom("berkelium bitmap", size: 14, relativeTo: .body))
                                .foregroundStyle(message.isEmpty ? Color.white.opacity(0.45) : .neon)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(message.isEmpty ? Color.white.opacity(0.04) : Color.clear.opacity(0.22))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(message.isEmpty ? Color.white.opacity(0.08) : Color.neon, lineWidth: 1)
                                )
                        }
                        .disabled(message.isEmpty)
                    }

                    HStack(spacing: 12) {
                        Spacer()
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
                
                VStack(spacing: 4) {
                    ForEach(Array(letterRows.enumerated()), id: \.offset) { _, row in
                        HStack(spacing: 0) {
                            ForEach(row, id: \.self) { letter in
                                letterInputButton(for: letter)
                            }
                        }
                    }

                    Button(action: inputSpace) {
                        Text("Space")
                            .font(.custom("berkelium bitmap", size: 14, relativeTo: .body))
                            .foregroundStyle(message.isEmpty || message.hasSuffix(" ") ? Color.white.opacity(0.45) : .neon)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(message.isEmpty || message.hasSuffix(" ") ? Color.white.opacity(0.04) : Color.clear.opacity(0.22))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(message.isEmpty || message.hasSuffix(" ") ? Color.white.opacity(0.08) : Color.neon, lineWidth: 1)
                            )
                    }
                    .disabled(message.isEmpty || message.hasSuffix(" "))
                    .padding(.horizontal, 56)
                }
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .safeAreaInset(edge: .top, spacing: 0) {
            topToolbar
        }
        .overlay(alignment: .top) {
            if let warehouseStatusMessage {
                Text(warehouseStatusMessage)
                    .font(.custom("berkelium bitmap", size: 12))
                    .foregroundStyle(.neon)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.92))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.neon.opacity(0.8), lineWidth: 1)
                    )
                    .shadow(color: Color.neon.opacity(0.2), radius: 12)
                    .padding(.top, 24)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: warehouseStatusMessage)
        .onDisappear {
            stopActivePlayback()
            warehouseStatusDismissTask?.cancel()
            warehouseStatusDismissTask = nil
            letterDisplayResetTask?.cancel()
            letterDisplayResetTask = nil
        }
    }
}

#Preview {
    let morseEngine = MorseEngine()
    Practice(morseEngine: morseEngine, letter: nil)
        .environmentObject(PlaybackSettings())
}
