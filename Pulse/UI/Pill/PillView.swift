import SwiftUI

struct PillView: View {
    @ObservedObject var viewModel: PillViewModel

    var body: some View {
        ZStack {
            Capsule()
                .fill(Color.pulseAccent)
                .shadow(color: Color.pulseAccent.opacity(0.65), radius: 14, x: 0, y: 0)

            HStack(spacing: 8) {
                Circle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 6, height: 6)

                WaveformView(amplitudes: viewModel.barAmplitudes)
            }
            .padding(.horizontal, 16)
        }
        .frame(width: 140, height: 44)
        .opacity(viewModel.isVisible ? 1 : 0)
        .scaleEffect(viewModel.isVisible ? 1 : 0.75)
        .animation(.spring(response: 0.28, dampingFraction: 0.65), value: viewModel.isVisible)
    }
}
