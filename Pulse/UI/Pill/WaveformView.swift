import SwiftUI

struct WaveformView: View {
    let amplitudes: [Float]

    var body: some View {
        HStack(alignment: .center, spacing: 3) {
            ForEach(0..<5, id: \.self) { i in
                let amp = i < amplitudes.count ? CGFloat(amplitudes[i]) : 0.15
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white)
                    .frame(width: 3, height: amp * 22 + 4)
                    .animation(
                        .easeInOut(duration: 0.08).delay(Double(i) * 0.015),
                        value: amplitudes
                    )
            }
        }
    }
}
