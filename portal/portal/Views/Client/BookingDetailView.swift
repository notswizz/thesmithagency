import SwiftUI
import FirebaseFirestore

struct BookingDetailView: View {
    let booking: Booking
    let showMap: [String: Show]
    let firestoreService: FirestoreService
    @Environment(\.dismiss) private var dismiss

    @State private var staffMap: [String: Staff] = [:]
    @State private var isLoadingStaff = true
    @State private var listener: ListenerRegistration?
    @State private var appearAnimation = false
    @State private var showCancelAlert = false
    @State private var isCancelling = false

    private var allStaffIds: [String] {
        let ids = (booking.datesNeeded ?? []).flatMap { $0.staffIds ?? [] }
        return Array(Set(ids))
    }

    private var show: Show? {
        showMap[booking.showId ?? ""]
    }

    private var sortedDates: [DateNeed] {
        (booking.datesNeeded ?? []).sorted { ($0.date ?? "") < ($1.date ?? "") }
    }

    private var totalAssigned: Int {
        sortedDates.reduce(0) { $0 + ($1.staffIds?.filter { !$0.isEmpty }.count ?? 0) }
    }

    private var totalNeeded: Int {
        sortedDates.reduce(0) { $0 + ($1.staffCount ?? 0) }
    }

    private var fillRatio: Double {
        totalNeeded > 0 ? Double(totalAssigned) / Double(totalNeeded) : 0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surfacePrimary.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {

                        // ── Hero ─────────────────────────────────
                        VStack(spacing: 14) {
                            // Status pill at top
                            HStack(spacing: 8) {
                                StatusBadge(status: booking.status ?? "pending")
                                if let payment = booking.paymentStatus, !payment.isEmpty {
                                    StatusBadge(status: payment)
                                }
                            }
                            .scaleEffect(appearAnimation ? 1 : 0.9)
                            .opacity(appearAnimation ? 1 : 0)

                            Text(booking.displayName)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(.textPrimary)
                                .multilineTextAlignment(.center)

                            if let show {
                                Text(DateHelper.dateRange(show.startDate ?? "", show.endDate ?? ""))
                                    .font(.system(size: 13))
                                    .foregroundStyle(.textTertiary)
                            }
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 24)
                        .padding(.horizontal, 20)

                        Spacer().frame(height: 4)

                        // ── Cards ────────────────────────────────
                        VStack(spacing: 16) {

                            // MARK: - Contact & Showroom
                            if booking.contactName != nil || booking.showroomCity != nil {
                                detailCard(icon: "person.crop.circle", title: "BOOKING DETAILS") {
                                    if let name = booking.contactName {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text("Primary Show Contact")
                                                .font(.system(size: 11, weight: .semibold))
                                                .foregroundStyle(.textTertiary)
                                                .tracking(0.5)
                                            HStack(spacing: 10) {
                                                ZStack {
                                                    Circle()
                                                        .fill(Color.brand.opacity(0.12))
                                                        .frame(width: 36, height: 36)
                                                    Image(systemName: "person.fill")
                                                        .font(.system(size: 14))
                                                        .foregroundStyle(.brand)
                                                }
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(name)
                                                        .font(.system(size: 14, weight: .semibold))
                                                        .foregroundStyle(.textPrimary)
                                                    if let phone = booking.contactPhone, !phone.isEmpty {
                                                        Text(phone)
                                                            .font(.system(size: 12))
                                                            .foregroundStyle(.textTertiary)
                                                    }
                                                    if let email = booking.contactEmail, !email.isEmpty {
                                                        Text(email)
                                                            .font(.system(size: 12))
                                                            .foregroundStyle(.textTertiary)
                                                    }
                                                }
                                            }
                                        }

                                        if booking.showroomCity != nil {
                                            Divider().overlay(Color.borderSubtle)
                                        }
                                    }

                                    if let city = booking.showroomCity {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text("Showroom")
                                                .font(.system(size: 11, weight: .semibold))
                                                .foregroundStyle(.textTertiary)
                                                .tracking(0.5)
                                            HStack(spacing: 10) {
                                                ZStack {
                                                    Circle()
                                                        .fill(Color.brand.opacity(0.12))
                                                        .frame(width: 36, height: 36)
                                                    Image(systemName: "building.2.fill")
                                                        .font(.system(size: 14))
                                                        .foregroundStyle(.brand)
                                                }
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(city)
                                                        .font(.system(size: 14, weight: .semibold))
                                                        .foregroundStyle(.textPrimary)
                                                    if let loc = booking.showroomLocation {
                                                        Text(loc)
                                                            .font(.system(size: 12))
                                                            .foregroundStyle(.textTertiary)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // MARK: - Daily Breakdown
                            if !sortedDates.isEmpty {
                                detailCard(icon: "person.3.fill", title: "STAFF ASSIGNMENTS") {
                                    ForEach(Array(sortedDates.enumerated()), id: \.element.date) { index, dateNeed in
                                        let staffIds = (dateNeed.staffIds ?? []).filter { !$0.isEmpty }
                                        let needed = dateNeed.staffCount ?? 0
                                        let filled = staffIds.count
                                        let isFull = filled >= needed

                                        VStack(alignment: .leading, spacing: 10) {
                                            // Date header row
                                            HStack {
                                                Text(DateHelper.display(dateNeed.date ?? ""))
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundStyle(.textPrimary)
                                                Spacer()
                                                Text("\(filled)/\(needed)")
                                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 4)
                                                    .foregroundStyle(isFull ? .green : .orange)
                                                    .background((isFull ? Color.green : Color.orange).opacity(0.12))
                                                    .clipShape(Capsule())
                                            }

                                            // Progress bar
                                            GeometryReader { geo in
                                                ZStack(alignment: .leading) {
                                                    Capsule()
                                                        .fill(Color.surfacePrimary)
                                                        .frame(height: 4)
                                                    Capsule()
                                                        .fill(
                                                            LinearGradient(
                                                                colors: isFull ? [.green, .green.opacity(0.7)] : [.brand, .brand.opacity(0.6)],
                                                                startPoint: .leading,
                                                                endPoint: .trailing
                                                            )
                                                        )
                                                        .frame(width: needed > 0 ? geo.size.width * CGFloat(filled) / CGFloat(needed) : 0, height: 4)
                                                }
                                            }
                                            .frame(height: 4)

                                            // Staff list
                                            if staffIds.isEmpty {
                                                HStack(spacing: 6) {
                                                    Image(systemName: "clock")
                                                        .font(.system(size: 11))
                                                    Text("Awaiting staff assignment")
                                                        .font(.system(size: 12))
                                                }
                                                .foregroundStyle(.textTertiary)
                                                .padding(.vertical, 4)
                                            } else {
                                                VStack(spacing: 6) {
                                                    ForEach(staffIds, id: \.self) { staffId in
                                                        HStack(spacing: 10) {
                                                            staffAvatar(staffId)
                                                            staffNameView(staffId)
                                                            Spacer()
                                                            Image(systemName: "checkmark.circle.fill")
                                                                .foregroundStyle(.green)
                                                                .font(.system(size: 14))
                                                        }
                                                        .padding(.vertical, 2)
                                                    }
                                                }
                                            }
                                        }
                                        .padding(14)
                                        .background(Color.surfaceElevated)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))

                                        if index < sortedDates.count - 1 {
                                            Spacer().frame(height: 4)
                                        }
                                    }
                                }
                            }

                            // MARK: - Notes
                            if let notes = booking.notes, !notes.isEmpty {
                                detailCard(icon: "note.text", title: "NOTES") {
                                    Text(notes)
                                        .font(.system(size: 14))
                                        .foregroundStyle(.textSecondary)
                                        .lineSpacing(5)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }

                            // MARK: - Pricing
                            if let rate = booking.dailyRate, rate > 0 {
                                detailCard(icon: "dollarsign.circle.fill", title: "PRICING") {
                                    VStack(spacing: 10) {
                                        pricingRow(label: "Market Rate", value: MarketPricing.rateDescription(for: booking.market ?? "other"))
                                        pricingRow(label: "Staff Days", value: "\(booking.totalStaffDays ?? 0)")
                                        Divider().overlay(Color.borderSubtle)
                                        pricingRow(label: "Total", value: MarketPricing.formatCents(booking.estimatedTotal ?? 0), bold: true)
                                        pricingRow(label: "Deposit Paid", value: "-\(MarketPricing.formatCents(booking.depositAmount ?? 0))")
                                        Divider().overlay(Color.borderSubtle)

                                        if booking.paymentStatus == "paid", let final_ = booking.finalAmount {
                                            pricingRow(label: "Final Charged", value: MarketPricing.formatCents(final_), bold: true, highlight: true)
                                        } else {
                                            pricingRow(label: "Balance Due", value: MarketPricing.formatCents(booking.balanceDue ?? 0), bold: true, highlight: true)
                                        }
                                    }
                                }
                            }

                            // MARK: - Payment Status
                            detailCard(icon: "creditcard.fill", title: "PAYMENT") {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(paymentStatusLabel)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundStyle(paymentStatusColor)
                                        Text(paymentStatusDetail)
                                            .font(.system(size: 12))
                                            .foregroundStyle(.textTertiary)
                                    }
                                    Spacer()
                                    Image(systemName: paymentStatusIcon)
                                        .font(.system(size: 20))
                                        .foregroundStyle(paymentStatusColor)
                                }
                            }

                            // MARK: - Cancel Button
                            if canCancel {
                                VStack(spacing: 8) {
                                    let days = CancellationPolicy.daysUntil(showStartDate: show?.startDate ?? "")
                                    let rate = booking.dailyRate ?? MarketPricing.dailyRate(for: booking.market ?? "other")

                                    Text(CancellationPolicy.policyDescription(daysUntilShow: days, dailyRate: rate))
                                        .font(.system(size: 12))
                                        .foregroundStyle(.textTertiary)

                                    Button {
                                        showCancelAlert = true
                                    } label: {
                                        if isCancelling {
                                            ProgressView().tint(.red)
                                        } else {
                                            HStack(spacing: 6) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.system(size: 13))
                                                Text("Cancel Booking")
                                                    .font(.system(size: 15, weight: .semibold))
                                            }
                                        }
                                    }
                                    .foregroundStyle(.red)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.red.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .disabled(isCancelling)
                                }
                                .alert("Cancel Booking?", isPresented: $showCancelAlert) {
                                    Button("Keep Booking", role: .cancel) {}
                                    Button("Cancel Booking", role: .destructive) {
                                        Task { await cancelBooking() }
                                    }
                                } message: {
                                    let days = CancellationPolicy.daysUntil(showStartDate: show?.startDate ?? "")
                                    let rate = booking.dailyRate ?? MarketPricing.dailyRate(for: booking.market ?? "other")
                                    let fee = CancellationPolicy.fee(daysUntilShow: days, dailyRate: rate)
                                    Text("Cancellation fee: \(MarketPricing.formatCents(fee))")
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button { dismiss() } label: {
                        Text("Done")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.brand)
                    }
                }
            }
            .task {
                await loadStaff()
                listenToBooking()
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                    appearAnimation = true
                }
            }
            .onDisappear {
                listener?.remove()
            }
        }
    }

    // MARK: - Detail Card

    private func detailCard<Content: View>(icon: String, title: String, @ViewBuilder content: () -> Content) -> some View {
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

    // MARK: - Stat Items

    private func statItem(value: String, label: String, icon: String, color: Color = .brand) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.textPrimary)
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.textTertiary)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
    }

    private func statDivider() -> some View {
        Rectangle()
            .fill(Color.borderSubtle)
            .frame(width: 1, height: 36)
    }

    // MARK: - Info Row

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.brand)
                .frame(width: 18)
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(.textTertiary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.textPrimary)
                .multilineTextAlignment(.trailing)
        }
    }

    // MARK: - Staff Avatar

    @ViewBuilder
    private func staffAvatar(_ staffId: String) -> some View {
        if let staff = staffMap[staffId],
           let photoURL = staff.photoURL,
           !photoURL.isEmpty {
            AsyncImage(url: URL(string: photoURL)) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                avatarPlaceholder()
            }
            .frame(width: 32, height: 32)
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(Color.brand.opacity(0.25), lineWidth: 1.5))
        } else {
            avatarPlaceholder()
        }
    }

    private func avatarPlaceholder() -> some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [Color.surfaceElevated, Color.surfacePrimary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 32, height: 32)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.textTertiary)
            )
    }

    @ViewBuilder
    private func staffNameView(_ staffId: String) -> some View {
        if let staff = staffMap[staffId] {
            Text(staff.name ?? "Staff")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.textPrimary)
        } else if isLoadingStaff {
            ProgressView()
                .scaleEffect(0.6)
        } else {
            Text("Staff Member")
                .font(.system(size: 13))
                .foregroundStyle(.textTertiary)
        }
    }

    // MARK: - Pricing Row

    private func pricingRow(label: String, value: String, bold: Bool = false, highlight: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: bold ? .semibold : .regular))
                .foregroundStyle(bold ? .textPrimary : .textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: bold ? .bold : .medium, design: .rounded))
                .foregroundStyle(highlight ? .brand : .textPrimary)
        }
    }

    // MARK: - Payment Status

    private var paymentStatusLabel: String {
        switch booking.paymentStatus {
        case "paid": return "Fully Paid"
        case "deposit_paid": return "Deposit Paid"
        default: return "Unpaid"
        }
    }

    private var paymentStatusColor: Color {
        switch booking.paymentStatus {
        case "paid": return .green
        case "deposit_paid": return .orange
        default: return .red
        }
    }

    private var paymentStatusIcon: String {
        switch booking.paymentStatus {
        case "paid": return "checkmark.seal.fill"
        case "deposit_paid": return "clock.fill"
        default: return "exclamationmark.circle.fill"
        }
    }

    private var paymentStatusDetail: String {
        switch booking.paymentStatus {
        case "paid": return "Final balance has been charged"
        case "deposit_paid":
            let balance = booking.balanceDue ?? 0
            return balance > 0 ? "Balance of \(MarketPricing.formatCents(balance)) due after show" : "Deposit collected"
        default: return "No payment received"
        }
    }

    // MARK: - Cancellation

    private var canCancel: Bool {
        let status = booking.status ?? ""
        return status != "cancelled" && status != "completed"
    }

    private func cancelBooking() async {
        guard let bookingId = booking.id else { return }
        isCancelling = true
        let days = CancellationPolicy.daysUntil(showStartDate: show?.startDate ?? "")
        let rate = booking.dailyRate ?? MarketPricing.dailyRate(for: booking.market ?? "other")
        let fee = CancellationPolicy.fee(daysUntilShow: days, dailyRate: rate)
        do {
            try await firestoreService.cancelBooking(bookingId: bookingId, cancellationFee: fee)
            dismiss()
        } catch {
            isCancelling = false
        }
    }

    // MARK: - Data Loading

    private func loadStaff() async {
        guard !allStaffIds.isEmpty else {
            isLoadingStaff = false
            return
        }
        do {
            staffMap = try await firestoreService.fetchStaffByIds(allStaffIds)
        } catch { /* show what we have */ }
        isLoadingStaff = false
    }

    private func listenToBooking() {
        guard let bookingId = booking.id else { return }
        listener = Firestore.firestore().collection("bookings").document(bookingId)
            .addSnapshotListener { snapshot, _ in
                guard let snapshot, let updated = try? snapshot.data(as: Booking.self) else { return }
                let newIds = (updated.datesNeeded ?? []).flatMap { $0.staffIds ?? [] }
                let unknownIds = newIds.filter { staffMap[$0] == nil }
                if !unknownIds.isEmpty {
                    Task {
                        if let newStaff = try? await firestoreService.fetchStaffByIds(unknownIds) {
                            staffMap.merge(newStaff) { _, new in new }
                        }
                    }
                }
            }
    }
}
