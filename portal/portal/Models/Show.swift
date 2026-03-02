import Foundation
import FirebaseFirestore

struct Show: Codable, Identifiable, Sendable {
    @DocumentID var id: String?
    var name: String?
    var startDate: String?
    var endDate: String?
    var location: String?
    var status: String?
    var season: String?
    var type: String?
    var customType: String?
    var venue: String?
    var market: String?  // "atlanta", "dallas", "other"
    var description: String?
    var createdAt: Timestamp?
    var updatedAt: Timestamp?

    var displayName: String { name ?? "" }
    var displayLocation: String { location ?? "" }

    var city: String {
        displayLocation.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces) ?? displayLocation
    }

    var dateRange: [String] {
        guard let start = DateHelper.date(from: startDate ?? ""),
              let end = DateHelper.date(from: endDate ?? "") else { return [] }
        var dates: [String] = []
        var current = start
        while current <= end {
            dates.append(DateHelper.string(from: current))
            guard let next = Calendar.current.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
        return dates
    }

    var isActive: Bool { status == "active" }
}
