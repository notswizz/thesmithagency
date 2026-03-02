import Foundation

enum MarketPricing {
    static let rates: [String: Int] = [
        "atlanta": 30000,  // $300 in cents
        "dallas": 32500,   // $325 in cents
        "other": 35000     // $350 in cents
    ]

    static let depositAmount: Int = 10000  // $100 in cents

    static func dailyRate(for market: String) -> Int {
        return rates[market.lowercased()] ?? rates["other"]!
    }

    static func totalCost(market: String, staffDays: Int) -> Int {
        return dailyRate(for: market) * staffDays
    }

    static func balanceDue(market: String, staffDays: Int) -> Int {
        return totalCost(market: market, staffDays: staffDays) - depositAmount
    }

    static func marketDisplayName(_ market: String) -> String {
        switch market.lowercased() {
        case "atlanta": return "Atlanta"
        case "dallas": return "Dallas"
        default: return "Other"
        }
    }

    static func formatCents(_ cents: Int) -> String {
        return String(format: "$%.2f", Double(cents) / 100.0)
    }

    static func rateDescription(for market: String) -> String {
        let rate = dailyRate(for: market)
        return "\(formatCents(rate))/day (\(marketDisplayName(market)))"
    }
}
