//
//  WatchSessionManager.swift
//  MorseModeWatch
//
//  Created by Assistant on 2/10/26.
//

import Foundation
import WatchConnectivity
#if os(watchOS)
import WatchKit
#endif
#if canImport(CoreHaptics)
import CoreHaptics
import Combine
#endif

/// A singleton to manage Watch Connectivity on the watch and play incoming Morse haptics.
@MainActor
final class WatchSessionManager: NSObject, ObservableObject {
    
    static let shared = WatchSessionManager()
    
    private override init() {
        super.init()
        activate()
    }
    
#if canImport(CoreHaptics)
    private var hapticEngine: CHHapticEngine?
#endif
    
    func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }
    
    private func handle(payload: [String: Any]) {
        guard let morse = payload["morseClue"] as? String else { return }
        playMorseHaptics(morse)
    }
    
    private func playMorseHaptics(_ morse: String) {
        // Base timing unit (seconds) — match iOS side for rough sync
        let unit: TimeInterval = 0.08
        let dot = unit
        let dash = unit * 3
        let intraCharGap = unit
        let interCharGap = unit * 6
        let wordGap = unit * 7
        
#if canImport(CoreHaptics)
        // Try Core Haptics first for richer feel
        do {
            if hapticEngine == nil {
                hapticEngine = try CHHapticEngine()
            }
            guard let engine = hapticEngine else { return }
            try engine.start()
            
            var events: [CHHapticEvent] = []
            var relativeTime: TimeInterval = 0
            
            func addDot() {
                let event = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
                    ],
                    relativeTime: relativeTime
                )
                events.append(event)
                relativeTime += dot
            }

            func addDash() {
                let attack = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.55)
                    ],
                    relativeTime: relativeTime
                )
                let body = CHHapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                    ],
                    relativeTime: relativeTime + 0.02,
                    duration: max(dash - 0.02, unit * 2.5)
                )
                events.append(attack)
                events.append(body)
                relativeTime += dash
            }
            
            for ch in morse {
                switch ch {
                case ".":
                    addDot()
                    relativeTime += intraCharGap
                case "-":
                    addDash()
                    relativeTime += intraCharGap
                case " ":
                    relativeTime += (interCharGap - intraCharGap)
                case "/":
                    relativeTime += (wordGap - intraCharGap)
                default:
                    break
                }
            }
            
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
            return
        } catch {
            // Fall through to WatchKit haptics
        }
#endif
        
#if os(watchOS)
        // WatchKit fallback: pulse discrete taps to suggest dots/dashes
        var delay: TimeInterval = 0
        func scheduleDotTap() {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                WKInterfaceDevice.current().play(.click)
            }
            delay += dot
        }

        func scheduleDashBurst(duration: TimeInterval) {
            // Fire stronger directional pulses so dashes feel heavier than dots.
            let step = max(unit / 2, 0.04)
            var t: TimeInterval = 0
            while t < duration {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay + t) {
                    WKInterfaceDevice.current().play(.directionUp)
                }
                t += step
            }
            delay += duration
        }
        
        for ch in morse {
            switch ch {
            case ".":
                scheduleDotTap()
                delay += intraCharGap
            case "-":
                scheduleDashBurst(duration: dash)
                delay += intraCharGap
            case " ":
                delay += (interCharGap - intraCharGap)
            case "/":
                delay += (wordGap - intraCharGap)
            default:
                break
            }
        }
#else
        // Non-watchOS: no haptic fallback available
#endif
    }
}

extension WatchSessionManager: WCSessionDelegate {
    func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // No-op
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        handle(payload: message)
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        handle(payload: userInfo)
    }
}
