import SwiftUI

struct ColorTheme {
    static let primary = Color(red: 97 / 255, green: 70 / 255, blue: 170 / 255)
    static let secondary = Color(red: 142 / 255, green: 111 / 255, blue: 210 / 255)
    static let accent = Color(red: 175 / 255, green: 145 / 255, blue: 230 / 255)
    static let background = Color(red: 244 / 255, green: 244 / 255, blue: 247 / 255)
    static let secondaryBackground = Color(red: 243 / 255, green: 240 / 255, blue: 250 / 255)
    static let text = Color(red: 28 / 255, green: 25 / 255, blue: 43 / 255)
    static let mutedText = Color(red: 110 / 255, green: 105 / 255, blue: 135 / 255)
    static let cardBackground = Color.white

    static let success = Color(red: 105 / 255, green: 178 / 255, blue: 106 / 255)
    static let warning = Color(red: 242 / 255, green: 184 / 255, blue: 75 / 255)
    static let error = Color(red: 222 / 255, green: 82 / 255, blue: 102 / 255)

    static let shadowColor = Color.black.opacity(0.06)
}

extension Color {
    static let theme = ColorTheme.self
}
