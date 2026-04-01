import SwiftUI

struct DailyIntroLoadingView: View {
    var onFinished: () -> Void

    @State private var showWarning1: Bool = true
    @State private var warning1Opacity: Double = 1.0
    @State private var showWarning2: Bool = false
    @State private var hasStarted: Bool = false

    private let flashInterval: TimeInterval = 0.2
    private let totalFlashDuration: TimeInterval = 1.2
    private let crossfadeDuration: TimeInterval = 0.6

    public init(onFinished: @escaping () -> Void) {
        self.onFinished = onFinished
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ZStack {
                // Warning2 fades in
                Image("Warning2")
                    .resizable()
                    .scaledToFit()
                    .opacity(showWarning2 ? 1 : 0)
                    .frame(maxWidth: 280)

                // Warning1 flashes then fades out
                Image("Warning1")
                    .resizable()
                    .scaledToFit()
                    .opacity(showWarning1 ? warning1Opacity : 0)
                    .frame(maxWidth: 280)
            }
        }
        .onAppear {
            startSequence()
        }
    }

    private func startSequence() {
        guard !hasStarted else { return }
        hasStarted = true

        // Start flashing Warning1
        var elapsed: TimeInterval = 0
        func scheduleNextFlash() {
            guard elapsed < totalFlashDuration else {
                // Start crossfade to Warning2
                withAnimation(.easeInOut(duration: crossfadeDuration)) {
                    showWarning2 = true
                    warning1Opacity = 0
                }
                showWarning1 = false
                // After crossfade completes, wait briefly then finish
                DispatchQueue.main.asyncAfter(deadline: .now() + crossfadeDuration + 0.6) {
                    onFinished()
                }
                return
            }
            withAnimation(.easeInOut(duration: flashInterval)) {
                warning1Opacity = (warning1Opacity < 0.6) ? 1.0 : 0.2
            }
            elapsed += flashInterval
            DispatchQueue.main.asyncAfter(deadline: .now() + flashInterval) {
                scheduleNextFlash()
            }
        }
        scheduleNextFlash()
    }
}

#Preview {
    DailyIntroLoadingView(onFinished: {})
}
