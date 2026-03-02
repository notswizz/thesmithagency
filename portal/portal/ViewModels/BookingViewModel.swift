import Foundation

@Observable
final class BookingViewModel {
    var bookings: [Booking] = []
    var shows: [Show] = []
    var showMap: [String: Show] = [:]
    var clientMap: [String: Client] = [:]
    var isLoading = false
    var isSaving = false
    var errorMessage: String?
    var successMessage: String?

    // Booking form state
    var selectedShowId: String?
    var selectedShowroomId: String?
    var selectedContactId: String?
    var notes = ""
    var dateStaffCounts: [String: Int] = [:]

    private let firestoreService: FirestoreService

    init(firestoreService: FirestoreService) {
        self.firestoreService = firestoreService
    }

    var selectedShow: Show? {
        guard let id = selectedShowId else { return nil }
        return showMap[id]
    }

    var upcomingBookings: [Booking] {
        bookings.filter(\.isUpcoming).sorted { ($0.datesNeeded?.first?.date ?? "") > ($1.datesNeeded?.first?.date ?? "") }
    }

    var pastBookings: [Booking] {
        bookings.filter { !$0.isUpcoming }.sorted { ($0.datesNeeded?.first?.date ?? "") > ($1.datesNeeded?.first?.date ?? "") }
    }

    func loadClientBookings(clientId: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            bookings = try await firestoreService.fetchBookingsForClient(clientId: clientId)
            let allShows = try await firestoreService.fetchAllShows()
            showMap = Dictionary(uniqueKeysWithValues: allShows.compactMap { s in
                guard let id = s.id else { return nil }
                return (id, s)
            })
            shows = allShows.filter { $0.isActive }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadStaffBookings(staffId: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let all = try await firestoreService.fetchBookingsForStaff(staffId: staffId)
            // Staff should only see bookings with status "booked" or "completed"
            bookings = all.filter { b in
                let status = b.status?.lowercased() ?? ""
                return status == "booked" || status == "completed"
            }
            let allShows = try await firestoreService.fetchAllShows()
            showMap = Dictionary(uniqueKeysWithValues: allShows.compactMap { s in
                guard let id = s.id else { return nil }
                return (id, s)
            })
            // Fetch client names for each booking
            let clientIds = Set(bookings.compactMap(\.clientId))
            for cid in clientIds {
                if let client = try? await firestoreService.fetchClient(uid: cid) {
                    clientMap[cid] = client
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func initializeDateCounts(for show: Show) {
        dateStaffCounts = [:]
        for date in show.dateRange {
            dateStaffCounts[date] = 1
        }
    }

    func submitBooking(
        clientId: String,
        contact: Contact? = nil,
        showroom: Showroom? = nil,
        paymentStatus: String? = nil,
        depositAmount: Int? = nil,
        stripePaymentIntentId: String? = nil,
        stripeCustomerId: String? = nil
    ) async {
        guard let showId = selectedShowId else {
            errorMessage = "Please select a show"
            return
        }
        isSaving = true
        defer { isSaving = false }

        let datesNeeded = dateStaffCounts
            .filter { $0.value > 0 }
            .map { DateNeed(date: $0.key, staffCount: $0.value, staffIds: []) }
            .sorted { ($0.date ?? "") < ($1.date ?? "") }

        guard !datesNeeded.isEmpty else {
            errorMessage = "Please set staff counts for at least one date"
            return
        }

        let showName = showMap[showId]?.displayName

        var booking = Booking(
            clientId: clientId,
            showId: showId,
            showName: showName,
            status: "pending",
            paymentStatus: paymentStatus,
            contactName: contact?.name,
            contactEmail: contact?.email,
            contactPhone: contact?.phone,
            showroomCity: showroom?.city,
            showroomLocation: showroom != nil ? "Bldg \(showroom!.buildingNumber), Floor \(showroom!.floorNumber)" : nil,
            notes: notes,
            totalStaffNeeded: datesNeeded.reduce(0) { $0 + ($1.staffCount ?? 0) },
            datesNeeded: datesNeeded
        )
        booking.depositAmount = depositAmount
        booking.stripeCustomerId = stripeCustomerId
        booking.stripePaymentIntentId = stripePaymentIntentId

        do {
            try await firestoreService.createBooking(booking)
            successMessage = "Booking submitted successfully"
            resetForm()
            await loadClientBookings(clientId: clientId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func resetForm() {
        selectedShowId = nil
        selectedShowroomId = nil
        selectedContactId = nil
        notes = ""
        dateStaffCounts = [:]
    }
}
