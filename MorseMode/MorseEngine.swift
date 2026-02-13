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
    
    private func startMorseAudioIfNeeded() {
        guard !isAudioPlaying else { return }
        guard let url = Bundle.main.url(forResource: "CH_morse_code", withExtension: "ogg") else {
            print("Audio file CH_morse_code.ogg not found in bundle")
            return
        }
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
        startMorseAudioIfNeeded()
    }

    func stopMorseAudioPlayback() {
        stopMorseAudio()
    }
    
    func performHaptic(for letter: Letter) {
        startMorseAudioIfNeeded()
        
        guard let engine else { return }

        var events: [CHHapticEvent] = []
        var time: TimeInterval = 0

        for symbol in letter.morseRepresentation {
            events.append(symbol.hapticEvent(relativeTime: time))
            // How each symbol knows how to generate its vibration
            time += symbol.duration + 0.15
            // adds a gap between symbols
        }

        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
            let totalDuration = time
            DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) { [weak self] in
                self?.stopMorseAudio()
            }
        } catch {
            print("❌ Playback error:", error)
        }
    }
}

