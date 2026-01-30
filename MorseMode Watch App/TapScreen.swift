//
//  TapScreen.swift
//  MorseMode
//
//  Created by Ishauna Marie Alexander on 1/27/26.
//

import SwiftUI
import WatchKit

struct TapScreen: View {
    
    @State private var rotationAngle: Double = 0
    @State private var isPressing = false
    private let hapticType: WKHapticType = .click
    
    var body: some View{
        VStack{
            Button(action: {}) {
                Image("Radar")
                    .resizable()
                    .scaledToFit()
                    .rotationEffect(.degrees(rotationAngle))
                    .onAppear() {
                        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false).speed(0.25)) {
                            rotationAngle = 360
                        }
                    }
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.0)
                            .onEnded { _ in
                                isPressing = false
                            }
                    )
                    .onLongPressGesture(minimumDuration: 0.0, pressing: { pressing in
                        isPressing = pressing
                        if pressing {
                            WKInterfaceDevice.current().play(hapticType)
                        }
                    }, perform: {})
            }
        }
    }
}
#Preview{
    TapScreen()
}
