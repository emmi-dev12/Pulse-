import SwiftUI

struct ContentView: View {
    @EnvironmentObject var coordinator: RecordingCoordinator
    @EnvironmentObject var convexClient: ConvexClient

    var body: some View {
        ZStack(alignment: .top) {
            Color.pulseBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.top, 24)
                    .padding(.bottom, 12)

                Spacer()

                TranscriptDisplayView()

                Spacer()

                HistoryTimelineView()
                    .frame(height: 220)
            }
        }
        .frame(minWidth: 620, minHeight: 520)
        .preferredColorScheme(.dark)
    }

    private var topBar: some View {
        HStack {
            Text("PULSE")
                .font(.system(size: 12, weight: .semibold, design: .default))
                .tracking(5)
                .foregroundColor(.pulseTextSecondary)

            Spacer()

            HStack(spacing: 6) {
                Circle()
                    .fill(convexClient.isOnline ? Color(hex: "00E676") : Color.pulseTextTertiary)
                    .frame(width: 5, height: 5)
                    .shadow(color: convexClient.isOnline ? Color(hex: "00E676").opacity(0.7) : .clear,
                            radius: 4)
                Text(convexClient.isOnline ? "Synced" : "Offline")
                    .font(.system(size: 11))
                    .foregroundColor(.pulseTextTertiary)
            }
            .animation(.easeInOut, value: convexClient.isOnline)
        }
        .padding(.horizontal, 28)
    }
}
