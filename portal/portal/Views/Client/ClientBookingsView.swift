import SwiftUI

struct ClientBookingsView: View {
    let uid: String
    var viewModel: BookingViewModel
    var firestoreService: FirestoreService
    var onCompanyTap: (() -> Void)? = nil
    var onNewBooking: (() -> Void)? = nil

    @State private var selectedBooking: Booking?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surfacePrimary.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Header
                        HStack {
                            Text("My Bookings")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(.textPrimary)
                            Spacer()
                            if let onCompanyTap {
                                Button {
                                    onCompanyTap()
                                } label: {
                                    Image(systemName: "building.2")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(.textSecondary)
                                        .frame(width: 36, height: 36)
                                        .background(Color.surfaceCard)
                                        .clipShape(Circle())
                                        .overlay(Circle().strokeBorder(Color.borderSubtle))
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                        let upcoming = viewModel.upcomingBookings
                        if !upcoming.isEmpty {
                            bookingSection(title: "UPCOMING", bookings: upcoming)
                        }

                        let past = viewModel.pastBookings
                        if !past.isEmpty {
                            bookingSection(title: "PAST", bookings: past)
                        }

                        if viewModel.bookings.isEmpty && !viewModel.isLoading {
                            emptyState
                        }

                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationBarHidden(true)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .refreshable {
                await viewModel.loadClientBookings(clientId: uid)
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView().tint(.brand)
                }
            }
            .sheet(item: $selectedBooking) { booking in
                BookingDetailView(booking: booking, showMap: viewModel.showMap, firestoreService: firestoreService)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 40)

            ZStack {
                Circle()
                    .fill(Color.brand.opacity(0.08))
                    .frame(width: 100, height: 100)
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(.brand.opacity(0.6))
            }

            VStack(spacing: 8) {
                Text("No Bookings Yet")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.textPrimary)

                Text("Tap the + button below to book staff\nfor your next show")
                    .font(.system(size: 14))
                    .foregroundStyle(.textTertiary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            // Arrow pointing to FAB
            VStack(spacing: 6) {
                Image(systemName: "arrow.down")
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(.brand.opacity(0.4))
            }
            .padding(.top, 12)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 40)
    }

    // MARK: - Section

    private func bookingSection(title: String, bookings: [Booking]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(.textTertiary)

                Capsule()
                    .fill(Color.brand.opacity(0.15))
                    .frame(width: 24, height: 18)
                    .overlay(
                        Text("\(bookings.count)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.brand)
                    )
            }
            .padding(.horizontal, 20)

            LazyVStack(spacing: 10) {
                ForEach(bookings) { booking in
                    Button {
                        selectedBooking = booking
                    } label: {
                        bookingCard(booking)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Booking Card

    private func bookingCard(_ booking: Booking) -> some View {
        let dates = booking.datesNeeded ?? []
        let totalStaff = booking.totalStaffNeeded ?? dates.reduce(0) { $0 + ($1.staffCount ?? 0) }
        let assigned = dates.reduce(0) { $0 + ($1.staffIds?.filter { !$0.isEmpty }.count ?? 0) }
        let needed = dates.reduce(0) { $0 + ($1.staffCount ?? 0) }
        let fillRatio: Double = needed > 0 ? Double(assigned) / Double(needed) : 0

        return VStack(alignment: .leading, spacing: 0) {
            // Top accent line
            LinearGradient(
                colors: [.brand, .brandDark, .brand.opacity(0.3)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 3)

            VStack(alignment: .leading, spacing: 14) {
                // Title + status row
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(booking.displayName)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.textPrimary)
                    }
                    Spacer()
                    StatusBadge(status: booking.status ?? "pending")
                }

                // Stats row
                HStack(spacing: 16) {
                    // Dates
                    HStack(spacing: 5) {
                        Image(systemName: "calendar")
                            .font(.system(size: 11))
                            .foregroundStyle(.brand)
                        Text("\(dates.count) days")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.textSecondary)
                    }

                    // Staff
                    HStack(spacing: 5) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.brand)
                        Text("\(totalStaff) staff")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.textSecondary)
                    }

                    Spacer()

                    // Payment badge
                    if let payment = booking.paymentStatus, !payment.isEmpty, payment != "unpaid" {
                        StatusBadge(status: payment)
                    }
                }

                // Fill progress bar
                if needed > 0 {
                    VStack(spacing: 6) {
                        HStack {
                            Text("Staff Assigned")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.textTertiary)
                                .tracking(0.5)
                            Spacer()
                            Text("\(assigned)/\(needed)")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(fillRatio >= 1 ? .green : .textSecondary)
                        }

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.surfacePrimary)
                                    .frame(height: 4)
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: fillRatio >= 1
                                                ? [.green, .green.opacity(0.7)]
                                                : [.brand, .brand.opacity(0.5)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: max(geo.size.width * fillRatio, 0), height: 4)
                            }
                        }
                        .frame(height: 4)
                    }
                }
            }
            .padding(16)
        }
        .background(Color.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.borderSubtle))
    }
}
