//
//  MorseCode.swift
//  MorseMode
//
//  Created by Ishauna Marie Alexander on 2/5/26.
//

enum Letter: String, CaseIterable, Codable {

    case a = "A"
    case b = "B"
    case c = "C"
    case d = "D"
    case e = "E"
    case f = "F"
    case g = "G"
    case h = "H"
    case i = "I"
    case j = "J"
    case k = "K"
    case l = "L"
    case m = "M"
    case n = "N"
    case o = "O"
    case p = "P"
    case q = "Q"
    case r = "R"
    case s = "S"
    case t = "T"
    case u = "U"
    case v = "V"
    case w = "W"
    case x = "X"
    case y = "Y"
    case z = "Z"

    init?(string: String) {
        self.init(rawValue: string.uppercased())
    }

    var morsePattern: [MorseCharacter] {

        switch self {

        case .a: return [.dot, .dash]
        case .b: return [.dash, .dot, .dot, .dot]
        case .c: return [.dash, .dot, .dash, .dot]
        case .d: return [.dash, .dot, .dot]
        case .e: return [.dot]
        case .f: return [.dot, .dot, .dash, .dot]
        case .g: return [.dash, .dash, .dot]
        case .h: return [.dot, .dot, .dot, .dot]
        case .i: return [.dot, .dot]
        case .j: return [.dot, .dash, .dash, .dash]
        case .k: return [.dash, .dot, .dash]
        case .l: return [.dot, .dash, .dot, .dot]
        case .m: return [.dash, .dash]
        case .n: return [.dash, .dot]
        case .o: return [.dash, .dash, .dash]
        case .p: return [.dot, .dash, .dash, .dot]
        case .q: return [.dash, .dash, .dot, .dash]
        case .r: return [.dot, .dash, .dot]
        case .s: return [.dot, .dot, .dot]
        case .t: return [.dash]
        case .u: return [.dot, .dot, .dash]
        case .v: return [.dot, .dot, .dot, .dash]
        case .w: return [.dot, .dash, .dash]
        case .x: return [.dash, .dot, .dot, .dash]
        case .y: return [.dash, .dot, .dash, .dash]
        case .z: return [.dash, .dash, .dot, .dot]
        }
    }
}
