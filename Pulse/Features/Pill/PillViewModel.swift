import Foundation
import Combine

@MainActor
final class PillViewModel: ObservableObject {
    @Published var isVisible: Bool = false
    @Published var barAmplitudes: [Float] = [0.15, 0.25, 0.4, 0.25, 0.15]

    private var animationTimer: Timer?
    private var audioRecorder: AudioRecorder?
    private var cancellables = Set<AnyCancellable>()

    func bind(to recorder: AudioRecorder) {
        audioRecorder = recorder
        recorder.$averagePower
            .receive(on: RunLoop.main)
            .sink { [weak self] power in self?.updateAmplitudes(power: power) }
            .store(in: &cancellables)
    }

    func show() {
        isVisible = true
        startIdleAnimation()
    }

    func hide() {
        isVisible = false
        stopAnimation()
        barAmplitudes = [0.15, 0.25, 0.4, 0.25, 0.15]
    }

    // MARK: - Animation

    private func updateAmplitudes(power: Float) {
        guard isVisible else { return }
        stopAnimation()
        // Center bar gets full power; outer bars taper
        let tapers: [Float] = [0.5, 0.75, 1.0, 0.75, 0.5]
        let minH: Float = 0.1
        barAmplitudes = tapers.map { max(minH, power * $0) }
    }

    private func startIdleAnimation() {
        guard animationTimer == nil else { return }
        var phase: Float = 0
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
            phase += 0.3
            let center: Float = 0.3 + 0.15 * sin(phase)
            self?.barAmplitudes = [
                0.15 + 0.1 * sin(phase + 1.0),
                0.2  + 0.15 * sin(phase + 0.5),
                center,
                0.2  + 0.15 * sin(phase - 0.5),
                0.15 + 0.1 * sin(phase - 1.0)
            ]
        }
    }

    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
}
