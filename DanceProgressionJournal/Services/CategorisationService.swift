import Foundation

// MARK: - On device categorisation
//
// Phase 1 categorisation is on device only, using clear local rules. No
// server AI, no AI API cost. The user can edit the category on every
// entry, so a wrong guess is always fixable. This protocol is the seam:
// Week 2 may add an on device model behind the same protocol without
// touching any view or view model.

struct CategorisationResult: Sendable, Equatable {
    let category: EntryCategory
    let confidence: Double
    let tags: [String]
}

protocol CategorisationServiceProtocol: Sendable {
    func categorise(title: String, body: String) -> CategorisationResult
}

/// Local rules categoriser. Challenge language points one way,
/// accomplishment language points the other. Ties and empty text stay
/// uncategorised. Tags come from the matched words only.
/// Bare "still" is deliberately not a challenge word: it appears in
/// forward looking notes ("still to work on the knees") after positive
/// text, and genuine challenge phrasing is covered by "needs work".
/// Verified against the three fixture journal entries in the tests.
struct LocalRulesCategorisationService: CategorisationServiceProtocol {
    private let challengeWords: [String: String] = [
        "struggle": "struggle",
        "struggled": "struggle",
        "difficult": "difficult",
        "hard": "hard",
        "timing": "timing",
        "stuck": "stuck",
        "missed": "missed",
        "needs work": "needs work",
        "weight transfer": "weight transfer",
        "close": "close",
        "turn": "turn"
    ]

    private let accomplishmentWords: [String: String] = [
        "clicked": "breakthrough",
        "finally": "breakthrough",
        "nailed": "breakthrough",
        "improved": "improved",
        "felt full": "weight transfer",
        "even": "even",
        "held": "held",
        "sharp": "sharp",
        "great": "great",
        "better": "better"
    ]

    func categorise(title: String, body: String) -> CategorisationResult {
        let text = (title + " " + body).lowercased()
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else {
            return CategorisationResult(category: .uncategorised, confidence: 0, tags: [])
        }
        var challengeHits: [String] = []
        var accomplishmentHits: [String] = []
        for (word, tag) in challengeWords where text.contains(word) {
            challengeHits.append(tag)
        }
        for (word, tag) in accomplishmentWords where text.contains(word) {
            accomplishmentHits.append(tag)
        }
        let challengeScore = challengeHits.count
        let accomplishmentScore = accomplishmentHits.count
        if challengeScore == 0 && accomplishmentScore == 0 {
            return CategorisationResult(category: .uncategorised, confidence: 0, tags: [])
        }
        if accomplishmentScore > challengeScore {
            let tags = Array(Set(accomplishmentHits)).sorted()
            let confidence = min(0.5 + 0.1 * Double(accomplishmentScore), 0.9)
            return CategorisationResult(category: .accomplishment, confidence: confidence, tags: tags)
        }
        if challengeScore > accomplishmentScore {
            let tags = Array(Set(challengeHits)).sorted()
            let confidence = min(0.5 + 0.1 * Double(challengeScore), 0.9)
            return CategorisationResult(category: .challenge, confidence: confidence, tags: tags)
        }
        let tags = Array(Set(challengeHits + accomplishmentHits)).sorted()
        return CategorisationResult(category: .uncategorised, confidence: 0.5, tags: tags)
    }
}
