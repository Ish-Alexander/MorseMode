import SwiftUI

struct WatchMorseInputView: View {
    @State private var pattern: String = ""
    @ObservedObject private var connectivity = WatchConnectivityManager.shared

    var body: some View {
        VStack(spacing: 8) {
            Text("Morse Input")
                .font(.headline)

            Text(pattern.isEmpty ? "Tap · or −" : pattern)
                .font(.system(.body, design: .monospaced))
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            HStack(spacing: 8) {
                Button("·") { pattern.append(".") }
                    .buttonStyle(.borderedProminent)
                Button("−") { pattern.append("-") }
                    .buttonStyle(.borderedProminent)
            }

            HStack(spacing: 8) {
                Button("Send") {
                    guard !pattern.isEmpty else { return }
                    WatchConnectivityManager.shared.sendMorseInput(pattern: pattern)
                    pattern.removeAll()
                }
                .buttonStyle(.bordered)
                .disabled(!connectivity.isReachable || pattern.isEmpty)

                Button("Clear") {
                    pattern.removeAll()
                }
                .buttonStyle(.bordered)
            }

            if !connectivity.isReachable {
                Text("iPhone not reachable")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .onAppear {
            // Ensure session is activated when the view appears
            WatchConnectivityManager.shared.activate()
        }
    }
}

#Preview {
    WatchMorseInputView()
}
