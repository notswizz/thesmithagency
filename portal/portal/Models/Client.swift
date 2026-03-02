import Foundation
import FirebaseFirestore

struct Client: Codable, Identifiable, Sendable {
    @DocumentID var id: String?
    var name: String?
    var email: String?
    var website: String?
    var onboardingCompleted: Bool?
    var stripeCustomerId: String?
    var createdAt: Timestamp?
    var updatedAt: Timestamp?
}
