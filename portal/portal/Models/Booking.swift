import Foundation
import FirebaseFirestore

struct BookingAdjustment: Codable, Sendable {
    var label: String
    var amount: Int  // cents, positive or negative
}

struct DateNeed: Codable, Sendable {
    var date: String?
    var staffCount: Int?
    var staffIds: [String]?
}

struct FlexTimestamp: Codable, Sendable {
    var timestamp: Timestamp?

    init(timestamp: Timestamp? = nil) {
        self.timestamp = timestamp
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let ts = try? container.decode(Timestamp.self) {
            timestamp = ts
        } else {
            // It's a string or something else — just ignore it
            timestamp = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let ts = timestamp {
            try container.encode(ts)
        } else {
            try container.encodeNil()
        }
    }
}

struct Booking: Codable, Identifiable, Sendable {
    @DocumentID var id: String?
    var clientId: String?
    var showId: String?
    var showName: String?
    var title: String?
    var assignedDate: String?
    var status: String?
    var paymentStatus: String?
    var contactName: String?
    var contactEmail: String?
    var contactPhone: String?
    var showroomCity: String?
    var showroomLocation: String?
    var notes: String?
    var totalStaffNeeded: Int?
    var datesNeeded: [DateNeed]?
    var market: String?
    var dailyRate: Int?           // cents
    var totalStaffDays: Int?
    var estimatedTotal: Int?      // cents
    var depositAmount: Int?       // cents
    var balanceDue: Int?          // cents
    var finalAmount: Int?         // cents
    var cancellationFee: Int?     // cents
    var adjustments: [BookingAdjustment]?
    var stripeCustomerId: String?
    var stripePaymentIntentId: String?
    var stripeFinalPaymentId: String?
    var createdAt: FlexTimestamp?
    var updatedAt: FlexTimestamp?

    var isUpcoming: Bool {
        guard let dates = datesNeeded,
              let lastDate = dates.compactMap(\.date).max(),
              let date = DateHelper.date(from: lastDate) else { return false }
        return date >= Date()
    }

    var displayName: String {
        showName ?? title ?? "Booking"
    }
}
