import SwiftUI

struct DateChip: View {
    let dateString: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Text(dayOfWeek)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : .textTertiary)
                Text(dayNumber)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(isSelected ? .white : .textPrimary)
                Text(month)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : .textTertiary)
            }
            .frame(width: 52, height: 64)
            .background(
                isSelected
                    ? AnyShapeStyle(LinearGradient(colors: [.brand, .brandDark], startPoint: .top, endPoint: .bottom))
                    : AnyShapeStyle(Color.surfaceElevated)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? Color.clear : Color.borderSubtle)
            )
        }
        .buttonStyle(.plain)
    }

    private var parsedDate: Date? { DateHelper.date(from: dateString) }

    private var dayOfWeek: String {
        guard let date = parsedDate else { return "" }
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f.string(from: date).uppercased()
    }

    private var dayNumber: String {
        guard let date = parsedDate else { return "" }
        let f = DateFormatter()
        f.dateFormat = "d"
        return f.string(from: date)
    }

    private var month: String {
        guard let date = parsedDate else { return "" }
        let f = DateFormatter()
        f.dateFormat = "MMM"
        return f.string(from: date).uppercased()
    }
}
