import Foundation
import StripePaymentSheet
import FirebaseFunctions

@Observable
final class StripeService {
    static let publishableKey = "pk_test_51M48tlBEXcaMIdnbvvqdwcKNGICciDnfha5nRnqnCd9AXO0MTMBQZSpxD1aCjvf2JRZTgR0g1l4MyYpI84kNkC2z00tiHg6hi5"

    private let functions = Functions.functions()

    var isLoading = false
    var errorMessage: String?

    /// Calls the createPaymentIntent Cloud Function and returns a configured PaymentSheet.
    func preparePaymentSheet(
        clientId: String,
        clientEmail: String,
        clientName: String
    ) async throws -> (paymentSheet: PaymentSheet, paymentIntentId: String, customerId: String) {
        isLoading = true
        defer { isLoading = false }

        let callable = functions.httpsCallable("createPaymentIntent")
        let result = try await callable.call([
            "clientId": clientId,
            "clientEmail": clientEmail,
            "clientName": clientName,
            "amount": 10000 // $100 deposit in cents
        ])

        guard let data = result.data as? [String: Any],
              let clientSecret = data["clientSecret"] as? String,
              let customerId = data["customerId"] as? String,
              let ephemeralKey = data["ephemeralKey"] as? String,
              let paymentIntentId = data["paymentIntentId"] as? String
        else {
            throw StripeServiceError.invalidResponse
        }

        var config = PaymentSheet.Configuration()
        config.merchantDisplayName = "The Smith Agency"
        config.customer = .init(id: customerId, ephemeralKeySecret: ephemeralKey)
        config.allowsDelayedPaymentMethods = false
        config.paymentMethodOrder = ["card"]

        let paymentSheet = PaymentSheet(
            paymentIntentClientSecret: clientSecret,
            configuration: config
        )

        return (paymentSheet, paymentIntentId, customerId)
    }
}

enum StripeServiceError: LocalizedError {
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from payment server"
        }
    }
}
