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

    var duration: TimeInterval {
        switch self {
        case .dot: return 0.12
        case .dash: return 0.5
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
