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
    
    private var engine: CHHapticEngine?
    
    init() {
        prepareEngine()
    }
    
    func prepareEngine() {
        //
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            print("Haptics not supported")
            return
        }
        do {
            //
            engine = try CHHapticEngine()
            try engine?.start()
            
            engine?.resetHandler = {[weak self] in
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
    
    func performHaptic(for letter: Letter) {
            guard let engine else { return }

            var events: [CHHapticEvent] = []
            var time: TimeInterval = 0

            for symbol in letter.morseRepresentation {
                events.append(symbol.hapticEvent(relativeTime: time))
                time += symbol.duration + 0.15
            }

            do {
                let pattern = try CHHapticPattern(events: events, parameters: [])
                let player = try engine.makePlayer(with: pattern)
                try player.start(atTime: 0)
            } catch {
                print("❌ Playback error:", error)
            }
        }
    }

