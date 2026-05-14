import SwiftUI

struct TranscriptDisplayView: View {
    @EnvironmentObject var coordinator: RecordingCoordinator

    var body: some View {
        VStack(spacing: 20) {
            stateIndicator
            transcriptText
        }
        .padding(.horizontal, 44)
    }

    @ViewBuilder
    private var stateIndicator: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(indicatorColor)
                .frame(width: 6, height: 6)
                .shadow(color: indicatorColor.opacity(0.8), radius: 4)
            Text(indicatorLabel)
                .font(.system(size: 11, weight: .medium))
                .tracking(1.8)
                .foregroundColor(.pulseTextSecondary)
                .textCase(.uppercase)
        }
        .animation(.easeInOut(duration: 0.2), value: coordinator.state)
    }

    private var transcriptText: some View {
        Group {
            if coordinator.lastTranscript.isEmpty {
                Text("Hold ⌥ Space to dictate")
                    .font(.custom("Georgia", size: 38).weight(.light))
                    .italic()
                    .foregroundColor(.pulseTextTertiary)
                    .multilineTextAlignment(.center)
            } else {
                Text(coordinator.lastTranscript)
                    .font(.custom("Georgia", size: 38).weight(.light))
                    .foregroundColor(.pulseTextPrimary)
                    .multilineTextAlignment(.center)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .animation(.easeInOut(duration: 0.35), value: coordinator.lastTranscript)
        .lineSpacing(8)
    }

    private var indicatorColor: Color {
        switch coordinator.state {
        case .idle:         return Color(white: 0.3)
        case .recording:    return .pulseAccent
        case .transcribing: return Color(hex: "FF8C00")
        case .error:        return Color(hex: "FF3B30")
        }
    }

    private var indicatorLabel: String {
        switch coordinator.state {
        case .idle:                return "Ready"
        case .recording:           return "Recording"
        case .transcribing:        return "Transcribing"
        case .error(let msg):      return msg
        }
    }
}
