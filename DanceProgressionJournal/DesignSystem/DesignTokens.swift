import SwiftUI

// MARK: - Design tokens
//
// Source of truth: docs/design/01_design_tokens.md. This file is the only
// place in the app that holds a raw hex value. No screen and no component
// uses a raw hex value. If the docs and this file ever disagree, the docs
// win and this file is updated to match.
//
// Brand status, provisional: the accent below is provisional, taken from
// the Week 1 presentation. May Nguyen picks brand colours by 2 Dec 2026.
// When she picks, change the accent token values only. No screen layout
// changes.

enum DesignTokens {

    // MARK: Colour

    enum Color {
        // Light mode hex values, dark mode hex values, in that order.
        private static func adaptive(light: String, dark: String) -> SwiftUI.Color {
            SwiftUI.Color(uiColor: UIColor { traits in
                let hex = traits.userInterfaceStyle == .dark ? dark : light
                return UIColor(hex: hex)
            })
        }

        static var backgroundPrimary: SwiftUI.Color {
            adaptive(light: "#FFFFFF", dark: "#121214")
        }
        static var backgroundSecondary: SwiftUI.Color {
            adaptive(light: "#F4F6F8", dark: "#1C1E21")
        }
        static var surfaceCard: SwiftUI.Color {
            adaptive(light: "#FFFFFF", dark: "#1E2023")
        }
        static var borderSubtle: SwiftUI.Color {
            adaptive(light: "#E3E8EE", dark: "#2E3136")
        }
        static var textPrimary: SwiftUI.Color {
            adaptive(light: "#14181D", dark: "#F5F5F7")
        }
        static var textSecondary: SwiftUI.Color {
            adaptive(light: "#606770", dark: "#A8A8AD")
        }
        // Light mode contrast 4.2 to 1. Large text 17 pt and above and
        // icons only. Never footnote or caption sizes in light mode.
        static var textTertiary: SwiftUI.Color {
            adaptive(light: "#757C86", dark: "#9BA0A8")
        }
        // Provisional brand accent, pending May's choice by 2 Dec 2026.
        static var accent: SwiftUI.Color {
            adaptive(light: "#0E7A5F", dark: "#5EC8AC")
        }
        static var accentText: SwiftUI.Color {
            adaptive(light: "#0A5C48", dark: "#5EC8AC")
        }
        static var accentSoft: SwiftUI.Color {
            adaptive(light: "#E2F2E7", dark: "#16352C")
        }
        static var library: SwiftUI.Color {
            adaptive(light: "#7A4FD0", dark: "#B79CFF")
        }
        static var libraryText: SwiftUI.Color {
            adaptive(light: "#5B32B8", dark: "#B79CFF")
        }
        static var challenge: SwiftUI.Color {
            adaptive(light: "#B3540A", dark: "#F2A35C")
        }
        static var accomplishment: SwiftUI.Color {
            adaptive(light: "#217A3C", dark: "#7BC8A4")
        }
        static var uncategorised: SwiftUI.Color {
            adaptive(light: "#606770", dark: "#A8A8AD")
        }
        static var warning: SwiftUI.Color {
            adaptive(light: "#9A6206", dark: "#F0B95A")
        }
        static var danger: SwiftUI.Color {
            adaptive(light: "#C0281B", dark: "#FF7A6E")
        }
        static var dangerSoft: SwiftUI.Color {
            adaptive(light: "#FBE9E7", dark: "#3A1D1A")
        }

        static func category(_ category: EntryCategory) -> SwiftUI.Color {
            switch category {
            case .challenge: challenge
            case .accomplishment: accomplishment
            case .uncategorised: uncategorised
            }
        }

        static func categoryTint(_ category: EntryCategory) -> SwiftUI.Color {
            switch category {
            case .challenge: challenge.opacity(0.12)
            case .accomplishment: accomplishment.opacity(0.12)
            case .uncategorised: backgroundSecondary
            }
        }
    }

    // MARK: Type
    //
    // System font SF Pro. Display face SF Pro Rounded for large titles
    // and for countdown numerals only. Dynamic Type is supported on every
    // style because these are all relative text styles, never fixed sizes.

    enum Font {
        static var largeTitle: SwiftUI.Font {
            .system(.largeTitle, design: .rounded, weight: .semibold)
        }
        static var title1: SwiftUI.Font {
            .system(.title, design: .rounded, weight: .semibold)
        }
        static var title2: SwiftUI.Font {
            .system(.title2, weight: .semibold)
        }
        static var title3: SwiftUI.Font {
            .system(.title3, weight: .semibold)
        }
        static var headline: SwiftUI.Font {
            .system(.headline, weight: .semibold)
        }
        static var body: SwiftUI.Font { .system(.body) }
        static var callout: SwiftUI.Font { .system(.callout) }
        static var subheadline: SwiftUI.Font { .system(.subheadline) }
        static var footnote: SwiftUI.Font { .system(.footnote) }
        static var caption1: SwiftUI.Font {
            .system(.caption, weight: .medium)
        }
        static var caption2: SwiftUI.Font { .system(.caption2) }
        static var countdownNumerals: SwiftUI.Font {
            .system(.title, design: .rounded, weight: .semibold)
                .monospacedDigit()
        }
        static var practiceTotals: SwiftUI.Font {
            .system(.body, weight: .semibold).monospacedDigit()
        }
    }

    // MARK: Spacing, 8 point grid
    //
    // Base unit 8. A 4 point half step is allowed inside chips and tight
    // rows only. Nothing else uses a value off the grid.

    enum Space {
        static let space1: CGFloat = 4
        static let space2: CGFloat = 8
        static let space3: CGFloat = 16
        static let space4: CGFloat = 24
        static let space5: CGFloat = 32
        static let space6: CGFloat = 48
        static let screenMargin: CGFloat = 16
        static let screenMarginLargePhone: CGFloat = 20
    }

    // MARK: Corner radius

    enum Radius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let sheet: CGFloat = 20
    }

    // MARK: Motion
    //
    // Motion respects the Reduce Motion setting. Views check
    // AccessibilityReduceMotion and skip animation when it is on.

    enum Motion {
        static let durationFast: Duration = .milliseconds(150)
        static let durationStandard: Duration = .milliseconds(250)
        static let durationSlow: Duration = .milliseconds(350)
    }

    // MARK: Icon sizes

    enum Icon {
        static let row: CGFloat = 20
        static let tabBar: CGFloat = 24
        static let emptyState: CGFloat = 28
    }
}

// MARK: - Hex colour helper
//
// Private to this file. The only place a hex string is parsed.

private extension UIColor {
    convenience init(hex: String) {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("#") {
            cleaned.removeFirst()
        }
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let red = CGFloat((value >> 16) & 0xFF) / 255
        let green = CGFloat((value >> 8) & 0xFF) / 255
        let blue = CGFloat(value & 0xFF) / 255
        self.init(red: red, green: green, blue: blue, alpha: 1)
    }
}
