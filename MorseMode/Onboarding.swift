//
//  Onboarding.swift
//  MorseMode
//
//  Created by Ishauna Marie Alexander on 1/27/26.
//

import SwiftUI

struct OnboardingItem: Identifiable, Hashable {
    let id = UUID()
    let imageName: String
    let title: String
    let description: String
}

let onboardingData: [OnboardingItem] = [
    OnboardingItem(
        imageName: "wave.3.right",
        title: "Welcome to MorseMode",
        description: "Practice, translate, and learn Morse code. Use taps, audio, or text to communicate and build speed over time."
    ),
    OnboardingItem(
        imageName: "brain.filled.head.profile",
        title: "The Daily Intercept",
        description: "A 3 minute decoding challenge of morse code knowledge. Words are changed daily, and only shown as dots and dashes."
    ),
    OnboardingItem(
        imageName: "character.book.closed.fill",
        title: "Agency Academy",
        description: "Learn morse code one random letter at a time. Use your Apple Watch to input the correct morse code pattern and earn EXP."
    ),
    OnboardingItem(
        imageName: "house.fill",
        title: "The Warehouse",
        description: "A place to pratice how you want. Type in a message and listen to it play, or just focus on learning one specific letter."
    )
]
struct OnboardingView: View {
    @State private var selection: Int = 0
    // Which onboarding page is currently selected
    let items: [OnboardingItem]
    let onFinish: () -> Void

    var body: some View {
        VStack {
            TabView(selection: $selection) {
                ForEach(Array(items.enumerated()), id: \.0) { index, item in
                    OnboardingPage(item: item)
                        .tag(index)
                        .padding(.horizontal, 24)
                        .foregroundStyle(.neon)
                    // Swipeable onboarding pages, page tracking
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            // Makes it swipe horizontally

            PageControl(currentIndex: selection, count: items.count)
                .padding(.top, 12)
            // Custom dots

            HStack {
                if selection > 0 {
                    Button("Back") {
                        withAnimation { selection = max(0, selection - 1) }
                    }
                    .font(.custom("berkelium bitmap", size: 16))
                    .foregroundColor(.neon)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.neon, lineWidth: 1)
                    )
                    .background(Color.clear)
                } else {
                    // Keep layout consistent
                    Color.clear.frame(width: 1, height: 1)
                        .accessibilityHidden(true)
                }

                Spacer()

                Button(selection == items.count - 1 ? "Get Started" : "Next") {
                    if selection < items.count - 1 {
                        withAnimation { selection += 1 }
                    } else {
                        onFinish()
                        // Closes onboarding after last page is cleared
                    }
                }
                .font(.custom("berkelium bitmap", size: 16))
                .foregroundColor(Color.black)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.neon)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .foregroundColor(.neon)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .ignoresSafeArea()
        .tint(.neon)
    }
}

private struct OnboardingPage: View {
    let item: OnboardingItem

    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 24)

            if !item.imageName.isEmpty {
                Image(systemName: item.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 160, maxHeight: 160)
                    .foregroundStyle(.neon)
                    .accessibilityHidden(true)
            }

            Text(item.title)
                .font(.custom("berkelium bitmap", size: 28))
                .bold()
                .multilineTextAlignment(.center)
                .foregroundColor(.neon)

            Text(item.description)
                .font(.custom("berkelium bitmap", size: 16))
                .foregroundColor(.neon.opacity(0.85))
                .multilineTextAlignment(.center)

            Spacer(minLength: 24)
        }
    }
}

private struct PageControl: View {
    let currentIndex: Int
    let count: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { index in
                Circle()
                    .fill(index == currentIndex ? .neon : Color.white.opacity(0.2))
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut(duration: 0.2), value: currentIndex)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page \(currentIndex + 1) of \(count)")
    }
}

#Preview("Onboarding") {
    OnboardingView(items: onboardingData) { }
        .preferredColorScheme(.dark)
}

