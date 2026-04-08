//
//  MorseCharacter.swift
//  MorseMode
//
//  Created by Ishauna Marie Alexander on 2/3/26.
//

import Foundation
import CoreHaptics

enum MorseCharacter{
    case dot
    case dash
    
    func hapticEvents(relativeTime: TimeInterval) -> [CHHapticEvent] {
        // Creates a vibration pattern that makes dots feel crisp and dashes feel weighty.
        switch self {
        case .dot:
            return [CHHapticEvent(eventType: .hapticTransient, parameters: [
                // Short, quick taps
                .init(parameterID: .hapticIntensity, value: 1),
                .init(parameterID: .hapticSharpness, value: 1)
            ],
                                  relativeTime: relativeTime
                                  // When should the vibration happen?
            )]
        case .dash:
            let accent = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    .init(parameterID: .hapticIntensity, value: 1),
                    .init(parameterID: .hapticSharpness, value: 0.55)
                ],
                relativeTime: relativeTime
            )
            let body = CHHapticEvent(
                eventType: .hapticContinuous,
                // Long, drawn out taps
                parameters: [
                    .init(parameterID: .hapticIntensity, value: 1),
                    .init(parameterID: .hapticSharpness, value: 0.2)
                ],
                relativeTime: relativeTime + 0.02,
                duration: 0.56
            )
            return [accent, body]
        }
    }
    
    var duration: TimeInterval {
        switch self {
        case .dot:
            return 0.3
        case .dash:
            return 0.8
        }
    }
}
