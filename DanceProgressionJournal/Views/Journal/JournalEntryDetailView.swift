import SwiftUI
import SwiftData

// MARK: - Journal Entry Detail
//
// One full entry with text, category, dance, date, linked video, linked
// drill, linked figure, Instagram link. Edit and Delete in the top bar.
// Share at the bottom for local export.

struct JournalEntryDetailView: View {
    let entryId: UUID

    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.dismiss) private var dismiss

    @Query private var entries: [JournalEntry]
    @Query(sort: \Video.title) private var videos: [Video]
    @Query(sort: \Drill.name) private var drills: [Drill]
    @Query(sort: \Figure.name) private var figures: [Figure]

    @State private var showingDeleteConfirmation = false
    @State private var showingEdit = false

    init(entryId: UUID) {
        self.entryId = entryId
        let lookupId = entryId
        _entries = Query(filter: #Predicate<JournalEntry> { $0.id == lookupId })
    }

    var body: some View {
        Group {
            if let entry = entries.first {
                detailContent(entry)
            } else {
                EmptyStateView(
                    icon: "book.pages",
                    title: "Entry not found",
                    helper: "This entry may have been deleted."
                )
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEdit) {
            if let entry = entries.first {
                NavigationStack {
                    JournalEntryFormView(entryId: entry.id, onSaved: { _ in
                        showingEdit = false
                    })
                }
            }
        }
        .alert(
            "Delete this entry? This cannot be undone.",
            isPresented: $showingDeleteConfirmation
        ) {
            Button("Delete", role: .destructive) {
                if let entry = entries.first {
                    do {
                        try dependencies.journalEntries.delete(entry)
                        dismiss()
                    } catch {
                        // Deletion failed. The entry stays, and the user
                        // stays on the screen to try again.
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func detailContent(_ entry: JournalEntry) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Space.space4) {
                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text(entry.title)
                        .font(DesignTokens.Font.title1)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    HStack(spacing: DesignTokens.Space.space2) {
                        Text(entry.dance?.name ?? "")
                            .font(DesignTokens.Font.subheadline)
                            .foregroundStyle(DesignTokens.Color.textSecondary)
                        Text(RelativeDateFormatter.shared.calendarString(for: entry.entryDate))
                            .font(DesignTokens.Font.subheadline)
                            .foregroundStyle(DesignTokens.Color.textSecondary)
                        CategoryTag(category: entry.category)
                    }
                }

                Text(entry.bodyText)
                    .font(DesignTokens.Font.body)
                    .foregroundStyle(DesignTokens.Color.textPrimary)
                    .lineSpacing(5)

                if !entry.aiTags.isEmpty {
                    VStack(alignment: .leading, spacing: DesignTokens.Space.space1) {
                        Text("Suggested by the app")
                            .font(DesignTokens.Font.footnote)
                            .foregroundStyle(DesignTokens.Color.textSecondary)
                        Text(entry.aiTags.joined(separator: ", "))
                            .font(DesignTokens.Font.subheadline)
                            .foregroundStyle(DesignTokens.Color.textPrimary)
                    }
                }

                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text("Linked items")
                        .font(DesignTokens.Font.title3)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    if entry.linkedVideoIds.isEmpty
                        && entry.linkedDrillIds.isEmpty
                        && entry.linkedFigureIds.isEmpty {
                        Text("None linked")
                            .font(DesignTokens.Font.body)
                            .foregroundStyle(DesignTokens.Color.textSecondary)
                    } else {
                        ForEach(videos.filter { entry.linkedVideoIds.contains($0.id) }) { video in
                            NavigationLink(value: LibraryRoute.videoDetail(videoId: video.id)) {
                                AppRow(
                                    title: video.title,
                                    metadata: metadataLine(video.dance?.name ?? "", video.videoType.displayName, video.durationLabel),
                                    leadingIcon: "play.circle"
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        ForEach(drills.filter { entry.linkedDrillIds.contains($0.id) }) { drill in
                            NavigationLink(value: LibraryRoute.drillDetail(drillId: drill.id)) {
                                AppRow(
                                    title: drill.name,
                                    metadata: metadataLine(drill.dance?.name ?? "", drill.focusAreaDisplayName),
                                    isFavourite: drill.isFavourite
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        ForEach(figures.filter { entry.linkedFigureIds.contains($0.id) }) { figure in
                            NavigationLink(value: LibraryRoute.figureDetail(figureId: figure.id)) {
                                AppRow(
                                    title: figure.name,
                                    metadata: metadataLine(figure.dance?.name ?? "", figure.level.displayName),
                                    leadingIcon: "figure.dance"
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if let instagramLink = entry.instagramLink,
                   let url = usableWebLink(instagramLink) {
                    Link(destination: url) {
                        HStack(spacing: DesignTokens.Space.space2) {
                            Text("View on Instagram")
                                .font(DesignTokens.Font.headline)
                                .foregroundStyle(DesignTokens.Color.accentText)
                            Image(systemName: "arrow.up.right")
                                .foregroundStyle(DesignTokens.Color.accentText)
                        }
                    }
                }

                ShareLink(
                    item: "\(entry.title)\n\n\(entry.bodyText)",
                    subject: Text(entry.title),
                    message: Text(entry.bodyText)
                ) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(DesignTokens.Font.headline)
                        .foregroundStyle(DesignTokens.Color.accentText)
                }
            }
            .padding(DesignTokens.Space.screenMargin)
        }
        .background(DesignTokens.Color.backgroundPrimary)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { showingEdit = true }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Delete") { showingDeleteConfirmation = true }
                    .foregroundStyle(DesignTokens.Color.danger)
            }
        }
    }
}
