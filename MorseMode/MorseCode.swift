//
//  MorseCode.swift
//  MorseMode
//
//  Created by Ishauna Marie Alexander on 2/3/26.
//

import Foundation

enum Letter{
    case a
    case b
    case c
    case d
    case e
    case f
    case g
    case h
    case i
    case j
    case k
    case l
    case m
    case n
    case o
    case p
    case q
    case r
    case s
    case t
    case u
    case v
    case w
    case x
    case y
    case z
    
    init?(string: String) {
        switch string.lowercased() {
        case "a": self = .a
        case "b": self = .b
        case "c": self = .c
        case "d": self = .d
        case "e": self = .e
        case "f": self = .f
        case "g": self = .g
        case "h": self = .h
        case "i": self = .i
        case "j": self = .j
        case "k": self = .k
        case "l": self = .l
        case "m": self = .m
        case "n": self = .n
        case "o": self = .o
        case "p": self = .p
        case "q": self = .q
        case "r": self = .r
        case "s": self = .s
        case "t": self = .t
        case "u": self = .u
        case "v": self = .v
        case "w": self = .w
        case "x": self = .x
        case "y": self = .y
        case "z": self = .z
        default:
            return nil
        }
    }

    var morseRepresentation: [MorseCharacter]{
        switch self{
        case .a:
            [.dot, .dash]
        case .b:
            [.dash, .dot, .dot, .dot]
        case .c:
            [.dash, .dot, .dash, .dot]
        case .d:
            [.dash, .dot, .dot]
        case .e:
            [.dot]
        case .f:
            [.dot, .dot, .dash, .dot]
        case .g:
            [.dash, .dash, .dot]
        case .h:
            [.dot, .dot, .dot, .dot]
        case .i:
            [.dot, .dot]
        case .j:
            [.dot, .dash, .dash, .dash]
        case .k:
            [.dash, .dot, .dash]
        case .l:
            [.dot, .dash, .dot, .dot]
        case .m:
            [.dash, .dash]
        case .n:
            [.dash, .dot]
        case .o:
            [.dash, .dash, .dash]
        case .p:
            [.dot, .dash, .dash, .dot]
        case .q:
            [.dash, .dash, .dot, .dash]
        case .r:
            [.dot, .dash, .dot]
        case .s:
            [.dot, .dot, .dot]
        case .t:
            [.dash]
        case .u:
            [.dot, .dot, .dash]
        case .v:
            [.dot, .dot, .dot, .dash]
        case .w:
            [.dot, .dash, .dash]
        case .x:
            [.dash, .dot, .dot, .dash]
        case .y:
            [.dash, .dot, .dash, .dash]
        case .z:
            [.dash, .dash, .dot, .dot]
        }
    }
}
