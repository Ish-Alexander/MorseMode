import Foundation
import AVFoundation

final class WatchAudioPlayer {
    static let shared = WatchAudioPlayer()
    private var player: AVAudioPlayer?

    private init() {}

    func play(letter: Character) {
        let upper = String(letter).uppercased()
        guard let first = upper.first, first.isLetter else {
            stop()
            return
        }
        let baseName = "\(first)_morse_code"
        let candidateExtensions = ["ogg.mp3", "mp3", "ogg", "wav", "m4a"]
        var foundURL: URL? = nil
        for ext in candidateExtensions {
            if let url = Bundle.main.url(forResource: baseName, withExtension: ext) {
                foundURL = url
                break
            }
        }
        guard let url = foundURL else {
            stop()
            print("[WatchAudio] No audio for letter \(first). Tried: \(candidateExtensions.map { "\(baseName).\($0)" }.joined(separator: ", "))")
            return
        }
        do {
            if let p = player, p.url == url {
                p.currentTime = 0
                p.play()
            } else {
                let p = try AVAudioPlayer(contentsOf: url)
                p.prepareToPlay()
                p.play()
                player = p
            }
        } catch {
            print("[WatchAudio] Failed to play \(url.lastPathComponent): \(error)")
        }
    }

    func stop() {
        player?.stop()
        player = nil
    }
}
