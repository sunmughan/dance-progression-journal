import SwiftUI

// MARK: - Shared components
//
// Every component below is built once and reused on every screen, from
// docs/design/02_components.md. No screen invents its own button, card
// or row. States are part of the component: normal, pressed, disabled,
// loading. All colours, type, spacing and radii come from DesignTokens.

// MARK: Buttons

struct PrimaryButton: View {
    let title: String
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    PrimaryButtonLabel(title: title)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
        }
        .background(isDisabled || isLoading ? DesignTokens.Color.backgroundSecondary : DesignTokens.Color.accent)
        .foregroundStyle(isDisabled || isLoading ? DesignTokens.Color.textTertiary : .white)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.medium))
        .disabled(isDisabled || isLoading)
        .accessibilityLabel(title)
    }
}

/// The label half of PrimaryButton, for use inside a NavigationLink
/// where a Button cannot go. Same type, same height, same one line
/// rule, so a link button looks exactly like a real one.
struct PrimaryButtonLabel: View {
    let title: String

    var body: some View {
        Text(title)
            .font(DesignTokens.Font.headline)
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
    }
}

struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            SecondaryButtonLabel(title: title)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
        }
        .background(.clear)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.medium)
                .stroke(DesignTokens.Color.borderSubtle, lineWidth: 1)
        )
        .accessibilityLabel(title)
    }
}

/// The label half of SecondaryButton, for use inside a NavigationLink.
/// Same type, same height, same one line rule.
struct SecondaryButtonLabel: View {
    let title: String

    var body: some View {
        Text(title)
            .font(DesignTokens.Font.headline)
            .foregroundStyle(DesignTokens.Color.accentText)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
    }
}

struct DestructiveButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DesignTokens.Font.headline)
                .foregroundStyle(DesignTokens.Color.danger)
                .frame(minHeight: 44)
        }
        .accessibilityLabel(title)
    }
}

struct AppTextButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DesignTokens.Font.headline)
                .foregroundStyle(DesignTokens.Color.accentText)
        }
        .accessibilityLabel(title)
    }
}

// MARK: Card

/// Cards are for widgets, galleries and settings groups only. Lists of
/// entries, drills, videos and figures are rows, never cards.
struct AppCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(DesignTokens.Space.space3)
            .background(DesignTokens.Color.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.large))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.large)
                    .stroke(DesignTokens.Color.borderSubtle, lineWidth: 1)
            )
    }
}

// MARK: List rows

/// Row layout, left to right: optional thumbnail or icon, title, one
/// metadata line, disclosure chevron at the right. Minimum height 64.
struct AppRow: View {
    let title: String
    let metadata: String
    var isFavourite: Bool = false
    var leadingIcon: String? = nil
    /// Admin manage rows are not tappable, so they hide the chevron
    /// instead of implying navigation that does not exist.
    var showsChevron: Bool = true

    var body: some View {
        HStack(spacing: DesignTokens.Space.space2) {
            if let leadingIcon {
                Image(systemName: leadingIcon)
                    .font(.system(size: DesignTokens.Icon.row))
                    .foregroundStyle(DesignTokens.Color.textSecondary)
                    .frame(width: 28, height: 28)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DesignTokens.Font.headline)
                    .foregroundStyle(DesignTokens.Color.textPrimary)
                    .lineLimit(2)
                Text(metadata)
                    .font(DesignTokens.Font.subheadline)
                    .foregroundStyle(DesignTokens.Color.textSecondary)
                    .lineLimit(1)
            }
            Spacer()
            if isFavourite {
                Image(systemName: "star.fill")
                    .font(.system(size: DesignTokens.Icon.row))
                    .foregroundStyle(DesignTokens.Color.accent)
                    .accessibilityLabel("Favourite")
            }
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DesignTokens.Color.textTertiary)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, DesignTokens.Space.space3)
        .frame(minHeight: 64)
        .contentShape(Rectangle())
    }
}

// MARK: Filter chips

/// Pill shape, height 32. Chips sit in one horizontal scroll row and
/// never wrap to two lines. Extra tappable padding brings the target
/// to 44, per the accessibility spec.
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DesignTokens.Font.subheadline)
                .foregroundStyle(isSelected ? DesignTokens.Color.accentText : DesignTokens.Color.textPrimary)
                .padding(.horizontal, DesignTokens.Space.space2)
                .padding(.vertical, DesignTokens.Space.space1)
                .frame(height: 32)
        }
        .background(isSelected ? DesignTokens.Color.accentSoft : DesignTokens.Color.backgroundSecondary)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(
                    isSelected ? DesignTokens.Color.accent : .clear,
                    lineWidth: 1
                )
        )
        .padding(.vertical, 6)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: Category tags

/// A tag always shows the written word. Colour is never the only signal.
struct CategoryTag: View {
    let category: EntryCategory

    var body: some View {
        Text(category.displayName.uppercased())
            .font(DesignTokens.Font.caption1)
            .tracking(0.5)
            .foregroundStyle(DesignTokens.Color.category(category))
            .padding(.horizontal, DesignTokens.Space.space2)
            .padding(.vertical, DesignTokens.Space.space1)
            .frame(height: 24)
            .background(DesignTokens.Color.categoryTint(category))
            .clipShape(Capsule())
            .accessibilityLabel("Category, \(category.displayName)")
    }
}

// MARK: Search field

struct AppSearchField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: DesignTokens.Space.space2) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(DesignTokens.Color.textSecondary)
                .accessibilityHidden(true)
            TextField(placeholder, text: $text)
                .font(DesignTokens.Font.body)
                .foregroundStyle(DesignTokens.Color.textPrimary)
                .autocorrectionDisabled()
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(DesignTokens.Color.textSecondary)
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, DesignTokens.Space.space3)
        .frame(height: 44)
        .background(DesignTokens.Color.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.medium))
    }
}

// MARK: Empty state

struct EmptyStateView: View {
    let icon: String
    let title: String
    let helper: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        icon: String,
        title: String,
        helper: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.helper = helper
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: DesignTokens.Space.space3) {
            Image(systemName: icon)
                .font(.system(size: DesignTokens.Icon.emptyState))
                .foregroundStyle(DesignTokens.Color.textTertiary)
                .accessibilityHidden(true)
            Text(title)
                .font(DesignTokens.Font.title3)
                .foregroundStyle(DesignTokens.Color.textPrimary)
                .multilineTextAlignment(.center)
            Text(helper)
                .font(DesignTokens.Font.callout)
                .foregroundStyle(DesignTokens.Color.textSecondary)
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                PrimaryButton(title: actionTitle, action: action)
                    .frame(maxWidth: 280)
            }
        }
        .padding(DesignTokens.Space.space6)
        .frame(maxWidth: .infinity)
    }
}

// MARK: Error banner

/// Plain inline banner at the top of the content area. Copy is plain and
/// specific: what failed, and what to do next. No error about the network
/// ever appears for local actions.
struct ErrorBanner: View {
    let message: String
    var retryTitle: String? = nil
    var onRetry: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: DesignTokens.Space.space2) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(DesignTokens.Color.danger)
                .accessibilityHidden(true)
            Text(message)
                .font(DesignTokens.Font.body)
                .foregroundStyle(DesignTokens.Color.danger)
            Spacer()
            if let retryTitle, let onRetry {
                Button(retryTitle, action: onRetry)
                    .font(DesignTokens.Font.headline)
                    .foregroundStyle(DesignTokens.Color.danger)
            }
        }
        .padding(DesignTokens.Space.space3)
        .background(DesignTokens.Color.dangerSoft)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.medium))
    }
}

// MARK: Countdown display

/// Large numerals in SF Pro Rounded with tabular figures. No live seconds
/// ticker. Days, hours and minutes only. VoiceOver reads the whole card
/// as one sentence, never digit by digit.
struct CountdownView: View {
    let competitionName: String
    let targetDate: Date
    var showsName: Bool = true

    private var components: DateComponents {
        Calendar.current.dateComponents(
            [.day, .hour, .minute],
            from: Date(),
            to: targetDate
        )
    }

    private var days: Int { max(components.day ?? 0, 0) }
    private var hours: Int { max(components.hour ?? 0, 0) }
    private var minutes: Int { max(components.minute ?? 0, 0) }

    var body: some View {
        VStack(spacing: DesignTokens.Space.space2) {
            if showsName {
                HStack(spacing: DesignTokens.Space.space3) {
                    Text(competitionName)
                        .font(DesignTokens.Font.title3)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    Spacer()
                }
            }
            HStack(alignment: .top, spacing: DesignTokens.Space.space4) {
                countdownUnit(value: days, unit: "Days")
                countdownUnit(value: hours, unit: "Hours")
                countdownUnit(value: minutes, unit: "Minutes")
                Spacer()
            }
            HStack {
                Text("\(competitionName) starts in \(days) days")
                    .font(DesignTokens.Font.subheadline)
                    .foregroundStyle(DesignTokens.Color.textSecondary)
                Spacer()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(competitionName) starts in \(days) days")
    }

    private func countdownUnit(value: Int, unit: String) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(DesignTokens.Font.countdownNumerals)
                .foregroundStyle(DesignTokens.Color.textPrimary)
            Text(unit.uppercased())
                .font(DesignTokens.Font.caption1)
                .tracking(0.5)
                .foregroundStyle(DesignTokens.Color.textSecondary)
        }
    }
}

// MARK: Checklist row

/// Tick box 28 by 28 visually with a 44 by 44 tappable area. Done items
/// show the title in secondary text with no strikethrough, so done text
/// stays readable.
struct ChecklistRow: View {
    let item: ChecklistItem
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: DesignTokens.Space.space2) {
            Button(action: onToggle) {
                ZStack {
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.small)
                        .fill(item.isDone ? DesignTokens.Color.accent : .clear)
                        .frame(width: 28, height: 28)
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.small)
                        .stroke(DesignTokens.Color.borderSubtle, lineWidth: 1)
                        .frame(width: 28, height: 28)
                    if item.isDone {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .frame(width: 44, height: 44)
            .accessibilityLabel(item.isDone ? "Mark \(item.title) as not done" : "Mark \(item.title) as done")
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(DesignTokens.Font.body)
                    .foregroundStyle(item.isDone ? DesignTokens.Color.textSecondary : DesignTokens.Color.textPrimary)
                Text(ChecklistCategory.displayName(for: item.category))
                    .font(DesignTokens.Font.footnote)
                    .foregroundStyle(DesignTokens.Color.textSecondary)
            }
            Spacer()
            if let dueDate = item.dueDate {
                Text(RelativeDateFormatter.shared.string(for: dueDate))
                    .font(DesignTokens.Font.footnote)
                    .foregroundStyle(DesignTokens.Color.textSecondary)
            }
        }
        .frame(minHeight: 52)
    }
}

// MARK: Confidence selector

/// Five tappable circles numbered 1 to 5, 44 by 44 each. Selected circle
/// is filled in accent with white numerals.
struct ConfidenceSelector: View {
    @Binding var value: Int

    var body: some View {
        HStack(spacing: DesignTokens.Space.space2) {
            ForEach(1...5, id: \.self) { number in
                Button {
                    value = number
                } label: {
                    Text("\(number)")
                        .font(DesignTokens.Font.headline)
                        .foregroundStyle(number == value ? .white : DesignTokens.Color.textPrimary)
                        .frame(width: 44, height: 44)
                        .background(number == value ? DesignTokens.Color.accent : DesignTokens.Color.backgroundSecondary)
                        .clipShape(Circle())
                }
                .accessibilityLabel("Confidence \(number) of 5")
                .accessibilityAddTraits(number == value ? .isSelected : [])
            }
            Spacer()
        }
    }
}

// MARK: - Relative date helper

/// Joins metadata parts with a middle dot, dropping empty parts, so a
/// row with no dance never renders a leading or doubled separator.
func metadataLine(_ parts: String...) -> String {
    parts.filter { !$0.isEmpty }.joined(separator: " · ")
}

/// Returns the URL only when it is a real https link with a host.
/// URL(string:) alone accepts bare words like "foo", which open
/// nowhere, so a mistyped link must never render a dead button.
func usableWebLink(_ string: String) -> URL? {
    guard let url = URL(string: string),
          url.scheme == "https",
          let host = url.host, !host.isEmpty
    else { return nil }
    return url
}

/// Shared relative date formatter for metadata lines and checklist due
/// dates. Shows real calendar dates under the relative label in
/// production use, per the design spec.
struct RelativeDateFormatter {
    @MainActor static let shared = RelativeDateFormatter()

    private let relative: RelativeDateTimeFormatter
    private let calendar: DateFormatter

    init() {
        relative = RelativeDateTimeFormatter()
        relative.unitsStyle = .full
        calendar = DateFormatter()
        calendar.dateStyle = .medium
        calendar.timeStyle = .none
    }

    func string(for date: Date) -> String {
        relative.localizedString(for: date, relativeTo: Date())
    }

    func calendarString(for date: Date) -> String {
        calendar.string(from: date)
    }
}
