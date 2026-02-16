//
//  MorseEngine.swift
//  MorseMode
//
//  Created by Ishauna Marie Alexander on 2/3/26.
//

import Foundation
import AVFoundation
import CoreHaptics
import Combine

final class MorseEngine: ObservableObject {
    // This is the only view that can use this

    // Supported audio candidates (base name, extension) in priority order
    private let audioCandidates: [(name: String, ext: String)] = [
        ("CH_morse_code", "ogg"),
        ("CH_morse_code", "mp3"),
        ("CH_morse_code", "wav"),
        ("morse_code", "mp3"),
        ("morse_code", "wav"),
        ("morse", "mp3"),
        ("morse", "wav")
    ]
    
    private var audioPlayer: AVAudioPlayer?
    private var isAudioPlaying: Bool = false
    
    private var engine: CHHapticEngine?
    //Haptic system
    
    init() {
        prepareEngine()
    }
    
    func prepareEngine() {
        // Sets up haptics
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            //Checks for device support
            print("Haptics not supported")
            return
        }
        do {
            //
            engine = try CHHapticEngine()
            try engine?.start()
            // Builds the engine and turns it on
            engine?.resetHandler = {[weak self] in
                // Watches for system resets and interruptions
                do{
                    try self?.engine?.start()
                } catch{
                    print("Failed to restart haptics engine: \(error)")
                }
            }
        } catch {
            print("Could not create/start engine: \(error)")
        }
    }
    
    private func resolveMorseAudioURL() -> URL? {
        // Try common generic files as a fallback
        for (name, ext) in [("CH_morse_code", "ogg"), ("CH_morse_code", "mp3"), ("CH_morse_code", "wav"), ("morse_code", "mp3"), ("morse_code", "wav"), ("morse", "mp3"), ("morse", "wav")] {
            if let url = Bundle.main.url(forResource: name, withExtension: ext) {
                return url
            }
        }
        return nil
    }
    
    private func startMorseAudioIfNeeded(using url: URL?) {
        guard !isAudioPlaying else { return }
        guard let url = url ?? resolveMorseAudioURL() else {
            print("MorseEngine: No suitable Morse audio file found in bundle for requested letter or known candidates.")
            return
        }
        print("MorseEngine: Using audio file at URL: \(url.lastPathComponent)")
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1 // loop while Morse is playing
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            isAudioPlaying = true
        } catch {
            print("Failed to initialize audio player: \(error)")
        }
    }
    
    private func stopMorseAudio() {
        audioPlayer?.stop()
        isAudioPlaying = false
    }
    
    func startMorseAudio() {
        startMorseAudioIfNeeded(using: nil)
    }

    func stopMorseAudioPlayback() {
        stopMorseAudio()
        // Stops audio playback
    }
    
    func performHaptic(for letter: Letter) {
        startMorseAudioIfNeeded(using: nil)
        // Starts audio alongside haptics
        
        guard let engine else { return }

        var events: [CHHapticEvent] = []
        var time: TimeInterval = 0
        // Creates a list of vibrations and tells it when to happen

        for symbol in letter.morseRepresentation {
            events.append(symbol.hapticEvent(relativeTime: time))
            // How each symbol knows how to generate its vibration
            time += symbol.duration + 0.15
            // adds a gap between symbols
        }

        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            // Combines morse into one pattern
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
            // Starts audio immediately
            let totalDuration = time
            DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) { [weak self] in
                self?.stopMorseAudio()
                // Stops audio when finished
            }
        } catch {
            print("❌ Playback error:", error)
        }
    }
}

