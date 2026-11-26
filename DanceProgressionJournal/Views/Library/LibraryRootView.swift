import SwiftUI
import SwiftData

// MARK: - Library tab
//
// Root is Video Library, with a top segment that switches the list to
// Figure Library Browse or Drill List. Video upload and recording arrive
// in Week 3, drill create and edit arrive in Week 2. This Week 1 build
// shows the seeded lists read only, with the figure rows labelled
// pending the client NDCA list.

enum LibrarySegment: String, CaseIterable {
    case videos
    case figures
    case drills

    var title: String {
        switch self {
        case .videos: "Videos"
        case .figures: "Figures"
        case .drills: "Drills"
        }
    }
}

struct LibraryRootView: View {
    @Binding var segment: LibrarySegment

    @Query(sort: \Video.recordedDate, order: .reverse) private var videos: [Video]
    @Query(sort: \Figure.name) private var figures: [Figure]
    @Query(sort: \Drill.name) private var drills: [Drill]

    @State private var searchText = ""
    @State private var selectedDance: Dance?
    @State private var showingDanceFilter = false
    @Query(sort: \Dance.displayOrder) private var dances: [Dance]

    var body: some View {
        VStack(spacing: 0) {
            Picker("Library", selection: $segment) {
                ForEach(LibrarySegment.allCases, id: \.self) { item in
                    Text(item.title).tag(item)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, DesignTokens.Space.screenMargin)
            .padding(.bottom, DesignTokens.Space.space2)

            AppSearchField(
                placeholder: searchPlaceholder,
                text: $searchText
            )
            .padding(.horizontal, DesignTokens.Space.screenMargin)
            .padding(.bottom, DesignTokens.Space.space2)

            switch segment {
            case .videos:
                videoList
            case .figures:
                figureList
            case .drills:
                drillList
            }
        }
        .background(DesignTokens.Color.backgroundPrimary)
        .navigationTitle("Library")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingDanceFilter) {
            danceFilterSheet
        }
    }

    private var searchPlaceholder: String {
        switch segment {
        case .videos: "Search videos"
        case .figures: "Search figures"
        case .drills: "Search drills"
        }
    }

    private var danceFilterChip: some View {
        FilterChip(
            title: selectedDance?.name ?? "All dances",
            isSelected: selectedDance != nil
        ) {
            showingDanceFilter = true
        }
    }

    private var danceFilterSheet: some View {
        NavigationStack {
            List {
                Button("All dances") {
                    selectedDance = nil
                    showingDanceFilter = false
                }
                ForEach(dances) { dance in
                    Button {
                        selectedDance = dance
                        showingDanceFilter = false
                    } label: {
                        HStack {
                            Text(dance.name)
                                .foregroundStyle(DesignTokens.Color.textPrimary)
                            Spacer()
                            if selectedDance?.id == dance.id {
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
                    Button("Cancel") { showingDanceFilter = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func matchesSearch(_ text: String) -> Bool {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        return query.isEmpty || text.lowercased().contains(query)
    }

    private func matchesDance(_ dance: Dance?) -> Bool {
        guard let selectedDance else { return true }
        return dance?.id == selectedDance.id
    }

    private var videoList: some View {
        let filtered = videos.filter { matchesSearch($0.title) && matchesDance($0.dance) }
        return Group {
            if videos.isEmpty {
                EmptyStateView(
                    icon: "play.circle",
                    title: "No videos yet",
                    helper: "Upload a practice video to watch it back."
                )
            } else if filtered.isEmpty {
                EmptyStateView(
                    icon: "magnifyingglass",
                    title: "No videos match this filter.",
                    helper: "Try a different search or filter."
                )
            } else {
                List {
                    HStack {
                        danceFilterChip
                        Spacer()
                    }
                    .listRowSeparator(.hidden)
                    ForEach(filtered) { video in
                        NavigationLink(value: LibraryRoute.videoDetail(videoId: video.id)) {
                            AppRow(
                                title: video.title,
                                metadata: "\(video.dance?.name ?? "") · \(video.videoType.displayName) · \(video.durationLabel)",
                                leadingIcon: "play.circle"
                            )
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    private var figureList: some View {
        let filtered = figures.filter { matchesSearch($0.name) && matchesDance($0.dance) }
        return Group {
            if filtered.isEmpty {
                EmptyStateView(
                    icon: "figure.dance",
                    title: "No figures match this filter.",
                    helper: "Try a different search or filter."
                )
            } else {
                List {
                    HStack {
                        danceFilterChip
                        Spacer()
                    }
                    .listRowSeparator(.hidden)
                    Text("Pending the client NDCA list")
                        .font(DesignTokens.Font.footnote)
                        .foregroundStyle(DesignTokens.Color.textSecondary)
                        .listRowSeparator(.hidden)
                    ForEach(filtered) { figure in
                        NavigationLink(value: LibraryRoute.figureDetail(figureId: figure.id)) {
                            AppRow(
                                title: figure.name,
                                metadata: "\(figure.dance?.name ?? "") · \(figure.level.displayName) · \(figure.practiceLogs.count) sessions",
                                leadingIcon: "figure.dance"
                            )
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    private var drillList: some View {
        let filtered = drills.filter { matchesSearch($0.name) && matchesDance($0.dance) }
        let favourites = filtered.filter { $0.isFavourite }
        let others = filtered.filter { !$0.isFavourite }
        return Group {
            if drills.isEmpty {
                EmptyStateView(
                    icon: "timer",
                    title: "No drills yet",
                    helper: "Save a drill to practise it again."
                )
            } else if filtered.isEmpty {
                EmptyStateView(
                    icon: "magnifyingglass",
                    title: "No drills match this filter.",
                    helper: "Try a different search or filter."
                )
            } else {
                List {
                    HStack {
                        danceFilterChip
                        Spacer()
                    }
                    .listRowSeparator(.hidden)
                    if !favourites.isEmpty {
                        Section("Favourites") {
                            ForEach(favourites) { drill in
                                drillRow(drill)
                            }
                        }
                    }
                    Section("By dance") {
                        ForEach(others) { drill in
                            drillRow(drill)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    private func drillRow(_ drill: Drill) -> some View {
        NavigationLink(value: LibraryRoute.drillDetail(drillId: drill.id)) {
            AppRow(
                title: drill.name,
                metadata: "\(drill.dance?.name ?? ""), \(drill.focusArea.displayName), \(drill.targetRepetitions) repetitions",
                isFavourite: drill.isFavourite
            )
        }
    }
}
