import SwiftUI

struct ShowDetailView: View {
    let show: Show
    let uid: String
    let staffName: String
    @Bindable var availabilityVM: AvailabilityViewModel
    var bookingVM: BookingViewModel
    @Environment(\.dismiss) private var dismiss

    private var bookingsForShow: [Booking] {
        bookingVM.bookings.filter { $0.showId == show.id }
    }

    private var myDatesBooked: [String] {
        bookingsForShow.flatMap { booking in
            (booking.datesNeeded ?? [])
                .filter { ($0.staffIds ?? []).contains(uid) }
                .compactMap(\.date)
        }
        .sorted()
    }

    private var hasSubmittedAvailability: Bool {
        availabilityVM.submittedShowIds.contains(show.id ?? "")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surfacePrimary.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Show header
                        VStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(Color.brand.opacity(0.1))
                                    .frame(width: 64, height: 64)
                                Image(systemName: "calendar.badge.clock")
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundStyle(.brand)
                            }

                            Text(show.displayName)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.textPrimary)
                                .multilineTextAlignment(.center)

                            HStack(spacing: 16) {
                                Label(show.city, systemImage: "mappin")
                                Label(DateHelper.dateRange(show.startDate ?? "", show.endDate ?? ""), systemImage: "calendar")
                            }
                            .font(.system(size: 13))
                            .foregroundStyle(.textSecondary)

                            if let season = show.season, !season.isEmpty {
                                Text(season.uppercased())
                                    .font(.system(size: 10, weight: .semibold))
                                    .tracking(1.5)
                                    .foregroundStyle(.textTertiary)
                            }
                        }
                        .padding(.top, 24)

                        // Booking info (if booked)
                        if !myDatesBooked.isEmpty {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack(spacing: 8) {
                                    Image(systemName: "briefcase.fill")
                                        .foregroundStyle(.brand)
                                    Text("YOU'RE BOOKED")
                                        .font(.system(size: 12, weight: .bold))
                                        .tracking(1)
                                        .foregroundStyle(.brand)
                                }

                                Text("Your assigned dates:")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.textSecondary)

                                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                                    ForEach(myDatesBooked, id: \.self) { date in
                                        DateChip(dateString: date, isSelected: true) {}
                                            .disabled(true)
                                    }
                                }

                                if let status = bookingsForShow.first?.status {
                                    HStack {
                                        Text("Status")
                                            .font(.system(size: 12))
                                            .foregroundStyle(.textTertiary)
                                        Spacer()
                                        StatusBadge(status: status)
                                    }
                                }
                            }
                            .padding(18)
                            .background(Color.brand.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(Color.brand.opacity(0.2))
                            )
                            .padding(.horizontal, 20)
                        }

                        // Availability section
                        if hasSubmittedAvailability {
                            submittedSection
                        } else {
                            selectionSection
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.textSecondary)
                    }
                }
            }
            .task {
                await availabilityVM.loadExistingAvailability(staffId: uid, showId: show.id ?? "")
            }
        }
    }

    private var submittedSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 56, height: 56)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.green)
            }

            Text("AVAILABILITY SUBMITTED")
                .font(.system(size: 13, weight: .bold))
                .tracking(1.5)
                .foregroundStyle(.textPrimary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                ForEach(availabilityVM.selectedDates.sorted(), id: \.self) { date in
                    DateChip(dateString: date, isSelected: true) {}
                        .disabled(true)
                }
            }
            .padding(.horizontal, 20)

            Text("Need to make changes?\nEmail Lilian to update your availability.")
                .font(.system(size: 12))
                .foregroundStyle(.textTertiary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        .padding(.vertical, 8)
    }

    private var selectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("SELECT AVAILABLE DATES")
                .font(.system(size: 12, weight: .bold))
                .tracking(1.5)
                .foregroundStyle(.textSecondary)
                .padding(.horizontal, 20)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                ForEach(show.dateRange, id: \.self) { date in
                    DateChip(
                        dateString: date,
                        isSelected: availabilityVM.selectedDates.contains(date)
                    ) {
                        availabilityVM.toggleDate(date)
                    }
                }
            }
            .padding(.horizontal, 20)

            HStack {
                Button("Select All") {
                    for date in show.dateRange {
                        availabilityVM.selectedDates.insert(date)
                    }
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.brand)
                Spacer()
                Button("Clear") {
                    availabilityVM.selectedDates.removeAll()
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.textTertiary)
            }
            .padding(.horizontal, 20)

            Button {
                Task {
                    await availabilityVM.submitAvailability(staffId: uid, staffName: staffName, show: show)
                    dismiss()
                }
            } label: {
                if availabilityVM.isSaving {
                    ProgressView().tint(.white)
                } else {
                    Text("Submit Availability")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .buttonStyle(.brand)
            .disabled(availabilityVM.selectedDates.isEmpty || availabilityVM.isSaving)
            .opacity(availabilityVM.selectedDates.isEmpty ? 0.5 : 1)
            .padding(.horizontal, 20)
        }
    }
}
