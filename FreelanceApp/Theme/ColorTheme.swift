import SwiftUI

struct ColorTheme {
    static let primary = Color("Primary")
    static let secondary = Color("Secondary")
    static let accent = Color("Accent")
    static let background = Color("Background")
    static let text = Color("Text")
    
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
    
    static let cardBackground = Color("CardBackground")
    static let shadowColor = Color.black.opacity(0.1)
}

extension Color {
    static let theme = ColorTheme.self
}
