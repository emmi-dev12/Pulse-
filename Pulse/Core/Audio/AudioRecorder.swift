import AVFoundation
import Combine

final class AudioRecorder: ObservableObject {
    @Published var averagePower: Float = 0.0  // 0.0–1.0

    private var engine = AVAudioEngine()
    private var audioFile: AVAudioFile?
    private var converter: AVAudioConverter?
    private let targetFormat = AVAudioFormat(
        commonFormat: .pcmFormatInt16,
        sampleRate: 16000,
        channels: 1,
        interleaved: true
    )!
    private(set) var currentURL: URL?

    enum RecordingError: Error {
        case formatUnsupported
        case engineStartFailed(Error)
        case fileFailed(Error)
    }

    func startRecording() throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".wav")
        currentURL = tempURL

        let inputNode = engine.inputNode
        let hardwareFormat = inputNode.outputFormat(forBus: 0)

        audioFile = try AVAudioFile(forWriting: tempURL,
                                    settings: targetFormat.settings,
                                    commonFormat: .pcmFormatInt16,
                                    interleaved: true)

        converter = AVAudioConverter(from: hardwareFormat, to: targetFormat)

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: hardwareFormat) { [weak self] buffer, _ in
            self?.processTapBuffer(buffer, inputFormat: hardwareFormat)
        }

        try engine.start()
    }

    func stopRecording() -> URL? {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        audioFile = nil
        converter = nil
        let url = currentURL
        currentURL = nil
        return url
    }

    // MARK: - Buffer processing

    private func processTapBuffer(_ buffer: AVAudioPCMBuffer, inputFormat: AVAudioFormat) {
        updateLevel(from: buffer)
        convertAndWrite(buffer, inputFormat: inputFormat)
    }

    private func convertAndWrite(_ inputBuffer: AVAudioPCMBuffer, inputFormat: AVAudioFormat) {
        guard let converter,
              let audioFile,
              let outputBuffer = AVAudioPCMBuffer(
                pcmFormat: targetFormat,
                frameCapacity: AVAudioFrameCount(
                    Double(inputBuffer.frameLength) * (targetFormat.sampleRate / inputFormat.sampleRate) + 1
                )
              )
        else { return }

        var error: NSError?
        var inputConsumed = false
        converter.convert(to: outputBuffer, error: &error) { _, outStatus in
            if inputConsumed {
                outStatus.pointee = .noDataNow
                return nil
            }
            inputConsumed = true
            outStatus.pointee = .haveData
            return inputBuffer
        }

        if error == nil && outputBuffer.frameLength > 0 {
            try? audioFile.write(from: outputBuffer)
        }
    }

    private func updateLevel(from buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let count = Int(buffer.frameLength)
        guard count > 0 else { return }

        var sumSquares: Float = 0
        for i in 0..<count { sumSquares += channelData[i] * channelData[i] }
        let rms = sqrt(sumSquares / Float(count))

        // Convert to 0–1 range using a -60dB floor
        let db = 20 * log10(max(rms, 1e-6))
        let normalized = max(0, min(1, (db + 60) / 60))

        DispatchQueue.main.async { self.averagePower = normalized }
    }
}
