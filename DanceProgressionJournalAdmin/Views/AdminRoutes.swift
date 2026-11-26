import Foundation

// MARK: - Admin routes
//
// One route enum for the admin app. Routes carry identifiers, never
// model objects, so a route stays valid if the store changes under
// it. The admin app shares the user app store, so an edit here
// appears in the user app at once.

enum AdminRoute: Hashable {
    case manageFigures
    case manageCompetitions
    case manageDrills
    case contentCategories
    case appSettings
    case competitionForm(competitionId: UUID?)
    case drillForm(drillId: UUID?)
}
