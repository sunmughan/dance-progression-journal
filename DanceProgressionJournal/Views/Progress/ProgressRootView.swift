import SwiftUI
import SwiftData

// MARK: - Progress tab
//
// Root is Journal Insights by Category, with a top segment that switches
// to Practice History. Counts come from the real store. Insights opens
// on the current month, or on the newest month that holds entries when
// the current month is empty. Months with no entries show zero counts
// and the message from the design spec.

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
    var onBrowseFigures: () -> Void = {}

    @State private var segment: ProgressSegment = .insights
    @State private var selectedMonth: Date = ProgressRootView.currentMonth
    @State private var didAdjustMonth = false

    @Query(sort: \JournalEntry.entryDate, order: .reverse) private var entries: [JournalEntry]
    @Query(sort: \FigurePracticeLog.practiceDate, order: .reverse) private var logs: [FigurePracticeLog]
    @Query(sort: \Dance.displayOrder) private var dances: [Dance]
    @Query(sort: \Figure.name) private var figures: [Figure]

    @State private var selectedDance: Dance?
    @State private var historyDance: Dance?
    @State private var historyFigure: Figure?
    @State private var historyDateFilter: HistoryDateFilter = .all
    @State private var showingHistoryDateFilter = false
    @State private var showingHistoryDanceFilter = false
    @State private var showingHistoryFigureFilter = false

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

    /// First day of the current month. Insights opens here.
    private static var currentMonth: Date {
        let calendar = Calendar.current
        return calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) ?? Date()
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
        .onAppear {
            adjustMonthToLatestEntries()
        }
    }

    /// First open only: when the store holds entries but none in the
    /// current month, open on the newest month that has entries instead
    /// of an empty current month. A deliberate month the user picked
    /// with the chevrons is never moved.
    private func adjustMonthToLatestEntries() {
        guard !didAdjustMonth else { return }
        didAdjustMonth = true
        guard !entries.isEmpty, monthEntries.isEmpty,
              let newest = entries.first?.entryDate else { return }
        let calendar = Calendar.current
        selectedMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: newest)) ?? newest
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
                        VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
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

                if monthFiltered.isEmpty {
                    Text("No entries in this month yet.")
                        .font(DesignTokens.Font.body)
                        .foregroundStyle(DesignTokens.Color.textSecondary)
                } else {
                    trendChart
                    Text("Total entries: \(danceFiltered.count)")
                        .font(DesignTokens.Font.subheadline)
                        .foregroundStyle(DesignTokens.Color.textSecondary)
                    ForEach(danceFiltered) { entry in
                        NavigationLink(value: ProgressRoute.entryDetail(entryId: entry.id)) {
                            AppRow(
                                title: entry.title,
                                metadata: metadataLine(entry.dance?.name ?? "", RelativeDateFormatter.shared.string(for: entry.entryDate))
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

    /// Bars per month for the six months ending at the selected
    /// month: one accomplishment bar and one challenge bar per
    /// month, with a short month label under each pair.
    private var trendChart: some View {
        let calendar = Calendar.current
        let months = (0..<6).compactMap { offset in
            calendar.date(byAdding: .month, value: -offset, to: selectedMonth)
        }.sorted()
        let counts = months.map { month in
            let inMonth = entries.filter {
                calendar.isDate($0.entryDate, equalTo: month, toGranularity: .month)
            }
            return (
                month: month,
                accomplishments: inMonth.filter { $0.category == .accomplishment }.count,
                challenges: inMonth.filter { $0.category == .challenge }.count
            )
        }
        let maxCount = counts.map { max($0.accomplishments, $0.challenges) }.max() ?? 0
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return AppCard {
            VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                Text("Trend")
                    .font(DesignTokens.Font.title3)
                    .foregroundStyle(DesignTokens.Color.textPrimary)
                HStack(alignment: .bottom, spacing: DesignTokens.Space.space3) {
                    ForEach(counts, id: \.month) { item in
                        VStack(spacing: DesignTokens.Space.space1) {
                            HStack(alignment: .bottom, spacing: 2) {
                                chartBar(value: item.accomplishments, max: maxCount, color: DesignTokens.Color.accomplishment)
                                chartBar(value: item.challenges, max: maxCount, color: DesignTokens.Color.challenge)
                            }
                            .frame(height: 88)
                            Text(formatter.string(from: item.month))
                                .font(DesignTokens.Font.caption1)
                                .foregroundStyle(DesignTokens.Color.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                HStack(spacing: DesignTokens.Space.space3) {
                    legendDot(color: DesignTokens.Color.accomplishment, label: "Accomplishments")
                    legendDot(color: DesignTokens.Color.challenge, label: "Challenges")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func chartBar(value: Int, max: Int, color: Color) -> some View {
        // Bar area is 88 tall; the count label above takes about 16,
        // so bars scale to 70 at most and never vanish entirely.
        let height: CGFloat
        if max == 0 || value == 0 {
            height = 2
        } else {
            height = Swift.max(CGFloat(value) / CGFloat(max) * 70, 4)
        }
        return VStack(spacing: 2) {
            if value > 0 {
                Text("\(value)")
                    .font(DesignTokens.Font.caption2)
                    .foregroundStyle(DesignTokens.Color.textSecondary)
            }
            RoundedRectangle(cornerRadius: 2)
                .fill(value == 0 ? DesignTokens.Color.borderSubtle : color)
                .frame(width: 12, height: height)
        }
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: DesignTokens.Space.space1) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(DesignTokens.Font.caption1)
                .foregroundStyle(DesignTokens.Color.textSecondary)
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
        let grouped = Dictionary(grouping: filteredLogs) { log in
            Calendar.current.startOfDay(for: log.practiceDate)
        }
        let days = grouped.keys.sorted(by: >)
        return ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Space.space4) {
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

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DesignTokens.Space.space2) {
                        FilterChip(title: historyDateFilter.title, isSelected: historyDateFilter != .all) {
                            showingHistoryDateFilter = true
                        }
                        FilterChip(title: historyDance?.name ?? "All dances", isSelected: historyDance != nil) {
                            showingHistoryDanceFilter = true
                        }
                        FilterChip(title: historyFigure?.name ?? "All figures", isSelected: historyFigure != nil) {
                            showingHistoryFigureFilter = true
                        }
                    }
                }

                if logs.isEmpty {
                    EmptyStateView(
                        icon: "figure.dance",
                        title: "No practice logged yet",
                        helper: "Log practice from a figure to see it here.",
                        actionTitle: "Browse figures",
                        action: onBrowseFigures
                    )
                } else if filteredLogs.isEmpty {
                    VStack(spacing: DesignTokens.Space.space3) {
                        EmptyStateView(
                            icon: "magnifyingglass",
                            title: "No sessions match this filter.",
                            helper: "Try a different filter."
                        )
                        AppTextButton(title: "Clear filters") {
                            historyDance = nil
                            historyFigure = nil
                            historyDateFilter = .all
                        }
                    }
                } else {
                    ForEach(days, id: \.self) { day in
                        VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                            Text(RelativeDateFormatter.shared.calendarString(for: day))
                                .font(DesignTokens.Font.headline)
                                .foregroundStyle(DesignTokens.Color.textPrimary)
                            ForEach(grouped[day] ?? []) { log in
                                historyRow(log)
                                Divider()
                            }
                        }
                    }
                }
            }
            .padding(DesignTokens.Space.screenMargin)
        }
        .sheet(isPresented: $showingHistoryDateFilter) {
            filterSheet(
                title: "Date",
                options: HistoryDateFilter.allCases.map { ($0.title, historyDateFilter == $0) },
                onPick: { index in
                    historyDateFilter = HistoryDateFilter.allCases[index]
                    showingHistoryDateFilter = false
                },
                onCancel: { showingHistoryDateFilter = false }
            )
        }
        .sheet(isPresented: $showingHistoryDanceFilter) {
            NavigationStack {
                List {
                    Button("All dances") {
                        historyDance = nil
                        showingHistoryDanceFilter = false
                    }
                    ForEach(dances) { dance in
                        Button {
                            historyDance = dance
                            showingHistoryDanceFilter = false
                        } label: {
                            HStack {
                                Text(dance.name)
                                    .foregroundStyle(DesignTokens.Color.textPrimary)
                                Spacer()
                                if historyDance?.id == dance.id {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(DesignTokens.Color.accent)
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Dance")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showingHistoryDanceFilter = false }
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showingHistoryFigureFilter) {
            NavigationStack {
                List {
                    Button("All figures") {
                        historyFigure = nil
                        showingHistoryFigureFilter = false
                    }
                    ForEach(figures) { figure in
                        Button {
                            historyFigure = figure
                            showingHistoryFigureFilter = false
                        } label: {
                            HStack {
                                Text(figure.name)
                                    .foregroundStyle(DesignTokens.Color.textPrimary)
                                Spacer()
                                if historyFigure?.id == figure.id {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(DesignTokens.Color.accent)
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Figure")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showingHistoryFigureFilter = false }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    private func filterSheet(
        title: String,
        options: [(String, Bool)],
        onPick: @escaping (Int) -> Void,
        onCancel: @escaping () -> Void
    ) -> some View {
        NavigationStack {
            List {
                ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                    Button {
                        onPick(index)
                    } label: {
                        HStack {
                            Text(option.0)
                                .foregroundStyle(DesignTokens.Color.textPrimary)
                            Spacer()
                            if option.1 {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(DesignTokens.Color.accent)
                            }
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel() }
                }
            }
        }
        .presentationDetents([.medium])
    }

    @ViewBuilder
    private func historyRow(_ log: FigurePracticeLog) -> some View {
        let title = log.figure?.name ?? log.dance.map { "\($0.name) practice" } ?? "Practice session"
        let subtitle = "\(RelativeDateFormatter.shared.string(for: log.practiceDate)) · \(log.repetitions) repetitions · \(log.durationMinutes) minutes · Confidence \(log.confidenceRating) of 5"
        if let figure = log.figure {
            NavigationLink(value: ProgressRoute.figureDetail(figureId: figure.id)) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(DesignTokens.Font.headline)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    Text(subtitle)
                        .font(DesignTokens.Font.subheadline)
                        .foregroundStyle(DesignTokens.Color.textSecondary)
                }
                .padding(.vertical, DesignTokens.Space.space1)
            }
            .buttonStyle(.plain)
        } else {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DesignTokens.Font.headline)
                    .foregroundStyle(DesignTokens.Color.textPrimary)
                Text(subtitle)
                    .font(DesignTokens.Font.subheadline)
                    .foregroundStyle(DesignTokens.Color.textSecondary)
            }
            .padding(.vertical, DesignTokens.Space.space1)
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
