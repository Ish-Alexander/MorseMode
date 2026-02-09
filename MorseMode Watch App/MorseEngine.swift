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

    func performHaptic(for letter: Letter) {

        let pattern = letter.morsePattern

        for symbol in pattern {

            switch symbol {

            case .dot:
                WKInterfaceDevice.current().play(.click)

            case .dash:
                WKInterfaceDevice.current().play(.directionUp)
            }
            Thread.sleep(forTimeInterval: 0.2)
        }
    }
}

