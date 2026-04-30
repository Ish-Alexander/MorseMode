//
//  MorseEngine.swift
//  MorseMode
//
//  Created by Ishauna Marie Alexander on 2/5/26.
//

import Foundation
import Combine
import WatchKit

class MorseEngine: ObservableObject {
    

    static let shared = MorseEngine()
    private init() {}

    func performHaptic(for letter: Letter, playbackRate: Double = 1) {
        let pattern = letter.morsePattern
        let symbolGap: TimeInterval = 0.1
        let timeScale = 1 / max(playbackRate, 0.01)
        var delay: TimeInterval = 0

        for symbol in pattern {
            for offset in symbol.pulseOffsets {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay + (offset * timeScale)) {
                    symbol.playWatchHaptic()
                }
            }
            delay += (symbol.duration + symbolGap) * timeScale
        }
    }
}
