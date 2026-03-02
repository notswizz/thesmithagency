import SwiftUI

extension Color {
    static let brand = Color(red: 255/255, green: 20/255, blue: 147/255)       // Hot pink
    static let brandDark = Color(red: 200/255, green: 10/255, blue: 110/255)   // Deeper pink
    static let brandNavy = Color.white                                          // Primary text on dark
    static let surfacePrimary = Color(red: 10/255, green: 10/255, blue: 10/255)  // Near-black bg
    static let surfaceCard = Color(red: 22/255, green: 22/255, blue: 22/255)     // Card bg
    static let surfaceElevated = Color(red: 32/255, green: 32/255, blue: 32/255) // Elevated card
    static let borderSubtle = Color.white.opacity(0.08)
    static let textPrimary = Color.white
    static let textSecondary = Color(red: 200/255, green: 200/255, blue: 204/255)
    static let textTertiary = Color(red: 174/255, green: 174/255, blue: 178/255)
    static let brandBackground = Color(red: 10/255, green: 10/255, blue: 10/255)
    static let cardBackground = Color(red: 22/255, green: 22/255, blue: 22/255)
}

extension ShapeStyle where Self == Color {
    static var brand: Color { .brand }
    static var brandNavy: Color { .white }
    static var textPrimary: Color { .textPrimary }
    static var textSecondary: Color { .textSecondary }
    static var textTertiary: Color { .textTertiary }
}
