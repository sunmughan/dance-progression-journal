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
