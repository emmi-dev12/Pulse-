import SwiftUI
import AVFoundation
import ApplicationServices

struct OnboardingPagePermissions: View {
    @State private var micGranted: Bool = false
    @State private var accessibilityGranted: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            header

            VStack(spacing: 12) {
                permissionRow(
                    icon: "mic.fill",
                    title: "Microphone",
                    description: "To record audio for transcription",
                    granted: micGranted,
                    action: requestMic
                )
                permissionRow(
                    icon: "accessibility",
                    title: "Accessibility",
                    description: "To inject transcripts into focused text fields",
                    granted: accessibilityGranted,
                    action: openAccessibilitySettings
                )
            }

            Text("You can grant these permissions later in System Settings → Privacy & Security.")
                .font(.system(size: 12))
                .foregroundColor(.pulseTextTertiary)
                .lineSpacing(3)
        }
        .onAppear { checkStatuses() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("03")
                .font(.system(size: 11, weight: .medium))
                .tracking(2)
                .foregroundColor(.pulseAccent)
            Text("Grant Permissions")
                .font(.custom("Georgia", size: 26).weight(.light))
                .foregroundColor(.pulseTextPrimary)
            Text("Pulse needs two system permissions to work.")
                .font(.system(size: 13))
                .foregroundColor(.pulseTextSecondary)
        }
    }

    private func permissionRow(icon: String, title: String, description: String,
                               granted: Bool, action: @escaping () -> Void) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.pulseSurface)
                    .frame(width: 42, height: 42)
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(granted ? .pulseAccent : .pulseTextSecondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.pulseTextPrimary)
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.pulseTextSecondary)
            }

            Spacer()

            if granted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color(hex: "00E676"))
                    .font(.system(size: 18))
            } else {
                Button("Grant") { action() }
                    .buttonStyle(NeonButtonStyle(small: true))
            }
        }
        .padding(14)
        .background(Color.pulseSurface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(granted ? Color.pulseAccent.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }

    // MARK: - Actions

    private func requestMic() {
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            DispatchQueue.main.async { micGranted = granted }
        }
    }

    private func openAccessibilitySettings() {
        NSWorkspace.shared.open(
            URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        )
        // Re-check after a short delay to catch immediate grants
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { checkStatuses() }
    }

    private func checkStatuses() {
        micGranted = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
        accessibilityGranted = AXIsProcessTrusted()
    }
}
