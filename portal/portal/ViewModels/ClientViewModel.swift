import Foundation

@Observable
final class ClientViewModel {
    var client: Client?
    var contacts: [Contact] = []
    var showrooms: [Showroom] = []
    var isLoading = false
    var errorMessage: String?

    private let firestoreService: FirestoreService

    init(firestoreService: FirestoreService) {
        self.firestoreService = firestoreService
    }

    func loadClient(uid: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            client = try await firestoreService.fetchClient(uid: uid)
            contacts = try await firestoreService.fetchContacts(clientId: uid)
            showrooms = try await firestoreService.fetchShowrooms(clientId: uid)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addContact(_ contact: Contact) async {
        do {
            try await firestoreService.addContact(contact)
            if let clientId = client?.id {
                contacts = try await firestoreService.fetchContacts(clientId: clientId)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateContact(_ contact: Contact) async {
        do {
            try await firestoreService.updateContact(contact)
            if let clientId = client?.id {
                contacts = try await firestoreService.fetchContacts(clientId: clientId)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteContact(id: String) async {
        do {
            try await firestoreService.deleteContact(id: id)
            contacts.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addShowroom(_ showroom: Showroom) async {
        do {
            try await firestoreService.addShowroom(showroom)
            if let clientId = client?.id {
                showrooms = try await firestoreService.fetchShowrooms(clientId: clientId)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateShowroom(_ showroom: Showroom) async {
        do {
            try await firestoreService.updateShowroom(showroom)
            if let clientId = client?.id {
                showrooms = try await firestoreService.fetchShowrooms(clientId: clientId)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteShowroom(id: String) async {
        do {
            try await firestoreService.deleteShowroom(id: id)
            showrooms.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
