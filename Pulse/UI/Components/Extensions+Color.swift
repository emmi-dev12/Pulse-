import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8)  & 0xFF) / 255.0
        let b = Double(int & 0xFF)          / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

extension Color {
    static let pulseAccent     = Color(hex: "FF007F")
    static let pulseBackground = Color.black
    static let pulseSurface    = Color(white: 0.07)
    static let pulseTextPrimary   = Color.white
    static let pulseTextSecondary = Color(white: 0.45)
    static let pulseTextTertiary  = Color(white: 0.25)
}

struct NeonButtonStyle: ButtonStyle {
    var small: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: small ? 12 : 13, weight: .semibold))
            .foregroundColor(.black)
            .padding(.horizontal, small ? 14 : 22)
            .padding(.vertical, small ? 7 : 10)
            .background(Capsule().fill(Color.pulseAccent))
            .shadow(
                color: Color.pulseAccent.opacity(configuration.isPressed ? 0.25 : 0.55),
                radius: configuration.isPressed ? 6 : 16
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
