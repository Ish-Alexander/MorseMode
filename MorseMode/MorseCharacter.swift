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
    
    func hapticEvent(relativeTime:  TimeInterval) -> CHHapticEvent {
        // Creates a vibration (Dot or Dash)
        switch self {
        case .dot:
            return  CHHapticEvent(eventType: .hapticTransient, parameters: [
                // Short, quick taps
                .init(parameterID: .hapticIntensity, value: 1),
                .init(parameterID: .hapticSharpness, value: 1)
            ],
                                  relativeTime: relativeTime
                                  // When should the vibration happen?
            )
        case .dash:
            return CHHapticEvent(
                eventType: .hapticContinuous,
                // Long, drawn out taps
                parameters: [
                    .init(parameterID: .hapticIntensity, value: 1),
                    .init(parameterID: .hapticSharpness, value: 0.4)
                ],
                relativeTime: relativeTime,
                duration: 0.5
            )
        }
    }
    
    var duration: TimeInterval {
        switch self {
        case .dot:
            return 0.12
        case .dash:
            return 0.5
        }
    }
}

