import Foundation
import FirebaseFirestore

struct Staff: Codable, Identifiable, Sendable {
    @DocumentID var id: String?
    var name: String?
    var email: String?
    var phone: String?
    var location: String?
    var address: String?
    var college: String?
    var dressSize: String?
    var shoeSize: String?
    var instagram: String?
    var retailWholesaleExperience: String?
    var resumeURL: String?
    var photoURL: String?
    var payRate: String?
    var applicationFormCompleted: Bool?
    var applicationFormApproved: Bool?
    var skills: [String]?
    var role: String?
    var active: Bool?
    var bankAccountHolderName: String?
    var bankRoutingNumber: String?
    var bankAccountNumber: String?
    var bankAccountType: String?
    var directDepositCompleted: Bool?
    var createdAt: Timestamp?
    var updatedAt: Timestamp?
}
