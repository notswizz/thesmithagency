import Foundation

@Observable
final class AvailabilityViewModel {
    var shows: [Show] = []
    var submittedShowIds: Set<String> = []
    var selectedDates: Set<String> = []
    var isLoading = false
    var isSaving = false
    var errorMessage: String?
    var locationFilter: String?

    private let firestoreService: FirestoreService

    init(firestoreService: FirestoreService) {
        self.firestoreService = firestoreService
    }

    var filteredShows: [Show] {
        guard let filter = locationFilter, !filter.isEmpty else { return shows }
        return shows.filter { $0.city.localizedCaseInsensitiveContains(filter) }
    }

    var availableLocations: [String] {
        Array(Set(shows.map(\.city))).sorted()
    }

    func loadShows(staffId: String, staffLocation: String?) async {
        isLoading = true
        defer { isLoading = false }
        do {
            shows = try await firestoreService.fetchUpcomingShows()
            let availability = try await firestoreService.fetchAvailability(staffId: staffId)
            submittedShowIds = Set(availability.map(\.showId))

            // Auto-filter to staff city if it matches any show
            if let loc = staffLocation,
               shows.contains(where: { $0.city.localizedCaseInsensitiveContains(loc) }) {
                locationFilter = loc
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadExistingAvailability(staffId: String, showId: String) async {
        do {
            let all = try await firestoreService.fetchAvailability(staffId: staffId)
            if let existing = all.first(where: { $0.showId == showId }) {
                selectedDates = Set(existing.availableDates)
            } else {
                selectedDates = []
            }
        } catch {
            selectedDates = []
        }
    }

    func toggleDate(_ date: String) {
        if selectedDates.contains(date) {
            selectedDates.remove(date)
        } else {
            selectedDates.insert(date)
        }
    }

    func submitAvailability(staffId: String, staffName: String, show: Show) async {
        guard let showId = show.id else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            let availability = Availability(
                staffId: staffId,
                staffName: staffName,
                showId: showId,
                showName: show.displayName,
                availableDates: selectedDates.sorted()
            )
            try await firestoreService.submitAvailability(availability)
            submittedShowIds.insert(showId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
