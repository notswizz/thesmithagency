import SwiftUI

struct StaffBookingsView: View {
    let uid: String
    var viewModel: BookingViewModel
    var showMap: [String: Show]

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
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                        // Stats row
                        HStack(spacing: 12) {
                            StatCard(
                                title: "Shows",
                                value: "\(viewModel.bookings.count)",
                                icon: "star.fill"
                            )
                            StatCard(
                                title: "Days Booked",
                                value: "\(totalDaysBooked)",
                                icon: "calendar.badge.checkmark"
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                        // Upcoming
                        let upcoming = viewModel.upcomingBookings
                        if !upcoming.isEmpty {
                            sectionBlock(title: "UPCOMING", bookings: upcoming)
                        }

                        // Past
                        let past = viewModel.pastBookings
                        if !past.isEmpty {
                            sectionBlock(title: "PAST", bookings: past)
                        }

                        if viewModel.bookings.isEmpty && !viewModel.isLoading {
                            EmptyStateView(
                                icon: "calendar",
                                title: "No Bookings Yet",
                                message: "Once you're booked for a show, it will appear here."
                            )
                        }

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarHidden(true)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .refreshable {
                await viewModel.loadStaffBookings(staffId: uid)
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView().tint(.brand)
                }
            }
            .sheet(item: $selectedBooking) { booking in
                StaffBookingDetailView(booking: booking, uid: uid, showMap: showMap, clientMap: viewModel.clientMap)
            }
        }
    }

    private var totalDaysBooked: Int {
        viewModel.bookings.flatMap { $0.datesNeeded ?? [] }
            .filter { ($0.staffIds ?? []).contains(uid) }
            .count
    }

    private func sectionBlock(title: String, bookings: [Booking]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .tracking(2)
                .foregroundStyle(.textTertiary)
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

    private func bookingCard(_ booking: Booking) -> some View {
        HStack(spacing: 14) {
            // Pink accent bar
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.brand)
                .frame(width: 3, height: 50)

            VStack(alignment: .leading, spacing: 6) {
                Text(booking.displayName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.textPrimary)

                if let clientName = viewModel.clientMap[booking.clientId ?? ""]?.name, !clientName.isEmpty {
                    Text(clientName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.brand)
                }

                HStack(spacing: 12) {
                    if let show = showMap[booking.showId ?? ""] {
                        Label(show.city, systemImage: "mappin")
                    }
                    let myDates = (booking.datesNeeded ?? [])
                        .filter { ($0.staffIds ?? []).contains(uid) }
                        .compactMap(\.date)
                        .sorted()
                    if !myDates.isEmpty {
                        Label("\(myDates.count)d", systemImage: "calendar")
                    }
                }
                .font(.system(size: 12))
                .foregroundStyle(.textTertiary)
            }

            Spacer()

            StatusBadge(status: booking.status ?? "pending")

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.textTertiary)
        }
        .padding(16)
        .background(Color.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.borderSubtle)
        )
    }
}
