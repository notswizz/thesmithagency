import Foundation
import FirebaseFirestore

struct Availability: Codable, Identifiable, Sendable {
    @DocumentID var id: String?
    var staffId: String = ""
    var staffName: String = ""
    var showId: String = ""
    var showName: String = ""
    var availableDates: [String] = []
    var createdAt: Timestamp?
}
