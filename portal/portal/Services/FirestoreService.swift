import Foundation
import FirebaseFirestore
import FirebaseAuth

@Observable
final class FirestoreService {
    private let db = Firestore.firestore()

    // MARK: - Staff

    func fetchStaff(uid: String) async throws -> Staff? {
        // First try by doc ID (auth UID)
        let doc = try await db.collection("staff").document(uid).getDocument()
        if doc.exists {
            // Try Codable first, fall back to manual parsing
            if let staff = try? doc.data(as: Staff.self) {
                return staff
            }
            // Manual fallback if Codable fails (type mismatches)
            if let data = doc.data() {
                return staffFromDict(data, id: doc.documentID)
            }
        }
        // Fallback: search by email for legacy web-created staff
        if let email = Auth.auth().currentUser?.email {
            let snapshot = try await db.collection("staff")
                .whereField("email", isEqualTo: email)
                .limit(to: 1)
                .getDocuments()
            if let d = snapshot.documents.first {
                if let staff = try? d.data(as: Staff.self) {
                    return staff
                }
                return staffFromDict(d.data(), id: d.documentID)
            }
        }
        return nil
    }

    private func staffFromDict(_ data: [String: Any], id: String) -> Staff {
        var staff = Staff()
        staff.id = id
        staff.name = data["name"] as? String
        staff.email = data["email"] as? String
        staff.phone = data["phone"] as? String
        staff.location = data["location"] as? String
        staff.address = data["address"] as? String
        staff.college = data["college"] as? String
        staff.dressSize = data["dressSize"] as? String
        staff.shoeSize = data["shoeSize"] as? String
        staff.instagram = data["instagram"] as? String
        staff.retailWholesaleExperience = data["retailWholesaleExperience"] as? String
        staff.resumeURL = data["resumeURL"] as? String
        staff.photoURL = data["photoURL"] as? String
        if let rate = data["payRate"] as? String {
            staff.payRate = rate
        } else if let rate = data["payRate"] as? NSNumber {
            staff.payRate = "\(rate)"
        }
        staff.role = data["role"] as? String
        staff.active = data["active"] as? Bool
        staff.createdAt = data["createdAt"] as? Timestamp
        staff.updatedAt = data["updatedAt"] as? Timestamp
        return staff
    }

    func fetchStaffByIds(_ ids: [String]) async throws -> [String: Staff] {
        guard !ids.isEmpty else { return [:] }
        var result: [String: Staff] = [:]
        // Firestore `in` queries support max 30 items
        for chunk in ids.chunked(into: 30) {
            let snapshot = try await db.collection("staff")
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments()
            for doc in snapshot.documents {
                if let staff = try? doc.data(as: Staff.self) {
                    result[doc.documentID] = staff
                }
            }
        }
        return result
    }

    func updateStaff(_ staff: Staff) async throws {
        guard let id = staff.id else { return }
        var updated = staff
        updated.updatedAt = Timestamp()
        try db.collection("staff").document(id).setData(from: updated, merge: true)
    }

    // MARK: - Client

    func fetchClient(uid: String) async throws -> Client? {
        // First try by doc ID (iOS-created clients use auth UID as doc ID)
        let doc = try await db.collection("clients").document(uid).getDocument()
        if doc.exists {
            if let client = try? doc.data(as: Client.self) {
                return client
            }
            if let data = doc.data() {
                var client = Client()
                client.id = doc.documentID
                client.name = data["name"] as? String
                client.email = data["email"] as? String
                client.website = data["website"] as? String
                client.createdAt = data["createdAt"] as? Timestamp
                client.updatedAt = data["updatedAt"] as? Timestamp
                return client
            }
        }
        // Fallback: search by email for legacy web-created clients
        if let email = Auth.auth().currentUser?.email {
            let snapshot = try await db.collection("clients")
                .whereField("email", isEqualTo: email)
                .limit(to: 1)
                .getDocuments()
            if let d = snapshot.documents.first {
                if let client = try? d.data(as: Client.self) {
                    return client
                }
                var client = Client()
                client.id = d.documentID
                let data = d.data()
                client.name = data["name"] as? String
                client.email = data["email"] as? String
                client.website = data["website"] as? String
                return client
            }
        }
        return nil
    }

    func updateClient(_ client: Client) async throws {
        guard let id = client.id else { return }
        var updated = client
        updated.updatedAt = Timestamp()
        try db.collection("clients").document(id).setData(from: updated, merge: true)
    }

    // MARK: - Shows

    func fetchUpcomingShows() async throws -> [Show] {
        let snapshot = try await db.collection("shows")
            .whereField("status", isEqualTo: "active")
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Show.self) }
    }

    func fetchAllShows() async throws -> [Show] {
        let snapshot = try await db.collection("shows").getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Show.self) }
    }

    func fetchShow(id: String) async throws -> Show? {
        let doc = try await db.collection("shows").document(id).getDocument()
        return try? doc.data(as: Show.self)
    }

    // MARK: - Availability

    func fetchAvailability(staffId: String) async throws -> [Availability] {
        let snapshot = try await db.collection("availability")
            .whereField("staffId", isEqualTo: staffId)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Availability.self) }
    }

    func submitAvailability(_ availability: Availability) async throws {
        // Check for existing availability for same staff + show
        let existing = try await db.collection("availability")
            .whereField("staffId", isEqualTo: availability.staffId)
            .whereField("showId", isEqualTo: availability.showId)
            .getDocuments()

        if let existingDoc = existing.documents.first {
            // Update existing
            try existingDoc.reference.setData(from: availability, merge: true)
        } else {
            // Create new
            var newAvail = availability
            newAvail.createdAt = Timestamp()
            _ = try db.collection("availability").addDocument(from: newAvail)
        }
    }

    // MARK: - Bookings

    func fetchBookingsForClient(clientId: String) async throws -> [Booking] {
        let snapshot = try await db.collection("bookings")
            .whereField("clientId", isEqualTo: clientId)
            .getDocuments()
        return decodeBookings(snapshot.documents)
    }

    func fetchBookingsForStaff(staffId: String) async throws -> [Booking] {
        // Firestore can't query array-of-objects directly for nested field,
        // so fetch all bookings and filter client-side
        let snapshot = try await db.collection("bookings").getDocuments()
        let all = decodeBookings(snapshot.documents)
        return all.filter { booking in
            (booking.datesNeeded ?? []).contains { ($0.staffIds ?? []).contains(staffId) }
        }
    }

    private func decodeBookings(_ documents: [QueryDocumentSnapshot]) -> [Booking] {
        documents.compactMap { doc in
            do {
                return try doc.data(as: Booking.self)
            } catch {
                print("Failed to decode booking \(doc.documentID): \(error)")
                return nil
            }
        }
    }

    func createBooking(_ booking: Booking) async throws {
        var newBooking = booking
        newBooking.createdAt = FlexTimestamp(timestamp: Timestamp())
        newBooking.updatedAt = FlexTimestamp(timestamp: Timestamp())
        _ = try db.collection("bookings").addDocument(from: newBooking)
    }

    // MARK: - Contacts

    func fetchContacts(clientId: String) async throws -> [Contact] {
        let snapshot = try await db.collection("contacts")
            .whereField("clientId", isEqualTo: clientId)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Contact.self) }
    }

    func addContact(_ contact: Contact) async throws {
        _ = try db.collection("contacts").addDocument(from: contact)
    }

    func updateContact(_ contact: Contact) async throws {
        guard let id = contact.id else { return }
        try db.collection("contacts").document(id).setData(from: contact)
    }

    func deleteContact(id: String) async throws {
        try await db.collection("contacts").document(id).delete()
    }

    // MARK: - Showrooms

    func fetchShowrooms(clientId: String) async throws -> [Showroom] {
        let snapshot = try await db.collection("showrooms")
            .whereField("clientId", isEqualTo: clientId)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Showroom.self) }
    }

    func addShowroom(_ showroom: Showroom) async throws {
        _ = try db.collection("showrooms").addDocument(from: showroom)
    }

    func updateShowroom(_ showroom: Showroom) async throws {
        guard let id = showroom.id else { return }
        try db.collection("showrooms").document(id).setData(from: showroom)
    }

    func deleteShowroom(id: String) async throws {
        try await db.collection("showrooms").document(id).delete()
    }
}
