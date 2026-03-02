import Foundation

enum CancellationPolicy {
    /// Returns the cancellation fee in cents based on days until show start
    static func fee(daysUntilShow: Int, dailyRate: Int) -> Int {
        if daysUntilShow >= 30 {
            return 10000  // Forfeit $100 deposit
        } else if daysUntilShow >= 8 {
            return dailyRate  // 1 day's rate
        } else {
            return dailyRate * 2  // 2 days' rates
        }
    }

    static func policyDescription(daysUntilShow: Int, dailyRate: Int) -> String {
        let feeAmount = fee(daysUntilShow: daysUntilShow, dailyRate: dailyRate)
        let dollars = MarketPricing.formatCents(feeAmount)

        if daysUntilShow >= 30 {
            return "Cancellation fee: \(dollars) (deposit forfeiture)"
        } else if daysUntilShow >= 8 {
            return "Cancellation fee: \(dollars) (1 day's rate)"
        } else {
            return "Cancellation fee: \(dollars) (2 days' rates)"
        }
    }

    static func daysUntil(showStartDate: String) -> Int {
        guard let date = DateHelper.date(from: showStartDate) else { return 0 }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: calendar.startOfDay(for: Date()), to: calendar.startOfDay(for: date))
        return max(0, components.day ?? 0)
    }
}
