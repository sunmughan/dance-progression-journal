import SwiftUI
import SwiftData

// MARK: - Library tab
//
// Root is Video Library, with a top segment that switches the list to
// Figure Library Browse or Drill List. The Add Video button opens the
// upload form, and the Add Drill button opens the drill form. Each row
// opens its detail with Edit and Delete.

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

enum VideoLayout: String, CaseIterable {
    case grid
    case list

    var title: String {
        switch self {
        case .grid: "Grid"
        case .list: "List"
        }
    }

    var icon: String {
        switch self {
        case .grid: "square.grid.2x2"
        case .list: "list.bullet"
        }
    }
}

/// Thumbnail tile for one video. Shows the stored thumbnail when the
/// file exists, otherwise the placeholder tile, never an error.
struct VideoThumbnailView: View {
    let video: Video

    @Environment(AppDependencies.self) private var dependencies

    var body: some View {
        Group {
            if let thumbnailPath = video.thumbnailRelativePath,
               let image = UIImage(contentsOfFile: dependencies.videoFiles.url(forRelativePath: thumbnailPath).path) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(16 / 9, contentMode: .fill)
            } else {
                ZStack {
                    Rectangle().fill(DesignTokens.Color.backgroundSecondary)
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(DesignTokens.Color.textSecondary)
                }
                .aspectRatio(16 / 9, contentMode: .fill)
            }
        }
    }
}

struct LibraryRootView: View {
    @Binding var segment: LibrarySegment
    var onNavigate: (LibraryRoute) -> Void = { _ in }

    @Query(sort: \Video.recordedDate, order: .reverse) private var videos: [Video]
    @Query(sort: \Figure.name) private var figures: [Figure]
    @Query(sort: \Drill.name) private var drills: [Drill]

    @State private var searchText = ""
    @State private var selectedDance: Dance?
    @State private var showingDanceFilter = false
    @State private var selectedFocusArea: String?
    @State private var showingFocusAreaFilter = false
    @State private var favouritesOnly = false
    @State private var selectedVideoType: VideoType?
    @State private var showingVideoTypeFilter = false
    @State private var selectedLevel: FigureLevel?
    @State private var showingLevelFilter = false
    @State private var videoLayout: VideoLayout = .grid
    @Query(sort: \Dance.displayOrder) private var dances: [Dance]
    @Query(sort: \ManagedListItem.sortOrder) private var managedItems: [ManagedListItem]

    private var focusAreas: [String] {
        managedItems.filter { $0.kind == .focusArea && $0.isActive }.map { $0.name }
    }

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
        .sheet(isPresented: $showingFocusAreaFilter) {
            focusAreaFilterSheet
        }
        .sheet(isPresented: $showingVideoTypeFilter) {
            videoTypeFilterSheet
        }
        .safeAreaInset(edge: .bottom) {
            if segment == .drills {
                NavigationLink(value: LibraryRoute.drillForm(drillId: nil)) {
                    PrimaryButtonLabel(title: "Add Drill")
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                }
                .background(DesignTokens.Color.accent)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.medium))
                .padding(.horizontal, DesignTokens.Space.screenMargin)
                .padding(.vertical, DesignTokens.Space.space2)
                .background(DesignTokens.Color.backgroundPrimary)
                .accessibilityLabel("Add Drill")
            }
            if segment == .videos {
                NavigationLink(value: LibraryRoute.videoForm(videoId: nil)) {
                    PrimaryButtonLabel(title: "Add Video")
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                }
                .background(DesignTokens.Color.accent)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.medium))
                .padding(.horizontal, DesignTokens.Space.screenMargin)
                .padding(.vertical, DesignTokens.Space.space2)
                .background(DesignTokens.Color.backgroundPrimary)
                .accessibilityLabel("Add Video")
            }
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

    private var focusAreaFilterChip: some View {
        FilterChip(
            title: selectedFocusArea.map { FocusArea.displayName(for: $0) } ?? "All focus areas",
            isSelected: selectedFocusArea != nil
        ) {
            showingFocusAreaFilter = true
        }
    }

    private var favouritesFilterChip: some View {
        FilterChip(
            title: "Favourites",
            isSelected: favouritesOnly
        ) {
            favouritesOnly.toggle()
        }
    }

    private var videoTypeFilterChip: some View {
        FilterChip(
            title: selectedVideoType?.displayName ?? "All types",
            isSelected: selectedVideoType != nil
        ) {
            showingVideoTypeFilter = true
        }
    }

    private var videoTypeFilterSheet: some View {
        NavigationStack {
            List {
                Button("All types") {
                    selectedVideoType = nil
                    showingVideoTypeFilter = false
                }
                ForEach(VideoType.allCases, id: \.self) { type in
                    Button {
                        selectedVideoType = type
                        showingVideoTypeFilter = false
                    } label: {
                        HStack {
                            Text(type.displayName)
                                .foregroundStyle(DesignTokens.Color.textPrimary)
                            Spacer()
                            if selectedVideoType == type {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(DesignTokens.Color.accent)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Type")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingVideoTypeFilter = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func matchesVideoType(_ type: VideoType) -> Bool {
        guard let selectedVideoType else { return true }
        return type == selectedVideoType
    }

    private var focusAreaFilterSheet: some View {
        NavigationStack {
            List {
                Button("All focus areas") {
                    selectedFocusArea = nil
                    showingFocusAreaFilter = false
                }
                ForEach(focusAreas, id: \.self) { area in
                    Button {
                        selectedFocusArea = area
                        showingFocusAreaFilter = false
                    } label: {
                        HStack {
                            Text(FocusArea.displayName(for: area))
                                .foregroundStyle(DesignTokens.Color.textPrimary)
                            Spacer()
                            if selectedFocusArea == area {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(DesignTokens.Color.accent)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Focus area")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingFocusAreaFilter = false }
                }
            }
        }
        .presentationDetents([.medium])
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
        let filtered = videos.filter {
            matchesSearch($0.title) && matchesDance($0.dance) && matchesVideoType($0.videoType)
        }
        return Group {
            if videos.isEmpty {
                EmptyStateView(
                    icon: "play.circle",
                    title: "No videos yet",
                    helper: "Upload a practice video to watch it back.",
                    actionTitle: "Add Video",
                    action: { onNavigate(.videoForm(videoId: nil)) }
                )
            } else if filtered.isEmpty {
                EmptyStateView(
                    icon: "magnifyingglass",
                    title: "No videos match this filter.",
                    helper: "Try a different search or filter."
                )
            } else {
                VStack(spacing: 0) {
                    HStack {
                        danceFilterChip
                        videoTypeFilterChip
                        Spacer()
                        Picker("Layout", selection: $videoLayout) {
                            ForEach(VideoLayout.allCases, id: \.self) { layout in
                                Image(systemName: layout.icon).tag(layout)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 110)
                    }
                    .padding(.horizontal, DesignTokens.Space.screenMargin)
                    .padding(.bottom, DesignTokens.Space.space2)
                    if videoLayout == .grid {
                        ScrollView {
                            LazyVGrid(
                                columns: [GridItem(.flexible()), GridItem(.flexible())],
                                spacing: DesignTokens.Space.space3
                            ) {
                                ForEach(filtered) { video in
                                    NavigationLink(value: LibraryRoute.videoDetail(videoId: video.id)) {
                                        VStack(alignment: .leading, spacing: DesignTokens.Space.space1) {
                                            VideoThumbnailView(video: video)
                                                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.small))
                                            Text(video.title)
                                                .font(DesignTokens.Font.subheadline)
                                                .foregroundStyle(DesignTokens.Color.textPrimary)
                                                .lineLimit(2)
                                            Text(video.durationLabel)
                                                .font(DesignTokens.Font.footnote)
                                                .foregroundStyle(DesignTokens.Color.textSecondary)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, DesignTokens.Space.screenMargin)
                        }
                    } else {
                        List {
                            ForEach(filtered) { video in
                                NavigationLink(value: LibraryRoute.videoDetail(videoId: video.id)) {
                                    AppRow(
                                        title: video.title,
                                        metadata: metadataLine(video.dance?.name ?? "", video.videoType.displayName, video.durationLabel),
                                        leadingIcon: "play.circle"
                                    )
                                }
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            }
        }
    }

    private var figureList: some View {
        let filtered = figures.filter {
            matchesSearch($0.name) && matchesDance($0.dance)
                && matchesLevel($0.level)
                && (!favouritesOnly || $0.isFavourite)
        }
        let searchActive = !searchText.trimmingCharacters(in: .whitespaces).isEmpty
        return VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignTokens.Space.space2) {
                    FilterChip(title: "All", isSelected: selectedDance == nil) {
                        selectedDance = nil
                    }
                    ForEach(dances) { dance in
                        FilterChip(title: dance.name, isSelected: selectedDance?.id == dance.id) {
                            selectedDance = dance
                        }
                    }
                }
                .padding(.horizontal, DesignTokens.Space.screenMargin)
            }
            .padding(.bottom, DesignTokens.Space.space2)

            HStack(spacing: DesignTokens.Space.space2) {
                FilterChip(
                    title: selectedLevel?.displayName ?? "All levels",
                    isSelected: selectedLevel != nil
                ) {
                    showingLevelFilter = true
                }
                FilterChip(
                    title: "Favourites",
                    isSelected: favouritesOnly
                ) {
                    favouritesOnly.toggle()
                }
                Spacer()
            }
            .padding(.horizontal, DesignTokens.Space.screenMargin)
            .padding(.bottom, DesignTokens.Space.space2)

            if figures.isEmpty {
                Text("Pending the client NDCA list")
                    .font(DesignTokens.Font.footnote)
                    .foregroundStyle(DesignTokens.Color.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, DesignTokens.Space.screenMargin)
                    .padding(.bottom, DesignTokens.Space.space2)
            }

            if filtered.isEmpty {
                if searchActive {
                    VStack(spacing: DesignTokens.Space.space3) {
                        EmptyStateView(
                            icon: "magnifyingglass",
                            title: "No figures found.",
                            helper: "Try a different search."
                        )
                        AppTextButton(title: "Clear search") {
                            searchText = ""
                        }
                    }
                } else if favouritesOnly {
                    EmptyStateView(
                        icon: "star",
                        title: "No favourite figures yet.",
                        helper: "Tap the star on a figure to save it here."
                    )
                } else {
                    EmptyStateView(
                        icon: "figure.dance",
                        title: "No figures for this dance yet.",
                        helper: "Figures arrive with the client NDCA list."
                    )
                }
            } else {
                List {
                    ForEach(filtered) { figure in
                        NavigationLink(value: LibraryRoute.figureDetail(figureId: figure.id)) {
                            AppRow(
                                title: figure.name,
                                metadata: metadataLine(figure.dance?.name ?? "", figure.level.displayName, "\(figure.practiceLogs.count) sessions"),
                                isFavourite: figure.isFavourite,
                                leadingIcon: "figure.dance"
                            )
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .sheet(isPresented: $showingLevelFilter) {
            NavigationStack {
                List {
                    Button("All levels") {
                        selectedLevel = nil
                        showingLevelFilter = false
                    }
                    ForEach(FigureLevel.allCases, id: \.self) { level in
                        Button {
                            selectedLevel = level
                            showingLevelFilter = false
                        } label: {
                            HStack {
                                Text(level.displayName)
                                    .foregroundStyle(DesignTokens.Color.textPrimary)
                                Spacer()
                                if selectedLevel == level {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(DesignTokens.Color.accent)
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Level")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showingLevelFilter = false }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    private var drillList: some View {
        let filtered = drills.filter {
            matchesSearch($0.name) && matchesDance($0.dance)
                && matchesFocusArea($0.focusArea)
                && (!favouritesOnly || $0.isFavourite)
        }
        let favourites = filtered.filter { $0.isFavourite }
        let others = filtered.filter { !$0.isFavourite }
        return Group {
            if drills.isEmpty {
                EmptyStateView(
                    icon: "timer",
                    title: "No drills yet",
                    helper: "Save a drill to practise it again.",
                    actionTitle: "Add Drill",
                    action: { onNavigate(.drillForm(drillId: nil)) }
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
                        focusAreaFilterChip
                        favouritesFilterChip
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
                    ForEach(dances) { dance in
                        let group = others.filter { $0.dance?.id == dance.id }
                        if !group.isEmpty {
                            Section(dance.name) {
                                ForEach(group) { drill in
                                    drillRow(drill)
                                }
                            }
                        }
                    }
                    let ungrouped = others.filter { $0.dance == nil }
                    if !ungrouped.isEmpty {
                        Section("Uncategorised") {
                            ForEach(ungrouped) { drill in
                                drillRow(drill)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    private func matchesFocusArea(_ focusArea: String) -> Bool {
        guard let selectedFocusArea else { return true }
        return focusArea == selectedFocusArea
    }

    private func matchesLevel(_ level: FigureLevel) -> Bool {
        guard let selectedLevel else { return true }
        return level == selectedLevel
    }

    private func drillRow(_ drill: Drill) -> some View {
        NavigationLink(value: LibraryRoute.drillDetail(drillId: drill.id)) {
            AppRow(
                title: drill.name,
                metadata: metadataLine(drill.dance?.name ?? "", drill.focusAreaDisplayName, "\(drill.targetRepetitions) repetitions"),
                isFavourite: drill.isFavourite
            )
        }
    }
}
