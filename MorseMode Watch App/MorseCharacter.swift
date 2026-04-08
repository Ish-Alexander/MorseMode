//
//  Untitled.swift
//  MorseMode
//
//  Created by Ishauna Marie Alexander on 2/5/26.
//

import Foundation

import WatchKit

enum MorseCharacter {

    case dot
    case dash

    var pulseOffsets: [TimeInterval] {
        switch self {
        case .dot:
            return [0]
        case .dash:
            return [0, 0.08]
        }
    }

    var duration: TimeInterval {
        switch self {
        case .dot: return 0.12
        case .dash: return 0.42
        }
    }
    func playWatchHaptic() {
        switch self {
        case .dot:
            WKInterfaceDevice.current().play(.click)
        case .dash:
            WKInterfaceDevice.current().play(.directionUp)
        }
    }
}
