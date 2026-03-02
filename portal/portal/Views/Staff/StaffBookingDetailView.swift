import SwiftUI

struct StaffBookingDetailView: View {
    let booking: Booking
    let uid: String
    let showMap: [String: Show]
    let clientMap: [String: Client]
    @Environment(\.dismiss) private var dismiss

    private var myDates: [DateNeed] {
        (booking.datesNeeded ?? [])
            .filter { ($0.staffIds ?? []).contains(uid) }
            .sorted { ($0.date ?? "") < ($1.date ?? "") }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surfacePrimary.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color.brand.opacity(0.1))
                                    .frame(width: 56, height: 56)
                                Image(systemName: "briefcase.fill")
                                    .font(.system(size: 22, weight: .medium))
                                    .foregroundStyle(.brand)
                            }

                            Text(booking.displayName)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.textPrimary)

                            if let clientName = clientMap[booking.clientId ?? ""]?.name, !clientName.isEmpty {
                                Text(clientName)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.brand)
                            }
                        }
                        .padding(.top, 20)

                        // Show info card
                        VStack(alignment: .leading, spacing: 12) {
                            sectionLabel("SHOW INFO")

                            if let show = showMap[booking.showId ?? ""] {
                                infoRow(icon: "mappin", label: "Location", value: show.displayLocation)
                                if let season = show.season, !season.isEmpty {
                                    infoRow(icon: "leaf", label: "Season", value: season)
                                }
                                infoRow(icon: "calendar", label: "Dates", value: DateHelper.dateRange(show.startDate ?? "", show.endDate ?? ""))
                            }
                        }
                        .padding(18)
                        .background(Color.surfaceCard)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.borderSubtle))
                        .padding(.horizontal, 20)

                        // Client card (shown once booking is confirmed)
                        if booking.status == "booked",
                           let client = clientMap[booking.clientId ?? ""] {
                            VStack(alignment: .leading, spacing: 12) {
                                sectionLabel("YOU'RE WORKING FOR")

                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.brand.opacity(0.1))
                                            .frame(width: 40, height: 40)
                                        Image(systemName: "building.2.fill")
                                            .font(.system(size: 16))
                                            .foregroundStyle(.brand)
                                    }

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(client.name ?? "Client")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundStyle(.textPrimary)
                                        if let website = client.website, !website.isEmpty {
                                            Text(website)
                                                .font(.system(size: 12))
                                                .foregroundStyle(.textTertiary)
                                        }
                                    }

                                    Spacer()
                                }
                            }
                            .padding(18)
                            .background(Color.surfaceCard)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.borderSubtle))
                            .padding(.horizontal, 20)
                        }

                        // My dates card
                        VStack(alignment: .leading, spacing: 12) {
                            sectionLabel("YOUR DATES")

                            if myDates.isEmpty {
                                Text("No specific dates assigned yet")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.textTertiary)
                            } else {
                                ForEach(myDates, id: \.date) { dateNeed in
                                    HStack {
                                        Text(DateHelper.display(dateNeed.date ?? ""))
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundStyle(.textPrimary)
                                        Spacer()
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                    }
                                    if dateNeed.date != myDates.last?.date {
                                        Divider().overlay(Color.borderSubtle)
                                    }
                                }
                            }
                        }
                        .padding(18)
                        .background(Color.surfaceCard)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.borderSubtle))
                        .padding(.horizontal, 20)

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.brand)
                    }
                }
            }
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .tracking(2)
            .foregroundStyle(.textTertiary)
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(.brand)
                .frame(width: 20)
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(.textTertiary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.textPrimary)
        }
    }
}
