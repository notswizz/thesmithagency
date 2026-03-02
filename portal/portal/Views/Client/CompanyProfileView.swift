import SwiftUI

struct CompanyProfileView: View {
    let uid: String
    @Bindable var viewModel: ClientViewModel
    @Environment(AuthManager.self) private var authManager

    @Environment(\.dismiss) private var dismiss
    @State private var showAddContact = false
    @State private var showAddShowroom = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surfacePrimary.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Contacts
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("CONTACTS")
                                    .font(.system(size: 10, weight: .bold))
                                    .tracking(2)
                                    .foregroundStyle(.textTertiary)
                                Spacer()
                                Button {
                                    showAddContact = true
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundStyle(.brand)
                                }
                            }

                            if viewModel.contacts.isEmpty {
                                Text("No contacts added")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.textTertiary)
                                    .padding(.vertical, 8)
                            } else {
                                ForEach(viewModel.contacts) { contact in
                                    contactRow(contact)
                                }
                            }
                        }
                        .padding(18)
                        .background(Color.surfaceCard)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.borderSubtle))
                        .padding(.horizontal, 20)

                        // Showrooms
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("SHOWROOMS")
                                    .font(.system(size: 10, weight: .bold))
                                    .tracking(2)
                                    .foregroundStyle(.textTertiary)
                                Spacer()
                                Button {
                                    showAddShowroom = true
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundStyle(.brand)
                                }
                            }

                            if viewModel.showrooms.isEmpty {
                                Text("No showrooms added")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.textTertiary)
                                    .padding(.vertical, 8)
                            } else {
                                ForEach(viewModel.showrooms) { showroom in
                                    showroomRow(showroom)
                                }
                            }
                        }
                        .padding(18)
                        .background(Color.surfaceCard)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.borderSubtle))
                        .padding(.horizontal, 20)

                        // Sign out
                        Button {
                            authManager.signOut()
                        } label: {
                            Text("Sign Out")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.textTertiary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .padding(.horizontal, 20)

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Company")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.textSecondary)
                    }
                }
            }
            .refreshable {
                await viewModel.loadClient(uid: uid)
            }
            .sheet(isPresented: $showAddContact) {
                AddContactSheet(clientId: uid, viewModel: viewModel)
            }
            .sheet(isPresented: $showAddShowroom) {
                AddShowroomSheet(clientId: uid, viewModel: viewModel)
            }
        }
    }

    private func contactRow(_ contact: Contact) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(contact.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.textPrimary)
                Spacer()
                if let id = contact.id {
                    Button {
                        Task { await viewModel.deleteContact(id: id) }
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundStyle(.red.opacity(0.7))
                    }
                }
            }
            Text(contact.role)
                .font(.system(size: 12))
                .foregroundStyle(.brand)
            HStack(spacing: 14) {
                if !contact.email.isEmpty {
                    Label(contact.email, systemImage: "envelope")
                }
                if !contact.phone.isEmpty {
                    Label(contact.phone, systemImage: "phone")
                }
            }
            .font(.system(size: 11))
            .foregroundStyle(.textTertiary)
        }
        .padding(14)
        .background(Color.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func showroomRow(_ showroom: Showroom) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(showroom.city)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.textPrimary)
                Text("Bldg \(showroom.buildingNumber), Floor \(showroom.floorNumber), Booth \(showroom.boothNumber)")
                    .font(.system(size: 12))
                    .foregroundStyle(.textTertiary)
            }
            Spacer()
            if let id = showroom.id {
                Button {
                    Task { await viewModel.deleteShowroom(id: id) }
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundStyle(.red.opacity(0.7))
                }
            }
        }
        .padding(14)
        .background(Color.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Add Contact Sheet
struct AddContactSheet: View {
    let clientId: String
    @Bindable var viewModel: ClientViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surfacePrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 12) {
                        TextField("Name", text: $name)
                            .modifier(DarkFieldStyle(label: "Name"))
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .modifier(DarkFieldStyle(label: "Email"))
                        TextField("Phone", text: $phone)
                            .keyboardType(.phonePad)
                            .modifier(DarkFieldStyle(label: "Phone"))
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Add Contact")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
            .tint(.brand)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let contact = Contact(
                            clientId: clientId,
                            name: name,
                            email: email,
                            phone: phone
                        )
                        Task {
                            await viewModel.addContact(contact)
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty)
                    .foregroundStyle(name.isEmpty ? .textTertiary : .brand)
                }
            }
        }
    }
}

// MARK: - Add Showroom Sheet
struct AddShowroomSheet: View {
    let clientId: String
    @Bindable var viewModel: ClientViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var city = ""
    @State private var buildingNumber = ""
    @State private var floorNumber = ""
    @State private var boothNumber = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surfacePrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("CITY")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(1)
                                .foregroundStyle(.textTertiary)
                            HStack {
                                ForEach(AppConstants.locations, id: \.self) { loc in
                                    Button {
                                        city = loc
                                    } label: {
                                        Text(loc)
                                            .font(.system(size: 13, weight: .semibold))
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 10)
                                            .background(city == loc ? Color.brand : Color.surfaceElevated)
                                            .foregroundStyle(city == loc ? .white : .textSecondary)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .strokeBorder(city == loc ? Color.brand : Color.borderSubtle)
                                            )
                                    }
                                }
                            }
                        }
                        TextField("Building Number", text: $buildingNumber)
                            .modifier(DarkFieldStyle(label: "Building Number"))
                        TextField("Floor Number", text: $floorNumber)
                            .modifier(DarkFieldStyle(label: "Floor Number"))
                        TextField("Booth Number", text: $boothNumber)
                            .modifier(DarkFieldStyle(label: "Booth Number"))
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Add Showroom")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
            .tint(.brand)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let showroom = Showroom(
                            clientId: clientId,
                            city: city,
                            buildingNumber: buildingNumber,
                            floorNumber: floorNumber,
                            boothNumber: boothNumber
                        )
                        Task {
                            await viewModel.addShowroom(showroom)
                            dismiss()
                        }
                    }
                    .disabled(city.isEmpty)
                    .foregroundStyle(city.isEmpty ? .textTertiary : .brand)
                }
            }
        }
    }
}
