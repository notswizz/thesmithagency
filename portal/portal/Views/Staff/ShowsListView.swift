import SwiftUI

struct ShowsListView: View {
    let uid: String
    @Bindable var viewModel: AvailabilityViewModel
    var bookingVM: BookingViewModel
    var staffVM: StaffViewModel

    @State private var selectedShow: Show?

    private var bookedShowIds: Set<String> {
        Set(bookingVM.bookings.compactMap { booking in
            let isStaffBooked = (booking.datesNeeded ?? []).contains { ($0.staffIds ?? []).contains(uid) }
            return isStaffBooked ? booking.showId : nil
        })
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surfacePrimary.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Header
                        HStack {
                            Text("Shows")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(.textPrimary)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 8)

                        // Location filter
                        if !viewModel.availableLocations.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    filterChip("All", isSelected: viewModel.locationFilter == nil) {
                                        viewModel.locationFilter = nil
                                    }
                                    ForEach(viewModel.availableLocations, id: \.self) { loc in
                                        filterChip(loc, isSelected: viewModel.locationFilter == loc) {
                                            viewModel.locationFilter = loc
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                            .padding(.top, 8)
                            .padding(.bottom, 16)
                        }

                        if viewModel.filteredShows.isEmpty && !viewModel.isLoading {
                            EmptyStateView(
                                icon: "calendar.badge.exclamationmark",
                                title: "No Upcoming Shows",
                                message: "Check back later for new show listings."
                            )
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.filteredShows) { show in
                                    Button {
                                        selectedShow = show
                                    } label: {
                                        showCard(show)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarHidden(true)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .refreshable {
                await viewModel.loadShows(staffId: uid, staffLocation: staffVM.staff?.location)
                await bookingVM.loadStaffBookings(staffId: uid)
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView().tint(.brand)
                }
            }
            .sheet(item: $selectedShow) { show in
                ShowDetailView(
                    show: show,
                    uid: uid,
                    staffName: staffVM.staff?.name ?? "",
                    availabilityVM: viewModel,
                    bookingVM: bookingVM
                )
            }
        }
    }

    private func filterChip(_ label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label.uppercased())
                .font(.system(size: 11, weight: .bold))
                .tracking(0.5)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.brand : Color.surfaceCard)
                .foregroundStyle(isSelected ? .white : Color.textSecondary)
                .clipShape(Capsule())
                .overlay(
                    Capsule().strokeBorder(isSelected ? Color.clear : Color.borderSubtle)
                )
        }
        .buttonStyle(.plain)
    }

    private func showCard(_ show: Show) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Top row: name + badges
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(show.displayName)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.textPrimary)
                    if let season = show.season, !season.isEmpty {
                        Text(season.uppercased())
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(1)
                            .foregroundStyle(.textTertiary)
                    }
                }

                Spacer()

                HStack(spacing: 6) {
                    if let id = show.id, bookedShowIds.contains(id) {
                        Text("BOOKED")
                            .font(.system(size: 9, weight: .black))
                            .tracking(0.5)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.brand)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                    if let id = show.id, viewModel.submittedShowIds.contains(id) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.system(size: 18))
                    }
                }
            }

            // Details
            HStack(spacing: 16) {
                Label(show.city, systemImage: "mappin")
                    .font(.system(size: 13))
                    .foregroundStyle(.textSecondary)
                Label(DateHelper.dateRange(show.startDate ?? "", show.endDate ?? ""), systemImage: "calendar")
                    .font(.system(size: 13))
                    .foregroundStyle(.textSecondary)
            }

            // Bottom accent line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.brand.opacity(0.6), .brand.opacity(0)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
        }
        .padding(18)
        .background(Color.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.borderSubtle)
        )
    }
}
