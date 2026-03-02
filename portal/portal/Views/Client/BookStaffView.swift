import SwiftUI

struct BookStaffView: View {
    let uid: String
    let clientEmail: String
    let clientName: String
    @Bindable var viewModel: BookingViewModel
    var clientVM: ClientViewModel
    var stripeService: StripeService

    @Environment(\.dismiss) private var dismiss
    @State private var showSuccess = false
    @State private var showReview = false
    @State private var appearAnimation = false

    // New contact form
    @State private var showNewContact = false
    @State private var newContactName = ""
    @State private var newContactEmail = ""
    @State private var newContactPhone = ""
    @State private var newContactRole = ""

    // New showroom form
    @State private var showNewShowroom = false
    @State private var newShowroomCity = ""
    @State private var newShowroomBuilding = ""
    @State private var newShowroomFloor = ""
    @State private var newShowroomBooth = ""

    private var totalStaffRequested: Int {
        viewModel.dateStaffCounts.values.reduce(0, +)
    }

    private var canProceed: Bool {
        viewModel.selectedShowId != nil && totalStaffRequested > 0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surfacePrimary.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {

                        // ── Hero header ──────────────────────────
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.brand.opacity(0.2), Color.brand.opacity(0.05)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 64, height: 64)
                                Image(systemName: "person.2.fill")
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundStyle(.brand)
                            }
                            .scaleEffect(appearAnimation ? 1 : 0.8)
                            .opacity(appearAnimation ? 1 : 0)

                            Text("Book Staff")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(.textPrimary)
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 28)
                        .padding(.horizontal, 40)

                        // ── Sections ─────────────────────────────
                        VStack(spacing: 24) {

                            // MARK: - Show Selection
                            sectionCard(icon: "calendar.badge.clock", title: "SHOW") {
                                Menu {
                                    ForEach(viewModel.shows) { show in
                                        Button {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                viewModel.selectedShowId = show.id
                                                if let id = show.id, let s = viewModel.showMap[id] {
                                                    viewModel.initializeDateCounts(for: s)
                                                }
                                            }
                                        } label: {
                                            Label(show.displayName, systemImage: show.id == viewModel.selectedShowId ? "checkmark" : "")
                                        }
                                    }
                                } label: {
                                    pickerRow(
                                        value: viewModel.selectedShowId.flatMap { viewModel.showMap[$0]?.displayName },
                                        placeholder: "Choose a show"
                                    )
                                }

                                // Show dates if selected
                                if let show = viewModel.selectedShow {
                                    Text(DateHelper.dateRange(show.startDate ?? "", show.endDate ?? ""))
                                        .font(.system(size: 13))
                                        .foregroundStyle(.textTertiary)
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }

                            // MARK: - Primary Show Contact
                            sectionCard(icon: "person.crop.circle", title: "PRIMARY SHOW CONTACT") {
                                if !clientVM.contacts.isEmpty && !showNewContact {
                                    Menu {
                                        ForEach(clientVM.contacts) { contact in
                                            Button {
                                                viewModel.selectedContactId = contact.id
                                            } label: {
                                                Label("\(contact.name) — \(contact.role)", systemImage: contact.id == viewModel.selectedContactId ? "checkmark" : "")
                                            }
                                        }
                                        Divider()
                                        Button {
                                            withAnimation(.easeInOut(duration: 0.25)) { showNewContact = true }
                                        } label: {
                                            Label("Add New Contact", systemImage: "plus")
                                        }
                                    } label: {
                                        pickerRow(
                                            value: selectedContactLabel.contains("—") ? selectedContactLabel : nil,
                                            placeholder: "Select contact"
                                        )
                                    }
                                }

                                if showNewContact || clientVM.contacts.isEmpty {
                                    inlineForm(
                                        title: clientVM.contacts.isEmpty ? nil : "New Contact",
                                        onCancel: clientVM.contacts.isEmpty ? nil : { withAnimation { showNewContact = false } }
                                    ) {
                                        formField("Name", text: $newContactName, icon: "person")
                                        formField("Email", text: $newContactEmail, icon: "envelope", keyboard: .emailAddress)
                                        formField("Phone", text: $newContactPhone, icon: "phone", keyboard: .phonePad)
                                        formField("Role (e.g. Show Manager)", text: $newContactRole, icon: "briefcase")

                                        saveButton("Save Contact", disabled: newContactName.isEmpty) {
                                            await saveNewContact()
                                        }
                                    }
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }

                            // MARK: - Showroom Location
                            sectionCard(icon: "building.2", title: "SHOWROOM LOCATION") {
                                if !clientVM.showrooms.isEmpty && !showNewShowroom {
                                    Menu {
                                        ForEach(clientVM.showrooms) { showroom in
                                            Button {
                                                viewModel.selectedShowroomId = showroom.id
                                            } label: {
                                                Label(
                                                    "\(showroom.city) — Bldg \(showroom.buildingNumber), Fl \(showroom.floorNumber)",
                                                    systemImage: showroom.id == viewModel.selectedShowroomId ? "checkmark" : ""
                                                )
                                            }
                                        }
                                        Divider()
                                        Button {
                                            withAnimation(.easeInOut(duration: 0.25)) { showNewShowroom = true }
                                        } label: {
                                            Label("Add New Showroom", systemImage: "plus")
                                        }
                                    } label: {
                                        pickerRow(
                                            value: selectedShowroomLabel.contains("—") ? selectedShowroomLabel : nil,
                                            placeholder: "Select showroom"
                                        )
                                    }
                                }

                                if showNewShowroom || clientVM.showrooms.isEmpty {
                                    inlineForm(
                                        title: clientVM.showrooms.isEmpty ? nil : "New Showroom",
                                        onCancel: clientVM.showrooms.isEmpty ? nil : { withAnimation { showNewShowroom = false } }
                                    ) {
                                        formField("City", text: $newShowroomCity, icon: "mappin.and.ellipse")
                                        formField("Building Number", text: $newShowroomBuilding, icon: "building")
                                        formField("Floor Number", text: $newShowroomFloor, icon: "arrow.up.to.line")
                                        formField("Booth Number (optional)", text: $newShowroomBooth, icon: "number")

                                        saveButton("Save Showroom", disabled: newShowroomCity.isEmpty || newShowroomBuilding.isEmpty || newShowroomFloor.isEmpty) {
                                            await saveNewShowroom()
                                        }
                                    }
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }

                            // MARK: - Staff Per Day
                            if let show = viewModel.selectedShow {
                                sectionCard(icon: "person.3.fill", title: "STAFF NEEDED PER DAY") {
                                    VStack(spacing: 0) {
                                        ForEach(Array(show.dateRange.enumerated()), id: \.element) { index, date in
                                            let count = viewModel.dateStaffCounts[date] ?? 0

                                            HStack {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(DateHelper.display(date))
                                                        .font(.system(size: 14, weight: .medium))
                                                        .foregroundStyle(.textPrimary)
                                                }

                                                Spacer()

                                                HStack(spacing: 0) {
                                                    Button {
                                                        withAnimation(.easeInOut(duration: 0.15)) {
                                                            if count > 0 { viewModel.dateStaffCounts[date] = count - 1 }
                                                        }
                                                    } label: {
                                                        Image(systemName: "minus")
                                                            .font(.system(size: 12, weight: .bold))
                                                            .foregroundStyle(count > 0 ? .textPrimary : .textTertiary.opacity(0.3))
                                                            .frame(width: 36, height: 36)
                                                            .background(Color.surfacePrimary)
                                                            .clipShape(Circle())
                                                    }
                                                    .disabled(count == 0)

                                                    Text("\(count)")
                                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                                        .foregroundStyle(count > 0 ? .brand : .textTertiary)
                                                        .frame(width: 40)
                                                        .contentTransition(.numericText())

                                                    Button {
                                                        withAnimation(.easeInOut(duration: 0.15)) {
                                                            viewModel.dateStaffCounts[date] = count + 1
                                                        }
                                                    } label: {
                                                        Image(systemName: "plus")
                                                            .font(.system(size: 12, weight: .bold))
                                                            .foregroundStyle(.white)
                                                            .frame(width: 36, height: 36)
                                                            .background(Color.brand)
                                                            .clipShape(Circle())
                                                    }
                                                }
                                            }
                                            .padding(.vertical, 14)
                                            .padding(.horizontal, 4)

                                            if index < show.dateRange.count - 1 {
                                                Divider().overlay(Color.borderSubtle)
                                            }
                                        }
                                    }

                                    // Total summary
                                    if totalStaffRequested > 0 {
                                        HStack {
                                            Text("Total Staff Days")
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundStyle(.textTertiary)
                                            Spacer()
                                            Text("\(totalStaffRequested)")
                                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                                .foregroundStyle(.brand)
                                                .contentTransition(.numericText())
                                        }
                                        .padding(.top, 12)
                                        .padding(.horizontal, 4)
                                        .transition(.opacity)
                                    }
                                }
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                            }

                            // MARK: - Notes
                            sectionCard(icon: "note.text", title: "NOTES") {
                                TextEditor(text: $viewModel.notes)
                                    .font(.system(size: 15))
                                    .foregroundStyle(.textPrimary)
                                    .scrollContentBackground(.hidden)
                                    .frame(minHeight: 80)
                                    .padding(12)
                                    .background(Color.surfacePrimary)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(
                                        Group {
                                            if viewModel.notes.isEmpty {
                                                Text("Any special requests or instructions...")
                                                    .font(.system(size: 15))
                                                    .foregroundStyle(.textTertiary)
                                                    .padding(.leading, 17)
                                                    .padding(.top, 20)
                                                    .allowsHitTesting(false)
                                            }
                                        },
                                        alignment: .topLeading
                                    )
                            }
                        }
                        .padding(.horizontal, 20)

                        // ── Bottom CTA ───────────────────────────
                        VStack(spacing: 12) {
                            if let error = viewModel.errorMessage {
                                Text(error)
                                    .font(.system(size: 13))
                                    .foregroundStyle(.red)
                            }

                            Button {
                                showReview = true
                            } label: {
                                HStack(spacing: 10) {
                                    Text("Review & Pay Deposit")
                                        .font(.system(size: 16, weight: .semibold))
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                            }
                            .buttonStyle(.brand)
                            .disabled(!canProceed)
                            .opacity(canProceed ? 1 : 0.4)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 28)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.textSecondary)
                    }
                }
            }
            .alert("Success", isPresented: $showSuccess) {
                Button("OK") { dismiss() }
            } message: {
                Text("Your booking request has been submitted.")
            }
            .sheet(isPresented: $showReview) {
                BookingReviewView(
                    uid: uid,
                    clientEmail: clientEmail,
                    clientName: clientName,
                    contact: selectedContact,
                    showroom: selectedShowroom,
                    viewModel: viewModel,
                    stripeService: stripeService
                )
            }
            .onChange(of: viewModel.successMessage) { _, newValue in
                if newValue != nil {
                    showReview = false
                    showSuccess = true
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                    appearAnimation = true
                }
            }
        }
    }

    // MARK: - Section Card

    private func sectionCard<Content: View>(icon: String, title: String, @ViewBuilder content: () -> Content) -> some View {
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

    // MARK: - Picker Row

    private func pickerRow(value: String?, placeholder: String) -> some View {
        HStack {
            if let value {
                Text(value)
                    .foregroundStyle(.textPrimary)
            } else {
                Text(placeholder)
                    .foregroundStyle(.textTertiary)
            }
            Spacer()
            Image(systemName: "chevron.up.chevron.down")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.textTertiary)
        }
        .font(.system(size: 15))
        .padding(14)
        .background(Color.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.borderSubtle))
    }

    // MARK: - Inline Form

    private func inlineForm<Content: View>(
        title: String?,
        onCancel: (() -> Void)?,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 12) {
            if let title {
                HStack {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.textPrimary)
                    Spacer()
                    if let onCancel {
                        Button("Cancel", action: onCancel)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.brand)
                    }
                }
            }
            content()
        }
        .padding(14)
        .background(Color.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Form Field

    private func formField(
        _ placeholder: String,
        text: Binding<String>,
        icon: String,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(.textTertiary)
                .frame(width: 18)
            TextField("", text: text, prompt: Text(placeholder).foregroundStyle(.textTertiary.opacity(0.7)))
                .font(.system(size: 15))
                .foregroundStyle(.textPrimary)
                .keyboardType(keyboard)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(Color.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Save Button

    private func saveButton(_ label: String, disabled: Bool, action: @escaping () async -> Void) -> some View {
        Button {
            Task { await action() }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                Text(label)
                    .font(.system(size: 14, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundStyle(disabled ? .textTertiary : .white)
            .background(disabled ? Color.surfacePrimary : Color.brand)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .disabled(disabled)
    }

    // MARK: - Save helpers

    private func saveNewContact() async {
        let contact = Contact(
            clientId: uid,
            name: newContactName,
            email: newContactEmail,
            phone: newContactPhone,
            role: newContactRole
        )
        await clientVM.addContact(contact)
        if let added = clientVM.contacts.last {
            viewModel.selectedContactId = added.id
        }
        newContactName = ""
        newContactEmail = ""
        newContactPhone = ""
        newContactRole = ""
        withAnimation { showNewContact = false }
    }

    private func saveNewShowroom() async {
        let showroom = Showroom(
            clientId: uid,
            city: newShowroomCity,
            buildingNumber: newShowroomBuilding,
            floorNumber: newShowroomFloor,
            boothNumber: newShowroomBooth
        )
        await clientVM.addShowroom(showroom)
        if let added = clientVM.showrooms.last {
            viewModel.selectedShowroomId = added.id
        }
        newShowroomCity = ""
        newShowroomBuilding = ""
        newShowroomFloor = ""
        newShowroomBooth = ""
        withAnimation { showNewShowroom = false }
    }

    // MARK: - Computed properties

    private var selectedContact: Contact? {
        guard let id = viewModel.selectedContactId else { return nil }
        return clientVM.contacts.first(where: { $0.id == id })
    }

    private var selectedShowroom: Showroom? {
        guard let id = viewModel.selectedShowroomId else { return nil }
        return clientVM.showrooms.first(where: { $0.id == id })
    }

    private var selectedShowroomLabel: String {
        if let id = viewModel.selectedShowroomId,
           let showroom = clientVM.showrooms.first(where: { $0.id == id }) {
            return "\(showroom.city) — Bldg \(showroom.buildingNumber)"
        }
        return "Select showroom"
    }

    private var selectedContactLabel: String {
        if let id = viewModel.selectedContactId,
           let contact = clientVM.contacts.first(where: { $0.id == id }) {
            return "\(contact.name) — \(contact.role)"
        }
        return "Select contact"
    }
}
