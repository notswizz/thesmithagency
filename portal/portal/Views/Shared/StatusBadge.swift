import SwiftUI

struct StatusBadge: View {
    let status: String

    private var color: Color {
        switch status.lowercased() {
        case "booked": return .blue
        case "completed", "paid": return .green
        case "pending", "deposit_paid": return .orange
        case "unpaid": return .red
        case "cancelled": return .red
        case "active", "upcoming": return .brand
        default: return .textTertiary
        }
    }

    var body: some View {
        Text(status.capitalized)
            .font(.system(size: 11, weight: .bold))
            .tracking(0.5)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}
