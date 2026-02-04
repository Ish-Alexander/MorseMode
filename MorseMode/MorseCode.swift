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
    
    var letterRepresentation: String {
        switch self {
        case .a:
            "a"
        case .b:
            "b"
        case .c:
            "c"
        case .d:
            "d"
        case .e:
            "e"
        case .f:
            "f"
        case .g:
            "g"
        case .h:
            "h"
        case .i:
            "i"
        case .j:
            "j"
        case .k:
            "k"
        case .l:
            "l"
        case .m:
            "m"
        case .n:
            "n"
        case .o:
            "o"
        case .p:
            "p"
        case .q:
            "q"
        case .r:
            "r"
        case .s:
            "s"
        case .t:
            "t"
        case .u:
            "u"
        case .v:
            "v"
        case .w:
            "w"
        case .x:
            "x"
        case .y:
            "y"
        case .z:
            "z"
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
