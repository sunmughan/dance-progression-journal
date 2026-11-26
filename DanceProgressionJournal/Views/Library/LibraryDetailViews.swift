import AVKit
import SwiftUI
import SwiftData

// MARK: - Video Detail and Player
//
// One video with local playback through AVPlayer, date, dance,
// choreography or drill type, notes and linked items. When the video
// file is missing, the player area says so plainly instead of showing
// a broken player. Edit and Delete are in the top bar.

struct VideoDetailView: View {
    let videoId: UUID

    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.dismiss) private var dismiss

    @Query private var videos: [Video]
    @Query(sort: \JournalEntry.entryDate, order: .reverse) private var entries: [JournalEntry]
    @Query(sort: \Drill.name) private var drills: [Drill]
    @Query(sort: \Figure.name) private var figures: [Figure]

    @State private var player: AVPlayer?
    @State private var showingDeleteConfirmation = false
    @State private var errorMessage: String?

    init(videoId: UUID) {
        self.videoId = videoId
        let lookupId = videoId
        _videos = Query(filter: #Predicate<Video> { $0.id == lookupId })
    }

    var body: some View {
        Group {
            if let video = videos.first {
                detailContent(video)
            } else {
                EmptyStateView(
                    icon: "play.circle",
                    title: "Video not found",
                    helper: "This video may have been deleted."
                )
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func playerArea(_ video: Video) -> some View {
        let url = dependencies.videoFiles.url(forRelativePath: video.relativePath)
        return Group {
            if FileManager.default.fileExists(atPath: url.path) {
                VideoPlayer(player: player)
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.small))
                    .onAppear {
                        if player == nil {
                            player = AVPlayer(url: url)
                        }
                        player?.play()
                    }
                    .onDisappear {
                        player?.pause()
                    }
                    .accessibilityLabel("Video player, \(video.title), duration \(video.durationLabel)")
            } else {
                ZStack {
                    Rectangle()
                        .fill(DesignTokens.Color.backgroundSecondary)
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.small))
                    VStack(spacing: DesignTokens.Space.space2) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 44))
                            .foregroundStyle(DesignTokens.Color.textSecondary)
                        Text("This video could not be played. The file may be missing.")
                            .font(DesignTokens.Font.subheadline)
                            .foregroundStyle(DesignTokens.Color.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(DesignTokens.Space.screenMargin)
                }
                .accessibilityLabel("Video unavailable, \(video.title)")
            }
        }
    }

    private func detailContent(_ video: Video) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Space.space4) {
                playerArea(video)

                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text(video.title)
                        .font(DesignTokens.Font.title3)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    Text(metadataLine(RelativeDateFormatter.shared.calendarString(for: video.recordedDate), video.dance?.name ?? "", video.videoType.displayName, video.durationLabel))
                        .font(DesignTokens.Font.subheadline)
                        .foregroundStyle(DesignTokens.Color.textSecondary)
                    if let choreographyName = video.choreographyName {
                        Text("Choreography: \(choreographyName)")
                            .font(DesignTokens.Font.subheadline)
                            .foregroundStyle(DesignTokens.Color.textSecondary)
                    }
                }

                if !video.notes.isEmpty {
                    Text(video.notes)
                        .font(DesignTokens.Font.body)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                } else {
                    NavigationLink(value: LibraryRoute.videoForm(videoId: video.id)) {
                        Text("Add a note")
                            .font(DesignTokens.Font.body)
                            .foregroundStyle(DesignTokens.Color.textSecondary)
                    }
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text("Linked items")
                        .font(DesignTokens.Font.title3)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    if let entryId = video.linkedJournalEntryId,
                       let entry = entries.first(where: { $0.id == entryId }) {
                        NavigationLink(value: JournalRoute.entryDetail(entryId: entry.id)) {
                            AppRow(title: entry.title, metadata: "Journal entry")
                        }
                        .buttonStyle(.plain)
                    }
                    if let drillId = video.drillId,
                       let drill = drills.first(where: { $0.id == drillId }) {
                        NavigationLink(value: LibraryRoute.drillDetail(drillId: drill.id)) {
                            AppRow(title: drill.name, metadata: "Drill")
                        }
                        .buttonStyle(.plain)
                    }
                    if let figureId = video.linkedFigureId,
                       let figure = figures.first(where: { $0.id == figureId }) {
                        NavigationLink(value: LibraryRoute.figureDetail(figureId: figure.id)) {
                            AppRow(title: figure.name, metadata: "Figure")
                        }
                        .buttonStyle(.plain)
                    }
                    if video.linkedJournalEntryId == nil
                        && video.drillId == nil
                        && video.linkedFigureId == nil {
                        Text("None linked")
                            .font(DesignTokens.Font.body)
                            .foregroundStyle(DesignTokens.Color.textSecondary)
                    }
                }

                if let instagramLink = video.instagramLink,
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

                if let errorMessage {
                    ErrorBanner(message: errorMessage)
                }
            }
            .padding(DesignTokens.Space.screenMargin)
        }
        .background(DesignTokens.Color.backgroundPrimary)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink(value: LibraryRoute.videoForm(videoId: video.id)) {
                    Text("Edit")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Delete", role: .destructive) {
                    showingDeleteConfirmation = true
                }
            }
        }
        .alert(
            "Delete this video? This cannot be undone.",
            isPresented: $showingDeleteConfirmation
        ) {
            Button("Delete", role: .destructive) {
                do {
                    let videoId = video.id
                    let fileName = video.fileName
                    try dependencies.videos.delete(video, fileService: dependencies.videoFiles)
                    Task { await dependencies.storageBackup.deleteRemoteVideo(id: videoId, fileName: fileName) }
                    dismiss()
                } catch {
                    errorMessage = "This video could not be deleted. Check storage and try again."
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

// MARK: - Figure Detail
//
// One NDCA figure with steps, timing, level and practice summary.
// Figures are pending the client NDCA list, due 9 Dec 2026, and the
// screen says so. The favourite star toggles the figure as a
// favourite. Log Practice opens the practice form.

struct FigureDetailView: View {
    let figureId: UUID

    @Environment(AppDependencies.self) private var dependencies

    @Query private var figures: [Figure]
    @Query(sort: \Video.recordedDate, order: .reverse) private var videos: [Video]

    @State private var errorMessage: String?

    init(figureId: UUID) {
        self.figureId = figureId
        let lookupId = figureId
        _figures = Query(filter: #Predicate<Figure> { $0.id == lookupId })
    }

    var body: some View {
        Group {
            if let figure = figures.first {
                detailContent(figure)
            } else {
                EmptyStateView(
                    icon: "figure.dance",
                    title: "Figure not found",
                    helper: "This figure may have been removed."
                )
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func detailContent(_ figure: Figure) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Space.space4) {
                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text(figure.name)
                        .font(DesignTokens.Font.title1)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    Text(metadataLine(figure.dance?.name ?? "", figure.level.displayName))
                        .font(DesignTokens.Font.subheadline)
                        .foregroundStyle(DesignTokens.Color.textSecondary)
                    Text("Pending the client NDCA list")
                        .font(DesignTokens.Font.footnote)
                        .foregroundStyle(DesignTokens.Color.textSecondary)
                }

                if !figure.descriptionText.isEmpty {
                    Text(figure.descriptionText)
                        .font(DesignTokens.Font.body)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                }

                if !figure.steps.isEmpty {
                    VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                        Text("Steps")
                            .font(DesignTokens.Font.title3)
                            .foregroundStyle(DesignTokens.Color.textPrimary)
                        ForEach(Array(figure.steps.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .top, spacing: DesignTokens.Space.space2) {
                                Text("\(index + 1).")
                                    .font(DesignTokens.Font.body)
                                    .foregroundStyle(DesignTokens.Color.textSecondary)
                                Text(step)
                                    .font(DesignTokens.Font.body)
                                    .foregroundStyle(DesignTokens.Color.textPrimary)
                            }
                        }
                    }
                }

                if !figure.timing.isEmpty {
                    VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                        Text("Timing")
                            .font(DesignTokens.Font.title3)
                            .foregroundStyle(DesignTokens.Color.textPrimary)
                        Text(figure.timing)
                            .font(DesignTokens.Font.callout)
                            .foregroundStyle(DesignTokens.Color.textPrimary)
                    }
                }

                AppCard {
                    VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                        Text("Practice summary")
                            .font(DesignTokens.Font.title3)
                            .foregroundStyle(DesignTokens.Color.textPrimary)
                        if figure.practiceLogs.isEmpty {
                            Text("No practice yet. Log your first practice.")
                                .font(DesignTokens.Font.body)
                                .foregroundStyle(DesignTokens.Color.textSecondary)
                        } else {
                            Text("\(figure.practiceLogs.count) sessions, \(figure.totalRepetitions) repetitions, \(figure.totalMinutes) minutes, average confidence \(String(format: "%.0f", figure.averageConfidence)) of 5")
                                .font(DesignTokens.Font.body)
                                .foregroundStyle(DesignTokens.Color.textPrimary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                NavigationLink(value: LibraryRoute.figurePracticeForm(figureId: figure.id)) {
                    PrimaryButtonLabel(title: "Log Practice")
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                }
                .background(DesignTokens.Color.accent)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.medium))
                .accessibilityLabel("Log Practice")

                if let errorMessage {
                    ErrorBanner(message: errorMessage)
                }

                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text("Linked videos")
                        .font(DesignTokens.Font.title3)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    let linked = videos.filter { $0.linkedFigureId == figure.id }
                    if linked.isEmpty {
                        Text("None linked")
                            .font(DesignTokens.Font.body)
                            .foregroundStyle(DesignTokens.Color.textSecondary)
                    } else {
                        ForEach(linked) { video in
                            NavigationLink(value: LibraryRoute.videoDetail(videoId: video.id)) {
                                AppRow(
                                    title: video.title,
                                    metadata: metadataLine(video.dance?.name ?? "", video.durationLabel),
                                    leadingIcon: "play.circle"
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(DesignTokens.Space.screenMargin)
        }
        .background(DesignTokens.Color.backgroundPrimary)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    figure.isFavourite.toggle()
                    do {
                        try dependencies.figures.save()
                    } catch {
                        figure.isFavourite.toggle()
                        errorMessage = "This figure could not be saved. Check storage and try again."
                    }
                } label: {
                    Image(systemName: figure.isFavourite ? "star.fill" : "star")
                        .foregroundStyle(DesignTokens.Color.accent)
                }
                .accessibilityLabel(figure.isFavourite ? "Remove from favourites" : "Add to favourites")
            }
        }
    }
}

// MARK: - Drill Detail
//
// One drill with description, focus area, targets and practice history.
// Mark Practiced logs a session with today date and the drill targets.
// Start Timer is a simple count up timer on this screen, not a
// separate screen. Edit and Delete are in the top bar.

struct DrillDetailView: View {
    let drillId: UUID

    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.dismiss) private var dismiss

    @Query private var drills: [Drill]
    @Query(sort: \Video.recordedDate, order: .reverse) private var videos: [Video]
    @Query(sort: \JournalEntry.entryDate, order: .reverse) private var entries: [JournalEntry]

    @State private var errorMessage: String?
    @State private var justPracticed = false
    @State private var showingDeleteConfirmation = false
    @State private var timerSeconds = 0
    @State private var timerActive = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(drillId: UUID) {
        self.drillId = drillId
        let lookupId = drillId
        _drills = Query(filter: #Predicate<Drill> { $0.id == lookupId })
    }

    var body: some View {
        Group {
            if let drill = drills.first {
                detailContent(drill)
            } else {
                EmptyStateView(
                    icon: "timer",
                    title: "Drill not found",
                    helper: "This drill may have been deleted."
                )
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(timer) { _ in
            if timerActive {
                timerSeconds += 1
            }
        }
    }

    private var timerLabel: String {
        String(format: "%d:%02d", timerSeconds / 60, timerSeconds % 60)
    }

    private func sessionSummary(_ session: DrillPracticeSession) -> String {
        var parts: [String] = []
        if session.repetitions > 0 {
            parts.append("\(session.repetitions) repetitions")
        }
        if session.durationMinutes > 0 {
            parts.append("\(session.durationMinutes) minutes")
        }
        return parts.joined(separator: " · ")
    }

    private func detailContent(_ drill: Drill) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Space.space4) {
                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text(drill.name)
                        .font(DesignTokens.Font.title1)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    Text(metadataLine(drill.dance?.name ?? "", drill.focusAreaDisplayName, drill.difficulty.displayName))
                        .font(DesignTokens.Font.subheadline)
                        .foregroundStyle(DesignTokens.Color.textSecondary)
                    if drill.isFavourite {
                        Label("Favourite", systemImage: "star.fill")
                            .font(DesignTokens.Font.subheadline)
                            .foregroundStyle(DesignTokens.Color.accent)
                    }
                }

                if !drill.descriptionText.isEmpty {
                    Text(drill.descriptionText)
                        .font(DesignTokens.Font.body)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                }

                HStack(spacing: DesignTokens.Space.space2) {
                    AppCard {
                        VStack(alignment: .leading, spacing: DesignTokens.Space.space1) {
                            Text("Target repetitions")
                                .font(DesignTokens.Font.footnote)
                                .foregroundStyle(DesignTokens.Color.textSecondary)
                            Text("\(drill.targetRepetitions)")
                                .font(DesignTokens.Font.practiceTotals)
                                .foregroundStyle(DesignTokens.Color.textPrimary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    AppCard {
                        VStack(alignment: .leading, spacing: DesignTokens.Space.space1) {
                            Text("Target minutes")
                                .font(DesignTokens.Font.footnote)
                                .foregroundStyle(DesignTokens.Color.textSecondary)
                            Text("\(drill.targetDurationMinutes)")
                                .font(DesignTokens.Font.practiceTotals)
                                .foregroundStyle(DesignTokens.Color.textPrimary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                HStack(spacing: DesignTokens.Space.space2) {
                    PrimaryButton(title: "Mark Practiced") {
                        do {
                            try dependencies.drills.markPracticed(drill, on: Date())
                            justPracticed = true
                        } catch {
                            errorMessage = "This practice could not be saved. Check storage and try again."
                        }
                    }
                    SecondaryButton(title: timerActive ? "Stop Timer" : "Start Timer") {
                        timerActive.toggle()
                    }
                }
                if justPracticed {
                    Text("Logged for today.")
                        .font(DesignTokens.Font.subheadline)
                        .foregroundStyle(DesignTokens.Color.accentText)
                }
                if timerSeconds > 0 || timerActive {
                    HStack(spacing: DesignTokens.Space.space2) {
                        Text(timerLabel)
                            .font(DesignTokens.Font.practiceTotals)
                            .foregroundStyle(DesignTokens.Color.textPrimary)
                            .monospacedDigit()
                        Spacer()
                        AppTextButton(title: "Reset") {
                            timerActive = false
                            timerSeconds = 0
                        }
                    }
                }
                if let errorMessage {
                    ErrorBanner(message: errorMessage)
                }

                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text("Practice history")
                        .font(DesignTokens.Font.title3)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    let sessions = drill.sessions.sorted { $0.practicedDate > $1.practicedDate }
                    if sessions.isEmpty {
                        Text("No practice logged yet. Tap Mark Practiced after your first set.")
                            .font(DesignTokens.Font.body)
                            .foregroundStyle(DesignTokens.Color.textSecondary)
                    } else {
                        ForEach(sessions) { session in
                            HStack(spacing: DesignTokens.Space.space2) {
                                Text(RelativeDateFormatter.shared.string(for: session.practicedDate))
                                    .font(DesignTokens.Font.body)
                                    .foregroundStyle(DesignTokens.Color.textPrimary)
                                Spacer()
                                Text(sessionSummary(session))
                                    .font(DesignTokens.Font.body)
                                    .foregroundStyle(DesignTokens.Color.textSecondary)
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text("Linked videos")
                        .font(DesignTokens.Font.title3)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    let linked = videos.filter { $0.drillId == drill.id }
                    if linked.isEmpty {
                        Text("None linked")
                            .font(DesignTokens.Font.body)
                            .foregroundStyle(DesignTokens.Color.textSecondary)
                    } else {
                        ForEach(linked) { video in
                            NavigationLink(value: LibraryRoute.videoDetail(videoId: video.id)) {
                                AppRow(
                                    title: video.title,
                                    metadata: metadataLine(video.dance?.name ?? "", video.durationLabel),
                                    leadingIcon: "play.circle"
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text("Linked entries")
                        .font(DesignTokens.Font.title3)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    let linked = entries.filter { $0.linkedDrillIds.contains(drill.id) }
                    if linked.isEmpty {
                        Text("None linked")
                            .font(DesignTokens.Font.body)
                            .foregroundStyle(DesignTokens.Color.textSecondary)
                    } else {
                        ForEach(linked) { entry in
                            NavigationLink(value: JournalRoute.entryDetail(entryId: entry.id)) {
                                AppRow(title: entry.title, metadata: entry.category.displayName)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(DesignTokens.Space.screenMargin)
        }
        .background(DesignTokens.Color.backgroundPrimary)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink(value: LibraryRoute.drillForm(drillId: drill.id)) {
                    Text("Edit")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Delete", role: .destructive) {
                    showingDeleteConfirmation = true
                }
            }
        }
        .alert(
            "Delete this drill? This cannot be undone.",
            isPresented: $showingDeleteConfirmation
        ) {
            Button("Delete", role: .destructive) {
                do {
                    try dependencies.drills.delete(drill)
                    dismiss()
                } catch {
                    errorMessage = "This drill could not be deleted. Check storage and try again."
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}
