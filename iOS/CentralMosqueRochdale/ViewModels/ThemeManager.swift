import SwiftUI

class ThemeManager: ObservableObject {
    @Published var isDarkMode: Bool {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
        }
    }
    
    init() {
        self.isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
    }
    
    var colorScheme: ColorScheme {
        isDarkMode ? .dark : .light
    }
    
    // Central Mosque Rochdale Brand Colors
    static let primaryGold = Color(hex: "#B5A77D")
    static let secondaryPurple = Color(hex: "#564E58")
    static let accentRose = Color(hex: "#904E55")
    static let lightBackground = Color(hex: "#F2EFE9")
    static let darkBackground = Color(hex: "#252627")
    
    // Computed properties for theme-aware colors
    var primaryColor: Color {
        ThemeManager.primaryGold
    }
    
    var secondaryColor: Color {
        ThemeManager.secondaryPurple
    }
    
    var accentColor: Color {
        ThemeManager.accentRose
    }
    
    var backgroundColor: Color {
        isDarkMode ? ThemeManager.darkBackground : ThemeManager.lightBackground
    }
    
    var cardBackground: Color {
        isDarkMode ? Color(hex: "#2F2F30") : Color.white
    }
    
    var textPrimary: Color {
        isDarkMode ? Color.white : ThemeManager.darkBackground
    }
    
    var textSecondary: Color {
        isDarkMode ? Color.gray : ThemeManager.secondaryPurple.opacity(0.7)
    }
}

// Extension to create Color from hex string
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
