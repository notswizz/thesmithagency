import Foundation
import FirebaseFirestore

struct Contact: Codable, Identifiable, Sendable {
    @DocumentID var id: String?
    var clientId: String = ""
    var name: String = ""
    var email: String = ""
    var phone: String = ""
    var role: String = ""
}
