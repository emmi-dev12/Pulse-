import SwiftUI

struct OnboardingView: View {
    var onComplete: (() -> Void)?

    @State private var page = 0
    @State private var convexURL = ""
    @State private var deployKey = ""
    @State private var composioKey = ""
    @State private var convexValid = false
    @State private var composioValid = false

    var body: some View {
        ZStack {
            Color.pulseBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Page content
                ZStack {
                    pageContent(for: 0).opacity(page == 0 ? 1 : 0)
                    pageContent(for: 1).opacity(page == 1 ? 1 : 0)
                    pageContent(for: 2).opacity(page == 2 ? 1 : 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.horizontal, 40)
                .padding(.top, 40)

                Spacer()

                // Bottom nav
                HStack {
                    // Page dots
                    HStack(spacing: 6) {
                        ForEach(0..<3) { i in
                            Circle()
                                .fill(i == page ? Color.pulseAccent : Color.pulseTextTertiary)
                                .frame(width: i == page ? 6 : 4, height: i == page ? 6 : 4)
                                .animation(.spring(response: 0.3), value: page)
                        }
                    }

                    Spacer()

                    HStack(spacing: 12) {
                        if page > 0 {
                            Button("Back") { withAnimation { page -= 1 } }
                                .font(.system(size: 13))
                                .foregroundColor(.pulseTextSecondary)
                        }

                        Button(page < 2 ? "Continue" : "Start Dictating") {
                            advance()
                        }
                        .buttonStyle(NeonButtonStyle())
                        .disabled(!canAdvance)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 36)
            }
        }
        .preferredColorScheme(.dark)
        .frame(width: 520, height: 580)
    }

    @ViewBuilder
    private func pageContent(for index: Int) -> some View {
        switch index {
        case 0: OnboardingPageConvex(convexURL: $convexURL, deployKey: $deployKey, isValid: $convexValid)
        case 1: OnboardingPageComposio(apiKey: $composioKey, isValid: $composioValid)
        case 2: OnboardingPagePermissions()
        default: EmptyView()
        }
    }

    private var canAdvance: Bool {
        switch page {
        case 0: return convexValid
        case 1: return composioValid
        case 2: return true
        default: return false
        }
    }

    private func advance() {
        if page < 2 {
            withAnimation(.easeInOut(duration: 0.25)) { page += 1 }
        } else {
            saveCredentials()
            onComplete?()
        }
    }

    private func saveCredentials() {
        let keychain = KeychainService()
        keychain.save(convexURL.trimmingCharacters(in: .whitespaces), for: .convexURL)
        keychain.save(deployKey.trimmingCharacters(in: .whitespaces), for: .convexDeployKey)
        keychain.save(composioKey.trimmingCharacters(in: .whitespaces), for: .composioAPIKey)
    }
}
