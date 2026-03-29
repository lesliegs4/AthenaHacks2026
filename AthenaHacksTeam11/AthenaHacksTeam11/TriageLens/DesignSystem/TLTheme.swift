import SwiftUI

enum TLTheme {
    static let cornerRadius: CGFloat = 16
    static let cardPadding: CGFloat = 16
    static let sidebarWidth: CGFloat = 280

    enum Spacing {
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

    enum ColorToken {
        static let bg = Color(red: 0.06, green: 0.07, blue: 0.09)
        static let surface = Color(red: 0.10, green: 0.11, blue: 0.14)
        static let surface2 = Color(red: 0.13, green: 0.14, blue: 0.18)
        static let stroke = Color.white.opacity(0.10)

        static let text = Color.white.opacity(0.92)
        static let textSecondary = Color.white.opacity(0.68)
        static let textTertiary = Color.white.opacity(0.48)

        static let red = Color(red: 0.94, green: 0.34, blue: 0.36)
        static let amber = Color(red: 0.98, green: 0.73, blue: 0.22)
        static let green = Color(red: 0.26, green: 0.86, blue: 0.54)
        static let blue = Color(red: 0.34, green: 0.66, blue: 0.98)
    }
}

extension View {
    func tlCard() -> some View {
        self
            .padding(TLTheme.cardPadding)
            .background(TLTheme.ColorToken.surface)
            .overlay(
                RoundedRectangle(cornerRadius: TLTheme.cornerRadius)
                    .stroke(TLTheme.ColorToken.stroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: TLTheme.cornerRadius))
    }
}

