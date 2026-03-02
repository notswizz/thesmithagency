import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(.brand.opacity(0.6))
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.textPrimary)
            Text(message)
                .font(.system(size: 14))
                .foregroundStyle(.textTertiary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
