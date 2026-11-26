import SwiftUI

/// Design tokens for Dance Progression Journal.
/// Single source of truth in code. Values must match docs/design/01_design_tokens.md.
/// If docs and code ever disagree, the docs win and this file is updated to match.
/// Astryx is the design language reference only. This file is pure SwiftUI.
/// Brand note: the accent values are provisional until May gives her brand
/// preference, due 2 Dec 2026. Change the accent tokens only when she answers.
public enum DesignTokens {

    // MARK: - Color helpers

    private static func dynamicColor(light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(hex: hex)
        })
    }

    // MARK: - Semantic colors

    public enum ColorToken {
        public static let backgroundPrimary = dynamicColor(light: 0xFFFFFF, dark: 0x121214)
        public static let backgroundSecondary = dynamicColor(light: 0xF4F6F8, dark: 0x1C1E21)
        public static let surfaceCard = dynamicColor(light: 0xFFFFFF, dark: 0x1E2023)
        public static let borderSubtle = dynamicColor(light: 0xE3E8EE, dark: 0x2E3136)
        public static let textPrimary = dynamicColor(light: 0x14181D, dark: 0xF5F5F7)
        public static let textSecondary = dynamicColor(light: 0x606770, dark: 0xA8A8AD)
        public static let textTertiary = dynamicColor(light: 0x757C86, dark: 0x9BA0A8)
        public static let accent = dynamicColor(light: 0x0E7A5F, dark: 0x5EC8AC)
        public static let accentText = dynamicColor(light: 0x0A5C48, dark: 0x5EC8AC)
        public static let accentSoft = dynamicColor(light: 0xE2F2E7, dark: 0x16352C)
        public static let library = dynamicColor(light: 0x7A4FD0, dark: 0xB79CFF)
        public static let libraryText = dynamicColor(light: 0x5B32B8, dark: 0xB79CFF)
        public static let challenge = dynamicColor(light: 0xB3540A, dark: 0xF2A35C)
        public static let accomplishment = dynamicColor(light: 0x217A3C, dark: 0x7BC8A4)
        public static let uncategorised = dynamicColor(light: 0x606770, dark: 0xA8A8AD)
        public static let warning = dynamicColor(light: 0x9A6206, dark: 0xF0B95A)
        public static let danger = dynamicColor(light: 0xC0281B, dark: 0xFF7A6E)
        public static let dangerSoft = dynamicColor(light: 0xFBE9E7, dark: 0x3A1D1A)
    }

    // MARK: - Type

    public enum FontToken {
        public static let largeTitle = Font.system(size: 34, weight: .semibold, design: .rounded)
        public static let title1 = Font.system(size: 28, weight: .semibold, design: .rounded)
        public static let title2 = Font.system(size: 22, weight: .semibold)
        public static let title3 = Font.system(size: 20, weight: .semibold)
        public static let headline = Font.system(size: 17, weight: .semibold)
        public static let body = Font.system(size: 17, weight: .regular)
        public static let callout = Font.system(size: 16, weight: .regular)
        public static let subheadline = Font.system(size: 15, weight: .regular)
        public static let footnote = Font.system(size: 13, weight: .regular)
        public static let caption1 = Font.system(size: 12, weight: .medium)
        public static let caption2 = Font.system(size: 11, weight: .regular)
        /// Countdown numerals. Tabular figures keep digits steady as values change.
        public static let countdown = Font.system(size: 28, weight: .semibold, design: .rounded).monospacedDigit()
    }

    // MARK: - Spacing, 8 point grid

    public enum Spacing {
        public static let space1: CGFloat = 4
        public static let space2: CGFloat = 8
        public static let space3: CGFloat = 16
        public static let space4: CGFloat = 24
        public static let space5: CGFloat = 32
        public static let space6: CGFloat = 48
        public static let screenMargin: CGFloat = 16
        public static let screenMarginLargePhone: CGFloat = 20
        public static let cardPadding: CGFloat = 16
    }

    // MARK: - Corner radius

    public enum Radius {
        public static let small: CGFloat = 8
        public static let medium: CGFloat = 12
        public static let large: CGFloat = 16
        public static let sheet: CGFloat = 20
    }

    // MARK: - Motion

    public enum Motion {
        public static let fast: Double = 0.15
        public static let standard: Double = 0.25
        public static let slow: Double = 0.35
    }

    // MARK: - Layout

    public enum Layout {
        public static let buttonHeight: CGFloat = 52
        public static let chipHeight: CGFloat = 32
        public static let rowMinHeight: CGFloat = 64
        public static let checklistRowMinHeight: CGFloat = 52
        public static let minTapTarget: CGFloat = 44
    }
}

private extension UIColor {
    convenience init(hex: UInt32) {
        let red = CGFloat((hex >> 16) & 0xFF) / 255
        let green = CGFloat((hex >> 8) & 0xFF) / 255
        let blue = CGFloat(hex & 0xFF) / 255
        self.init(red: red, green: green, blue: blue, alpha: 1)
    }
}
