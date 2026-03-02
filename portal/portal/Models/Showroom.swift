import Foundation
import FirebaseFirestore

struct Showroom: Codable, Identifiable, Sendable {
    @DocumentID var id: String?
    var clientId: String = ""
    var city: String = ""
    var buildingNumber: String = ""
    var floorNumber: String = ""
    var boothNumber: String = ""
}
