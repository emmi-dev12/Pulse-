import SwiftUI

struct OnboardingPageConvex: View {
    @Binding var convexURL: String
    @Binding var deployKey: String
    @Binding var isValid: Bool
    @State private var isTesting = false
    @State private var testResult: Bool? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            header

            VStack(alignment: .leading, spacing: 16) {
                field("Convex Deployment URL", placeholder: "https://happy-animal-123.convex.cloud",
                      text: $convexURL)
                field("Deploy Key", placeholder: "prod:abc123...", text: $deployKey,
                      secure: true)
            }

            HStack(spacing: 12) {
                Button("Test Connection") {
                    Task { await testConnection() }
                }
                .buttonStyle(NeonButtonStyle(small: true))
                .disabled(convexURL.isEmpty || deployKey.isEmpty || isTesting)

                if isTesting {
                    ProgressView().scaleEffect(0.7)
                } else if let result = testResult {
                    Image(systemName: result ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(result ? Color(hex: "00E676") : Color(hex: "FF3B30"))
                    Text(result ? "Connected" : "Could not connect")
                        .font(.system(size: 12))
                        .foregroundColor(result ? Color(hex: "00E676") : Color(hex: "FF3B30"))
                }
            }

            Text("Find your deployment URL and key in the Convex dashboard under Settings → URL & Deploy Key.")
                .font(.system(size: 12))
                .foregroundColor(.pulseTextTertiary)
                .lineSpacing(3)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("01")
                .font(.system(size: 11, weight: .medium))
                .tracking(2)
                .foregroundColor(.pulseAccent)
            Text("Connect Convex")
                .font(.custom("Georgia", size: 26).weight(.light))
                .foregroundColor(.pulseTextPrimary)
            Text("Your personal backend for real-time history sync.")
                .font(.system(size: 13))
                .foregroundColor(.pulseTextSecondary)
        }
    }

    private func testConnection() async {
        isTesting = true
        testResult = nil

        // Temporarily save to keychain for the test
        let keychain = KeychainService()
        keychain.save(convexURL, for: .convexURL)
        keychain.save(deployKey, for: .convexDeployKey)

        let client = ConvexClient()
        let success = await client.testConnection()
        testResult = success
        isValid = success
        isTesting = false
    }

    private func field(_ label: String, placeholder: String,
                       text: Binding<String>, secure: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .tracking(1.2)
                .foregroundColor(.pulseTextSecondary)
                .textCase(.uppercase)
            if secure {
                SecureField(placeholder, text: text)
                    .textFieldStyle(PulseFieldStyle())
            } else {
                TextField(placeholder, text: text)
                    .textFieldStyle(PulseFieldStyle())
            }
        }
    }
}

struct PulseFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.system(size: 13, design: .monospaced))
            .foregroundColor(.pulseTextPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(Color.pulseSurface)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.pulseTextTertiary.opacity(0.3), lineWidth: 1)
            )
    }
}
