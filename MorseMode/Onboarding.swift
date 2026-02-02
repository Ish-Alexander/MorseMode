//
//  Onboarding.swift
//  MorseMode
//
//  Created by Ishauna Marie Alexander on 1/27/26.
//

import SwiftUI

struct OnboardingItem: Identifiable {
    let id = UUID()
    let imageName: String
    let title: String
    let description: String
}

let onboardingData: [OnboardingItem] = [
    OnboardingItem(imageName: "", title: "Step 1", description: "" ),
    OnboardingItem(imageName: "", title: "Step 2", description: "" ),
    OnboardingItem(imageName: "", title: "Step 3", description: "" )
]
