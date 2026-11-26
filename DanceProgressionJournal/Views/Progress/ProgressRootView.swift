import SwiftUI
import SwiftData

// MARK: - Progress tab
//
// Root is Journal Insights by Category, with a top segment that switches
// to Practice History. Counts come from the real store, so the sample
// month December 2026 shows 3 entries, 2 accomplishments, 1 challenge.
// Months with no entries show zero counts and the message from the
// design spec.

enum ProgressSegment: String, CaseIterable {
    case insights
    case practiceHistory

    var title: String {
        switch self {
        case .insights: "Insights"
        case .practiceHistory: "Practice History"
        }
    }
}

struct ProgressRootView: View {
    @State private var segment: ProgressSegment = .insights
    @State private var selectedMonth: Date = ProgressRootView.december2026

    @Query(sort: \JournalEntry.entryDate, order: .reverse) private var entries: [JournalEntry]
    @Query(sort: \FigurePracticeLog.practiceDate, order: .reverse) private var logs: [FigurePracticeLog]
    @Query(sort: \Dance.displayOrder) private var dances: [Dance]
    @Query(sort: \Figure.name) private var figures: [Figure]

    @State private var selectedDance: Dance?
    @State private var historyDance: Dance?
    @State private var historyFigure: Figure?
    @State private var historyDateFilter: HistoryDateFilter = .all

    private enum HistoryDateFilter: String, CaseIterable {
        case all
        case thisMonth
        case last30Days

        var title: String {
            switch self {
            case .all: "All dates"
            case .thisMonth: "This month"
            case .last30Days: "Last 30 days"
            }
        }
    }

    // The sample data set is dated December 2026, so Insights opens on
    // that month. The user can move month to month with the chevrons.
    private static var december2026: Date {
        var components = DateComponents()
        components.year = 2026
        components.month = 12
        components.day = 1
        return Calendar.current.date(from: components) ?? Date()
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Progress", selection: $segment) {
                ForEach(ProgressSegment.allCases, id: \.self) { item in
                    Text(item.title).tag(item)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, DesignTokens.Space.screenMargin)
            .padding(.bottom, DesignTokens.Space.space2)

            switch segment {
            case .insights:
                insightsContent
            case .practiceHistory:
                practiceHistoryContent
            }
        }
        .background(DesignTokens.Color.backgroundPrimary)
        .navigationTitle("Progress")
        .navigationBarTitleDisplayMode(.large)
    }

    private var monthEntries: [JournalEntry] {
        let calendar = Calendar.current
        return entries.filter {
            calendar.isDate($0.entryDate, equalTo: selectedMonth, toGranularity: .month)
        }
    }

    private var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedMonth)
    }

    private func shiftMonth(by months: Int) {
        if let shifted = Calendar.current.date(byAdding: .month, value: months, to: selectedMonth) {
            selectedMonth = shifted
        }
    }

    private var insightsContent: some View {
        let monthFiltered = monthEntries
        let danceFiltered: [JournalEntry]
        if let selectedDance {
            let danceId = selectedDance.id
            danceFiltered = monthFiltered.filter { $0.dance?.id == danceId }
        } else {
            danceFiltered = monthFiltered
        }
        let accomplishments = danceFiltered.filter { $0.category == .accomplishment }.count
        let challenges = danceFiltered.filter { $0.category == .challenge }.count
        return ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Space.space4) {
                HStack {
                    Button {
                        shiftMonth(by: -1)
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(DesignTokens.Color.accent)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Previous month")
                    Spacer()
                    Text(monthName)
                        .font(DesignTokens.Font.title3)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    Spacer()
                    Button {
                        shiftMonth(by: 1)
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(DesignTokens.Color.accent)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Next month")
                }

                HStack(spacing: DesignTokens.Space.space2) {
                    AppCard {
                        VStack(alignment: .leading, spacing: DesignTokens.Space.space1) {
                            Text("Accomplishments")
                                .font(DesignTokens.Font.footnote)
                                .foregroundStyle(DesignTokens.Color.textSecondary)
                            Text("\(accomplishments)")
                                .font(DesignTokens.Font.title1)
                                .foregroundStyle(DesignTokens.Color.accomplishment)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    AppCard {
                        VStack(alignment: .leading, spacing: DesignTokens.Space.space1) {
                            Text("Challenges")
                                .font(DesignTokens.Font.footnote)
                                .foregroundStyle(DesignTokens.Color.textSecondary)
                            Text("\(challenges)")
                                .font(DesignTokens.Font.title1)
                                .foregroundStyle(DesignTokens.Color.challenge)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DesignTokens.Space.space2) {
                        FilterChip(title: "All dances", isSelected: selectedDance == nil) {
                            selectedDance = nil
                        }
                        ForEach(dances) { dance in
                            FilterChip(title: dance.name, isSelected: selectedDance?.id == dance.id) {
                                selectedDance = dance
                            }
                        }
                    }
                }

                if danceFiltered.isEmpty {
                    Text("No entries in this month yet.")
                        .font(DesignTokens.Font.body)
                        .foregroundStyle(DesignTokens.Color.textSecondary)
                } else {
                    Text("Total entries: \(danceFiltered.count)")
                        .font(DesignTokens.Font.subheadline)
                        .foregroundStyle(DesignTokens.Color.textSecondary)
                    ForEach(danceFiltered) { entry in
                        NavigationLink(value: ProgressRoute.entryDetail(entryId: entry.id)) {
                            AppRow(
                                title: entry.title,
                                metadata: "\(entry.dance?.name ?? "") · \(RelativeDateFormatter.shared.string(for: entry.entryDate))"
                            )
                        }
                        .buttonStyle(.plain)
                        Divider()
                    }
                }
            }
            .padding(DesignTokens.Space.screenMargin)
        }
    }

    private var practiceHistoryContent: some View {
        let filteredLogs = logs.filter { log in
            (historyDance == nil || log.dance?.id == historyDance?.id)
                && (historyFigure == nil || log.figure?.id == historyFigure?.id)
                && matchesHistoryDate(log.practiceDate)
        }
        let totalRepetitions = filteredLogs.reduce(0) { $0 + $1.repetitions }
        let totalMinutes = filteredLogs.reduce(0) { $0 + $1.durationMinutes }
        return ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Space.space4) {
                HStack(spacing: DesignTokens.Space.space2) {
                    Picker("Dance", selection: $historyDance) {
                        Text("All dances").tag(Optional<Dance>(nil))
                        ForEach(dances) { dance in
                            Text(dance.name).tag(Optional(dance))
                        }
                    }
                    .pickerStyle(.menu)
                    Picker("Figure", selection: $historyFigure) {
                        Text("All figures").tag(Optional<Figure>(nil))
                        ForEach(figures) { figure in
                            Text(figure.name).tag(Optional(figure))
                        }
                    }
                    .pickerStyle(.menu)
                    Picker("Date", selection: $historyDateFilter) {
                        ForEach(HistoryDateFilter.allCases, id: \.self) { filter in
                            Text(filter.title).tag(filter)
                        }
                    }
                    .pickerStyle(.menu)
                }
                AppCard {
                    VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                        Text("Totals")
                            .font(DesignTokens.Font.title3)
                            .foregroundStyle(DesignTokens.Color.textPrimary)
                        Text("\(filteredLogs.count) sessions, \(totalRepetitions) repetitions, \(totalMinutes) minutes")
                            .font(DesignTokens.Font.body)
                            .foregroundStyle(DesignTokens.Color.textPrimary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                if filteredLogs.isEmpty {
                    Text(logs.isEmpty ? "No practice sessions yet." : "No sessions match this filter.")
                        .font(DesignTokens.Font.body)
                        .foregroundStyle(DesignTokens.Color.textSecondary)
                } else {
                    ForEach(filteredLogs) { log in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(log.figure?.name ?? "Figure")
                                .font(DesignTokens.Font.headline)
                                .foregroundStyle(DesignTokens.Color.textPrimary)
                            Text("\(RelativeDateFormatter.shared.string(for: log.practiceDate)) · \(log.repetitions) repetitions · \(log.durationMinutes) minutes · Confidence \(log.confidenceRating) of 5")
                                .font(DesignTokens.Font.subheadline)
                                .foregroundStyle(DesignTokens.Color.textSecondary)
                        }
                        .padding(.vertical, DesignTokens.Space.space1)
                        Divider()
                    }
                }
            }
            .padding(DesignTokens.Space.screenMargin)
        }
    }

    private func matchesHistoryDate(_ date: Date) -> Bool {
        switch historyDateFilter {
        case .all:
            return true
        case .thisMonth:
            return Calendar.current.isDate(date, equalTo: Date(), toGranularity: .month)
        case .last30Days:
            guard let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) else { return true }
            return date >= cutoff
        }
    }
}
