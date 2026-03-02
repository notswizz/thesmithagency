import SwiftUI
import StripePaymentSheet

struct BookingReviewView: View {
    let uid: String
    let clientEmail: String
    let clientName: String
    let contact: Contact?
    let showroom: Showroom?
    @Bindable var viewModel: BookingViewModel
    var stripeService: StripeService

    @Environment(\.dismiss) private var dismiss
    @State private var paymentSheet: PaymentSheet?
    @State private var paymentIntentId: String?
    @State private var stripeCustomerId: String?
    @State private var isPreparing = false
    @State private var showPaymentSuccess = false
    @State private var errorMessage: String?
    @State private var appearAnimation = false

    private var selectedShow: Show? {
        guard let id = viewModel.selectedShowId else { return nil }
        return viewModel.showMap[id]
    }

    private var datesNeeded: [DateNeed] {
        viewModel.dateStaffCounts
            .filter { $0.value > 0 }
            .map { DateNeed(date: $0.key, staffCount: $0.value, staffIds: []) }
            .sorted { ($0.date ?? "") < ($1.date ?? "") }
    }

    private var totalStaff: Int {
        datesNeeded.reduce(0) { $0 + ($1.staffCount ?? 0) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surfacePrimary.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {

                        // ── Hero ─────────────────────────────────
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.brand.opacity(0.2), Color.brand.opacity(0.05)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 56, height: 56)
                                Image(systemName: "checkmark.shield.fill")
                                    .font(.system(size: 22, weight: .medium))
                                    .foregroundStyle(.brand)
                            }
                            .scaleEffect(appearAnimation ? 1 : 0.8)
                            .opacity(appearAnimation ? 1 : 0)

                            Text("Review Your Booking")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(.textPrimary)

                            Text("Confirm the details below and pay the deposit")
                                .font(.system(size: 13))
                                .foregroundStyle(.textTertiary)
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 24)

                        VStack(spacing: 16) {

                            // MARK: - Show
                            if let show = selectedShow {
                                reviewCard(icon: "calendar.badge.clock", title: "SHOW") {
                                    HStack(spacing: 12) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(show.displayName)
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundStyle(.textPrimary)
                                            if !show.displayLocation.isEmpty {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "mappin")
                                                        .font(.system(size: 10))
                                                    Text(show.displayLocation)
                                                        .font(.system(size: 13))
                                                }
                                                .foregroundStyle(.textSecondary)
                                            }
                                        }
                                        Spacer()
                                    }
                                }
                            }

                            // MARK: - Contact & Showroom
                            if contact != nil || showroom != nil {
                                reviewCard(icon: "person.crop.circle", title: "BOOKING DETAILS") {
                                    if let contact {
                                        HStack(spacing: 10) {
                                            ZStack {
                                                Circle()
                                                    .fill(Color.brand.opacity(0.1))
                                                    .frame(width: 32, height: 32)
                                                Image(systemName: "person.fill")
                                                    .font(.system(size: 12))
                                                    .foregroundStyle(.brand)
                                            }
                                            VStack(alignment: .leading, spacing: 1) {
                                                Text(contact.name)
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundStyle(.textPrimary)
                                                if !contact.role.isEmpty {
                                                    Text(contact.role)
                                                        .font(.system(size: 12))
                                                        .foregroundStyle(.brand)
                                                }
                                            }
                                            Spacer()
                                        }
                                    }

                                    if contact != nil && showroom != nil {
                                        Divider().overlay(Color.borderSubtle)
                                    }

                                    if let showroom {
                                        HStack(spacing: 10) {
                                            ZStack {
                                                Circle()
                                                    .fill(Color.brand.opacity(0.1))
                                                    .frame(width: 32, height: 32)
                                                Image(systemName: "building.2.fill")
                                                    .font(.system(size: 12))
                                                    .foregroundStyle(.brand)
                                            }
                                            VStack(alignment: .leading, spacing: 1) {
                                                Text(showroom.city)
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundStyle(.textPrimary)
                                                Text("Bldg \(showroom.buildingNumber), Floor \(showroom.floorNumber)")
                                                    .font(.system(size: 12))
                                                    .foregroundStyle(.textTertiary)
                                            }
                                            Spacer()
                                        }
                                    }
                                }
                            }

                            // MARK: - Dates & Staff
                            reviewCard(icon: "person.3.fill", title: "SCHEDULE") {
                                VStack(spacing: 0) {
                                    ForEach(Array(datesNeeded.enumerated()), id: \.element.date) { index, dn in
                                        HStack {
                                            Text(DateHelper.display(dn.date ?? ""))
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundStyle(.textPrimary)
                                            Spacer()
                                            HStack(spacing: 4) {
                                                Image(systemName: "person.fill")
                                                    .font(.system(size: 10))
                                                Text("\(dn.staffCount ?? 0)")
                                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                            }
                                            .foregroundStyle(.brand)
                                        }
                                        .padding(.vertical, 11)

                                        if index < datesNeeded.count - 1 {
                                            Divider().overlay(Color.borderSubtle)
                                        }
                                    }
                                }

                                // Total
                                HStack {
                                    Text("Total Staff Days")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(.textTertiary)
                                    Spacer()
                                    Text("\(totalStaff)")
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundStyle(.textPrimary)
                                }
                                .padding(.top, 8)
                            }

                            // MARK: - Deposit
                            VStack(spacing: 0) {
                                // Gradient accent line
                                LinearGradient(
                                    colors: [.brand, .brandDark],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .frame(height: 3)
                                .clipShape(RoundedRectangle(cornerRadius: 2))

                                VStack(spacing: 12) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Deposit")
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundStyle(.textTertiary)
                                            Text("$100.00")
                                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                                .foregroundStyle(.textPrimary)
                                        }
                                        Spacer()
                                        ZStack {
                                            Circle()
                                                .fill(Color.brand.opacity(0.12))
                                                .frame(width: 52, height: 52)
                                            Image(systemName: "creditcard.fill")
                                                .font(.system(size: 20))
                                                .foregroundStyle(.brand)
                                        }
                                    }

                                    Text("Your card will be saved securely. The remaining balance is charged after the show completes.")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.textTertiary)
                                        .lineSpacing(3)
                                }
                                .padding(18)
                            }
                            .background(Color.surfaceCard)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.borderSubtle))
                        }
                        .padding(.horizontal, 20)

                        // ── CTA ──────────────────────────────────
                        VStack(spacing: 12) {
                            if let error = errorMessage {
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 12))
                                    Text(error)
                                        .font(.system(size: 13))
                                }
                                .foregroundStyle(.red)
                            }

                            Button {
                                Task { await prepareAndPay() }
                            } label: {
                                if isPreparing || viewModel.isSaving {
                                    HStack(spacing: 8) {
                                        ProgressView().tint(.white)
                                        Text("Processing...")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                } else {
                                    HStack(spacing: 8) {
                                        Image(systemName: "lock.fill")
                                            .font(.system(size: 13))
                                        Text("Pay $100 & Confirm Booking")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                }
                            }
                            .buttonStyle(.brand)
                            .disabled(isPreparing || viewModel.isSaving)

                            HStack(spacing: 4) {
                                Image(systemName: "lock.shield.fill")
                                    .font(.system(size: 10))
                                Text("Secured by Stripe")
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .foregroundStyle(.textTertiary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.textSecondary)
                    }
                }
            }
            .navigationDestination(isPresented: $showPaymentSuccess) {
                PaymentSuccessView(showName: selectedShow?.displayName ?? "your show")
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                    appearAnimation = true
                }
            }
        }
    }

    // MARK: - Review Card

    private func reviewCard<Content: View>(icon: String, title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.brand)
                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(.textTertiary)
            }
            VStack(alignment: .leading, spacing: 12) {
                content()
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.borderSubtle))
    }

    // MARK: - Payment Logic

    private func prepareAndPay() async {
        isPreparing = true
        errorMessage = nil

        do {
            let result = try await stripeService.preparePaymentSheet(
                clientId: uid,
                clientEmail: clientEmail,
                clientName: clientName
            )
            paymentSheet = result.paymentSheet
            paymentIntentId = result.paymentIntentId
            stripeCustomerId = result.customerId
            isPreparing = false

            guard let sheet = paymentSheet else { return }
            await presentPaymentSheet(sheet)
        } catch {
            isPreparing = false
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func presentPaymentSheet(_ sheet: PaymentSheet) async {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            errorMessage = "Unable to present payment sheet"
            return
        }

        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }

        sheet.present(from: topVC) { [self] result in
            switch result {
            case .completed:
                Task { await submitBookingAfterPayment() }
            case .failed(let error):
                self.errorMessage = error.localizedDescription
            case .canceled:
                self.errorMessage = nil
            }
        }
    }

    private func submitBookingAfterPayment() async {
        await viewModel.submitBooking(
            clientId: uid,
            contact: contact,
            showroom: showroom,
            paymentStatus: "deposit_paid",
            depositAmount: 10000,
            stripePaymentIntentId: paymentIntentId,
            stripeCustomerId: stripeCustomerId
        )

        if viewModel.errorMessage == nil {
            showPaymentSuccess = true
        } else {
            errorMessage = viewModel.errorMessage
        }
    }
}
