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
        switch self {
        case .dot:
            return  CHHapticEvent(eventType: .hapticTransient, parameters: [
                .init(parameterID: .hapticIntensity, value: 1),
                .init(parameterID: .hapticSharpness, value: 1)
            ],
                                  relativeTime: relativeTime
            )
        case .dash:
            return CHHapticEvent(
                eventType: .hapticContinuous,
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

