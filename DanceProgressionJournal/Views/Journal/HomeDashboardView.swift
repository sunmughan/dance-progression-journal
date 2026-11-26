import SwiftUI
import SwiftData

// MARK: - Home Dashboard
//
// Today at a glance. This is the first screen inside the Journal tab.
// Countdown card, quick actions, recent entries, next drill, recent
// videos. The drill and video create forms are wired from the quick
// actions.

struct HomeDashboardView: View {
    var onShowJournalList: () -> Void
    var onShowEntryForm: () -> Void
    var onShowDrills: () -> Void
    var onShowVideos: () -> Void

    @Query(sort: \JournalEntry.entryDate, order: .reverse) private var entries: [JournalEntry]
    @Query(sort: \Drill.name) private var drills: [Drill]
    @Query(sort: \Video.recordedDate, order: .reverse) private var videos: [Video]
    @Query(sort: \Competition.startDate) private var competitions: [Competition]
    @Query private var profiles: [LocalProfile]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Space.space4) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(greeting)
                        .font(DesignTokens.Font.largeTitle)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    Text(Date(), style: .date)
                        .font(DesignTokens.Font.subheadline)
                        .foregroundStyle(DesignTokens.Color.textSecondary)
                }

                if let competition = nextCompetition {
                    NavigationLink(value: JournalRoute.competitionDetail(competitionId: competition.id)) {
                        AppCard {
                            CountdownView(
                                competitionName: competition.name,
                                targetDate: competition.startDate,
                                isSample: competition.name == "Sample NDCA event"
                            )
                        }
                    }
                    .buttonStyle(.plain)
                    NavigationLink(value: JournalRoute.competitionList) {
                        HStack {
                            Text("See all competitions")
                                .font(DesignTokens.Font.subheadline)
                                .foregroundStyle(DesignTokens.Color.accent)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(DesignTokens.Color.accent)
                        }
                        .frame(height: 44)
                    }
                    .buttonStyle(.plain)
                }

                HStack(spacing: DesignTokens.Space.space2) {
                    SecondaryButton(title: "New Entry", action: onShowEntryForm)
                    NavigationLink(value: LibraryRoute.drillForm(drillId: nil)) {
                        Text("Add Drill")
                            .font(DesignTokens.Font.headline)
                            .foregroundStyle(DesignTokens.Color.accentText)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                    }
                    .background(.clear)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.medium))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.medium)
                            .stroke(DesignTokens.Color.borderSubtle, lineWidth: 1)
                    )
                    .accessibilityLabel("Add Drill")
                    NavigationLink(value: LibraryRoute.videoForm(videoId: nil)) {
                        Text("Add Video")
                            .font(DesignTokens.Font.headline)
                            .foregroundStyle(DesignTokens.Color.accentText)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                    }
                    .background(.clear)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.medium))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.medium)
                            .stroke(DesignTokens.Color.borderSubtle, lineWidth: 1)
                    )
                    .accessibilityLabel("Add Video")
                }

                section(
                    title: "Recent entries",
                    seeAll: onShowJournalList
                ) {
                    if entries.isEmpty {
                        AppCard {
                            VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                                Text("No entries yet. Write your first entry after practice.")
                                    .font(DesignTokens.Font.callout)
                                    .foregroundStyle(DesignTokens.Color.textSecondary)
                                PrimaryButton(title: "New Entry", action: onShowEntryForm)
                            }
                        }
                    } else {
                        ForEach(entries.prefix(3)) { entry in
                            NavigationLink(value: JournalRoute.entryDetail(entryId: entry.id)) {
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

                section(title: "Next drill", seeAll: onShowDrills) {
                    if let drill = drills.first(where: { $0.isFavourite }) ?? drills.first {
                        NavigationLink(value: LibraryRoute.drillDetail(drillId: drill.id)) {
                            AppRow(
                                title: drill.name,
                                metadata: "\(drill.dance?.name ?? ""), \(drill.focusAreaDisplayName), \(drill.targetRepetitions) repetitions",
                                isFavourite: drill.isFavourite
                            )
                        }
                        .buttonStyle(.plain)
                    } else {
                        Text("No drills yet. Save a drill to practise it again.")
                            .font(DesignTokens.Font.callout)
                            .foregroundStyle(DesignTokens.Color.textSecondary)
                    }
                }

                section(title: "Recent videos", seeAll: onShowVideos) {
                    if videos.isEmpty {
                        Text("No videos yet. Upload a practice video to watch it back.")
                            .font(DesignTokens.Font.callout)
                            .foregroundStyle(DesignTokens.Color.textSecondary)
                    } else {
                        ForEach(videos.prefix(2)) { video in
                            NavigationLink(value: LibraryRoute.videoDetail(videoId: video.id)) {
                                AppRow(
                                    title: video.title,
                                    metadata: "\(video.dance?.name ?? "") · \(video.videoType.displayName) · \(video.durationLabel)",
                                    leadingIcon: "play.circle"
                                )
                            }
                            .buttonStyle(.plain)
                            Divider()
                        }
                    }
                }
            }
            .padding(DesignTokens.Space.screenMargin)
        }
        .background(DesignTokens.Color.backgroundPrimary)
        .navigationTitle("Journal")
        .navigationBarTitleDisplayMode(.large)
    }

    private var greeting: String {
        let name = profiles.first?.dancerName ?? ""
        let hour = Calendar.current.component(.hour, from: Date())
        let part: String
        switch hour {
        case 5..<12: part = "Good morning"
        case 12..<17: part = "Good afternoon"
        default: part = "Good evening"
        }
        return name.isEmpty ? part : "\(part), \(name)"
    }

    private var nextCompetition: Competition? {
        let now = Date()
        return competitions.first { $0.startDate >= now }
    }

    private func section<Content: View>(
        title: String,
        seeAll: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
            HStack {
                Text(title)
                    .font(DesignTokens.Font.title3)
                    .foregroundStyle(DesignTokens.Color.textPrimary)
                Spacer()
                AppTextButton(title: "See all", action: seeAll)
            }
            content()
        }
    }
}
