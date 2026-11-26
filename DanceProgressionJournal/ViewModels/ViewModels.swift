import Foundation
import SwiftData

// MARK: - View models
//
// View models own screen state and talk to repositories. They never touch
// a ModelContext. Views read lists through @Query and send actions here.
// Single direction data flow: store to view to action to repository to
// store, and the view updates from the store.

@Observable
@MainActor
final class JournalListViewModel {
    var searchText = ""
    var selectedCategory: EntryCategory?
    var selectedDance: Dance?
    var newestFirst = true
    var errorMessage: String?

    private let repository: JournalEntryRepositoryProtocol

    init(repository: JournalEntryRepositoryProtocol) {
        self.repository = repository
    }

    var activeFilterLabel: String {
        selectedDance?.name ?? "All dances"
    }

    func filtered(_ entries: [JournalEntry]) -> [JournalEntry] {
        var result = entries
        if let selectedCategory {
            result = result.filter { $0.category == selectedCategory }
        }
        if let selectedDance {
            let danceId = selectedDance.id
            result = result.filter { $0.dance?.id == danceId }
        }
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        if !query.isEmpty {
            result = result.filter {
                $0.title.lowercased().contains(query)
                    || $0.bodyText.lowercased().contains(query)
            }
        }
        result.sort {
            newestFirst ? $0.entryDate > $1.entryDate : $0.entryDate < $1.entryDate
        }
        return result
    }

    func clearFilters() {
        selectedCategory = nil
        selectedDance = nil
        searchText = ""
    }

    func delete(_ entry: JournalEntry) {
        do {
            try repository.delete(entry)
        } catch {
            errorMessage = "This entry could not be deleted. Check storage and try again."
        }
    }
}

@Observable
@MainActor
final class JournalEntryFormViewModel {
    var title = ""
    var bodyText = ""
    var selectedDance: Dance?
    var entryDate = Date()
    var instagramLink = ""
    var linkedDrillIds: [UUID] = []
    var linkedVideoIds: [UUID] = []
    var linkedFigureIds: [UUID] = []
    var category: EntryCategory = .uncategorised
    var aiTags: [String] = []
    var isSaving = false
    var errorMessage: String?

    private(set) var dances: [Dance] = []
    private var editingEntry: JournalEntry?
    private var categoryManuallyEdited = false

    private let repository: JournalEntryRepositoryProtocol
    private let categorisation: CategorisationServiceProtocol

    init(
        repository: JournalEntryRepositoryProtocol,
        categorisation: CategorisationServiceProtocol
    ) {
        self.repository = repository
        self.categorisation = categorisation
    }

    var isEditing: Bool { editingEntry != nil }

    var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && selectedDance != nil
    }

    var saveDisabledReason: String? {
        if title.trimmingCharacters(in: .whitespaces).isEmpty {
            return "Enter a title to save."
        }
        if selectedDance == nil {
            return "Pick a dance to save."
        }
        return nil
    }

    func load(entry: JournalEntry?, dances: [Dance]) {
        self.dances = dances
        guard let entry else {
            selectedDance = dances.first
            return
        }
        editingEntry = entry
        title = entry.title
        bodyText = entry.bodyText
        selectedDance = entry.dance
        entryDate = entry.entryDate
        instagramLink = entry.instagramLink ?? ""
        linkedDrillIds = entry.linkedDrillIds
        linkedVideoIds = entry.linkedVideoIds
        linkedFigureIds = entry.linkedFigureIds
        category = entry.category
        aiTags = entry.aiTags
    }

    /// Runs the on device categoriser over the current text. Called as
    /// text is entered, so the category preview stays live. A manual
    /// category change wins over the suggestion after that.
    func refreshSuggestedCategory() {
        guard !categoryManuallyEdited else { return }
        let result = categorisation.categorise(title: title, body: bodyText)
        category = result.category
        aiTags = result.tags
    }

    func setCategory(_ newCategory: EntryCategory) {
        category = newCategory
        categoryManuallyEdited = true
    }

    /// Saves and returns the saved entry id, or nil when the save failed.
    func save() -> UUID? {
        guard canSave, let dance = selectedDance else { return nil }
        isSaving = true
        defer { isSaving = false }
        let result = categorisation.categorise(title: title, body: bodyText)
        let trimmedLink = instagramLink.trimmingCharacters(in: .whitespaces)
        do {
            if let entry = editingEntry {
                entry.title = title.trimmingCharacters(in: .whitespaces)
                entry.bodyText = bodyText
                entry.dance = dance
                entry.entryDate = entryDate
                entry.updatedDate = Date()
                entry.instagramLink = trimmedLink.isEmpty ? nil : trimmedLink
                entry.linkedDrillIds = linkedDrillIds
                entry.linkedVideoIds = linkedVideoIds
                entry.linkedFigureIds = linkedFigureIds
                if !categoryManuallyEdited {
                    entry.category = result.category
                    entry.aiConfidence = result.confidence
                    entry.aiTags = result.tags
                } else {
                    entry.category = category
                    entry.aiTags = aiTags
                }
                try repository.save()
                return entry.id
            } else {
                let entry = JournalEntry(
                    title: title.trimmingCharacters(in: .whitespaces),
                    bodyText: bodyText,
                    entryDate: entryDate,
                    dance: dance,
                    category: categoryManuallyEdited ? category : result.category,
                    aiConfidence: categoryManuallyEdited ? 0 : result.confidence,
                    aiTags: categoryManuallyEdited ? aiTags : result.tags,
                    instagramLink: trimmedLink.isEmpty ? nil : trimmedLink,
                    linkedVideoIds: linkedVideoIds,
                    linkedDrillIds: linkedDrillIds,
                    linkedFigureIds: linkedFigureIds
                )
                try repository.insert(entry)
                return entry.id
            }
        } catch {
            errorMessage = "This entry could not be saved. Check storage and try again."
            return nil
        }
    }
}

@Observable
@MainActor
final class WelcomeViewModel {
    var dancerName = ""
    var selectedDanceIds: Set<UUID> = []
    var experienceLevel: ExperienceLevel = .competitionDancer
    var errorMessage: String?

    private let profileRepository: ProfileRepositoryProtocol
    private let danceRepository: DanceRepositoryProtocol

    init(
        profileRepository: ProfileRepositoryProtocol,
        danceRepository: DanceRepositoryProtocol
    ) {
        self.profileRepository = profileRepository
        self.danceRepository = danceRepository
    }

    var canContinue: Bool {
        !dancerName.trimmingCharacters(in: .whitespaces).isEmpty && !selectedDanceIds.isEmpty
    }

    /// Continue writes the profile the user just set. Skip keeps the
    /// sample defaults: name blank, all five dances selected.
    func finish(skipped: Bool) throws {
        let dances = try danceRepository.fetchActiveOrdered()
        let chosen = skipped ? dances : dances.filter { selectedDanceIds.contains($0.id) }
        let name = skipped ? "" : dancerName.trimmingCharacters(in: .whitespaces)
        if let existing = try profileRepository.fetchProfile() {
            existing.dancerName = name
            existing.experienceLevel = skipped ? existing.experienceLevel : experienceLevel
            existing.preferredDances = chosen
            existing.updatedDate = Date()
            if existing.appSettings == nil {
                existing.appSettings = AppSettings()
            }
            try profileRepository.save()
        } else {
            let profile = LocalProfile(
                dancerName: name,
                experienceLevel: experienceLevel,
                preferredDances: chosen
            )
            profile.appSettings = AppSettings()
            try profileRepository.insert(profile)
        }
    }
}

@Observable
@MainActor
final class SettingsViewModel {
    var storageUsedBytes: Int64 = 0
    var videoCount: Int = 0
    var errorMessage: String?
    var showDeleteConfirmation = false

    private let persistence: PersistenceController

    init(persistence: PersistenceController) {
        self.persistence = persistence
    }

    func refreshStorage() {
        storageUsedBytes = persistence.videoFileService.storageUsedBytes()
        let descriptor = FetchDescriptor<Video>()
        videoCount = (try? persistence.mainContext.fetchCount(descriptor)) ?? 0
    }

    var storageLabel: String {
        let megabytes = Double(storageUsedBytes) / 1_000_000
        if megabytes < 1 {
            return "\(videoCount) videos, \(storageUsedBytes) KB on this device"
        }
        return "\(videoCount) videos, \(String(format: "%.0f", megabytes)) MB on this device"
    }

    func deleteAllData() {
        do {
            try persistence.deleteAllData()
        } catch {
            errorMessage = "The data could not be deleted. Check storage and try again."
        }
    }
}

@Observable
@MainActor
final class DrillFormViewModel {
    var name = ""
    var selectedDance: Dance?
    var focusArea: FocusArea = .footwork
    var descriptionText = ""
    var targetRepetitions = 20
    var targetDurationMinutes = 15
    var difficulty: Difficulty = .intermediate
    var isFavourite = false
    var isSaving = false
    var errorMessage: String?

    private(set) var dances: [Dance] = []
    private var editingDrill: Drill?

    private let repository: DrillRepositoryProtocol

    init(repository: DrillRepositoryProtocol) {
        self.repository = repository
    }

    var isEditing: Bool { editingDrill != nil }

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && selectedDance != nil
    }

    var saveDisabledReason: String? {
        if name.trimmingCharacters(in: .whitespaces).isEmpty {
            return "Enter a name and pick a dance to save."
        }
        if selectedDance == nil {
            return "Pick a dance to save."
        }
        return nil
    }

    func load(drill: Drill?, dances: [Dance]) {
        self.dances = dances
        guard let drill else {
            selectedDance = dances.first
            return
        }
        editingDrill = drill
        name = drill.name
        selectedDance = drill.dance
        focusArea = drill.focusArea
        descriptionText = drill.descriptionText
        targetRepetitions = drill.targetRepetitions
        targetDurationMinutes = drill.targetDurationMinutes
        difficulty = drill.difficulty
        isFavourite = drill.isFavourite
    }

    /// Saves and returns the saved drill id, or nil when the save failed.
    func save() -> UUID? {
        guard canSave, let dance = selectedDance else { return nil }
        isSaving = true
        defer { isSaving = false }
        do {
            if let drill = editingDrill {
                drill.name = name.trimmingCharacters(in: .whitespaces)
                drill.dance = dance
                drill.focusArea = focusArea
                drill.descriptionText = descriptionText
                drill.targetRepetitions = max(targetRepetitions, 0)
                drill.targetDurationMinutes = max(targetDurationMinutes, 0)
                drill.difficulty = difficulty
                drill.isFavourite = isFavourite
                drill.updatedDate = Date()
                try repository.save()
                return drill.id
            } else {
                let drill = Drill(
                    name: name.trimmingCharacters(in: .whitespaces),
                    dance: dance,
                    focusArea: focusArea,
                    descriptionText: descriptionText,
                    targetRepetitions: max(targetRepetitions, 0),
                    targetDurationMinutes: max(targetDurationMinutes, 0),
                    difficulty: difficulty,
                    isFavourite: isFavourite
                )
                try repository.insert(drill)
                return drill.id
            }
        } catch {
            errorMessage = "This drill could not be saved. Check storage and try again."
            return nil
        }
    }
}

@Observable
@MainActor
final class VideoFormViewModel {
    var title = ""
    var recordedDate = Date()
    var selectedDance: Dance?
    var videoType: VideoType = .choreography
    var choreographyName = ""
    var selectedDrillId: UUID?
    var notes = ""
    var instagramLink = ""
    var isSaving = false
    var errorMessage: String?

    /// The picked video file, in a temporary location the form owns. Nil
    /// until a video is picked, and when editing an existing video.
    var pickedVideoURL: URL?
    var pickedDurationSeconds: Double = 0
    var pickedFileSizeBytes: Int64 = 0

    private(set) var dances: [Dance] = []
    private(set) var drills: [Drill] = []
    private(set) var sizeLimitMB = 500

    private var editingVideo: Video?

    private let repository: VideoRepositoryProtocol
    private let fileService: VideoFileService

    init(repository: VideoRepositoryProtocol, fileService: VideoFileService) {
        self.repository = repository
        self.fileService = fileService
    }

    var isEditing: Bool { editingVideo != nil }

    var sizeLimitExceeded: Bool {
        pickedVideoURL != nil
            && VideoFileService.isOverSizeLimit(bytes: pickedFileSizeBytes, limitMB: sizeLimitMB)
    }

    var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
            && selectedDance != nil
            && (editingVideo != nil || pickedVideoURL != nil)
            && !sizeLimitExceeded
    }

    var saveDisabledReason: String? {
        if title.trimmingCharacters(in: .whitespaces).isEmpty {
            return "Enter a title to save."
        }
        if selectedDance == nil {
            return "Pick a dance to save."
        }
        if editingVideo == nil && pickedVideoURL == nil {
            return "Pick a video to save."
        }
        if sizeLimitExceeded {
            return "This video is over the size limit. Pick a shorter video."
        }
        return nil
    }

    var pickedSizeLabel: String {
        let megabytes = Double(pickedFileSizeBytes) / 1_000_000
        if megabytes < 1 {
            return "\(pickedFileSizeBytes) KB"
        }
        return String(format: "%.0f MB", megabytes)
    }

    func load(video: Video?, dances: [Dance], drills: [Drill], sizeLimitMB: Int) {
        self.dances = dances
        self.drills = drills
        self.sizeLimitMB = sizeLimitMB
        guard let video else {
            selectedDance = dances.first
            return
        }
        editingVideo = video
        title = video.title
        recordedDate = video.recordedDate
        selectedDance = video.dance
        videoType = video.videoType
        choreographyName = video.choreographyName ?? ""
        selectedDrillId = video.drillId
        notes = video.notes
        instagramLink = video.instagramLink ?? ""
        pickedDurationSeconds = video.durationSeconds
    }

    /// Inspects a freshly picked video file: duration and byte size.
    /// Runs off the main actor for the asset load, then updates state.
    func inspectPickedVideo() async {
        guard let url = pickedVideoURL else { return }
        pickedFileSizeBytes = fileService.fileSizeBytes(at: url)
        pickedDurationSeconds = await fileService.durationSeconds(for: url)
    }

    /// Saves and returns the saved video id, or nil when the save failed.
    /// A new video is copied into the Videos folder first; an edit only
    /// updates the metadata and keeps the existing file.
    func save() -> UUID? {
        guard canSave, let dance = selectedDance else { return nil }
        isSaving = true
        defer { isSaving = false }
        let trimmedLink = instagramLink.trimmingCharacters(in: .whitespaces)
        do {
            if let video = editingVideo {
                video.title = title.trimmingCharacters(in: .whitespaces)
                video.recordedDate = recordedDate
                video.dance = dance
                video.videoType = videoType
                video.choreographyName = videoType == .choreography ? choreographyName.trimmingCharacters(in: .whitespaces) : nil
                video.drillId = videoType == .drill ? selectedDrillId : nil
                video.notes = notes
                video.instagramLink = trimmedLink.isEmpty ? nil : trimmedLink
                try repository.save()
                return video.id
            } else {
                guard let pickedURL = pickedVideoURL else { return nil }
                let fileExtension = pickedURL.pathExtension.isEmpty ? "mov" : pickedURL.pathExtension
                let relativePath = try fileService.saveVideo(from: pickedURL, fileExtension: fileExtension)
                let thumbnail = try? fileService.generateThumbnail(forRelativePath: relativePath)
                let video = Video(
                    title: title.trimmingCharacters(in: .whitespaces),
                    fileName: (relativePath as NSString).lastPathComponent,
                    relativePath: relativePath,
                    thumbnailRelativePath: thumbnail,
                    durationSeconds: pickedDurationSeconds,
                    recordedDate: recordedDate,
                    dance: dance,
                    videoType: videoType,
                    choreographyName: videoType == .choreography ? choreographyName.trimmingCharacters(in: .whitespaces) : nil,
                    drillId: videoType == .drill ? selectedDrillId : nil,
                    notes: notes,
                    instagramLink: trimmedLink.isEmpty ? nil : trimmedLink
                )
                try repository.insert(video)
                return video.id
            }
        } catch {
            errorMessage = "This video could not be saved. Check storage and try again."
            return nil
        }
    }
}
