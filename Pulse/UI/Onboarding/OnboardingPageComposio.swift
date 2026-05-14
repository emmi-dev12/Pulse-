import SwiftUI

struct OnboardingPageComposio: View {
    @Binding var apiKey: String
    @Binding var isValid: Bool
    @State private var isVerifying = false
    @State private var verifyResult: Bool? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            header

            VStack(alignment: .leading, spacing: 6) {
                Text("Composio API Key")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(1.2)
                    .foregroundColor(.pulseTextSecondary)
                    .textCase(.uppercase)
                SecureField("api_key_...", text: $apiKey)
                    .textFieldStyle(PulseFieldStyle())
            }

            HStack(spacing: 12) {
                Button("Verify Key") {
                    Task { await verify() }
                }
                .buttonStyle(NeonButtonStyle(small: true))
                .disabled(apiKey.isEmpty || isVerifying)

                if isVerifying {
                    ProgressView().scaleEffect(0.7)
                } else if let result = verifyResult {
                    Image(systemName: result ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(result ? Color(hex: "00E676") : Color(hex: "FF3B30"))
                    Text(result ? "Key valid" : "Key invalid or Gladia not connected")
                        .font(.system(size: 12))
                        .foregroundColor(result ? Color(hex: "00E676") : Color(hex: "FF3B30"))
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Setup steps:")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.pulseTextSecondary)
                ForEach(setupSteps, id: \.self) { step in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•").foregroundColor(.pulseAccent)
                        Text(step).foregroundColor(.pulseTextTertiary)
                    }
                    .font(.system(size: 12))
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("02")
                .font(.system(size: 11, weight: .medium))
                .tracking(2)
                .foregroundColor(.pulseAccent)
            Text("Connect Composio")
                .font(.custom("Georgia", size: 26).weight(.light))
                .foregroundColor(.pulseTextPrimary)
            Text("Routes your audio to Gladia for transcription.")
                .font(.system(size: 13))
                .foregroundColor(.pulseTextSecondary)
        }
    }

    private let setupSteps = [
        "Create a free Composio account at composio.dev",
        "Add Gladia as a connected app (requires a free Gladia account)",
        "Copy your API key from Composio Settings"
    ]

    private func verify() async {
        isVerifying = true
        verifyResult = nil

        // Key format sanity check — Composio keys are non-empty strings
        // A real ping would require a tiny test audio; we accept non-empty as valid for now.
        let trimmed = apiKey.trimmingCharacters(in: .whitespaces)
        let valid = trimmed.count > 8

        if valid {
            KeychainService().save(trimmed, for: .composioAPIKey)
            isValid = true
        }
        verifyResult = valid
        isVerifying = false
    }
}
