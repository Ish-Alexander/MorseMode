//
//  Avatarstore.swift
//  MorseMode
//
//  Created by Wisdom Ogwonuwe on 4/26/26.
//

import SwiftUI
import Combine

@MainActor
final class AvatarStore: ObservableObject {
    static let shared = AvatarStore()

    @Published var avatarIndex: Int = -1
    @Published var customAvatarData: Data?

    var customAvatar: UIImage? {
        get { customAvatarData.flatMap { UIImage(data: $0) } }
        set { customAvatarData = newValue?.jpegData(compressionQuality: 0.85) }
    }

    private init() {
        let extras = ProfileExtras.load()
        avatarIndex = extras.avatarIndex
        if let data = UserDefaults.standard.data(forKey: "customAvatarData") {
            customAvatarData = data
        }
    }

    func save(index: Int, image: UIImage?) {
        avatarIndex = index
        customAvatar = image
        if let data = customAvatarData {
            UserDefaults.standard.set(data, forKey: "customAvatarData")
        } else {
            UserDefaults.standard.removeObject(forKey: "customAvatarData")
        }
        var extras = ProfileExtras.load()
        extras.avatarIndex = index
        extras.save()
    }
}
