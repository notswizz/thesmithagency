import SwiftUI
import FirebaseFirestore

struct ClientOnboardingView: View {
    @Environment(AuthManager.self) private var authManager

    let uid: String
    let email: String

    @State private var currentStep = 0
    @State private var isSubmitting = false

    // Contact
    @State private var contactName = ""
    @State private var contactEmail = ""
    @State private var contactPhone = ""

    // Showroom
    @State private var showroomCity = ""
    @State private var buildingNumber = ""
    @State private var floorNumber = ""
    @State private var boothNumber = ""

    private let steps = ["Contact", "Showroom"]

    private var canContinue: Bool {
        switch currentStep {
        case 0: return !contactName.isEmpty && !contactEmail.isEmpty
        case 1: return true
        default: return false
        }
    }

    var body: some View {
        ZStack {
            Color.surfacePrimary.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    header
                    stepIndicator
                    stepContent
                    navigation
                    Spacer(minLength: 40)
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 16) {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 18))

            Text("Complete your profile")
                .font(.system(size: 14))
                .foregroundStyle(.textTertiary)
        }
        .padding(.top, 50)
        .padding(.bottom, 36)
    }

    // MARK: - Step Indicator

    private var stepIndicator: some View {
        HStack(spacing: 0) {
            ForEach(0..<steps.count, id: \.self) { i in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        currentStep = i
                    }
                } label: {
                    Text(steps[i].uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .tracking(0.5)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(currentStep == i ? .white : .textTertiary)
                        .background(currentStep == i ? Color.brand : Color.clear)
                }
            }
        }
        .background(Color.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.borderSubtle))
        .padding(.horizontal, 28)
        .padding(.bottom, 24)
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        VStack(spacing: 12) {
            switch currentStep {
            case 0:
                contactStep
            case 1:
                showroomStep
            default:
                EmptyView()
            }
        }
        .padding(.horizontal, 28)
    }

    private var contactStep: some View {
        VStack(spacing: 12) {
            TextField("Full Name", text: $contactName)
                .modifier(DarkFieldStyle(label: "Name"))
            TextField("Email", text: $contactEmail)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .modifier(DarkFieldStyle(label: "Email"))
            TextField("Phone", text: $contactPhone)
                .keyboardType(.phonePad)
                .modifier(DarkFieldStyle(label: "Phone"))
        }
    }

    private var showroomStep: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("CITY")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(.textTertiary)
                HStack {
                    ForEach(AppConstants.locations, id: \.self) { city in
                        Button {
                            showroomCity = city
                        } label: {
                            Text(city)
                                .font(.system(size: 13, weight: .semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(showroomCity == city ? Color.brand : Color.surfaceElevated)
                                .foregroundStyle(showroomCity == city ? .white : .textSecondary)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .strokeBorder(showroomCity == city ? Color.brand : Color.borderSubtle)
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
    }

    // MARK: - Navigation

    private var navigation: some View {
        VStack(spacing: 12) {
            if currentStep < steps.count - 1 {
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        currentStep += 1
                    }
                } label: {
                    Text("Next")
                        .font(.system(size: 16, weight: .semibold))
                }
                .buttonStyle(.brand)
                .disabled(!canContinue)
                .opacity(canContinue ? 1 : 0.5)
            } else {
                Button {
                    Task { await submit() }
                } label: {
                    if isSubmitting {
                        ProgressView().tint(.white)
                    } else {
                        Text("Complete Setup")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .buttonStyle(.brand)
            }

            if currentStep > 0 {
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        currentStep -= 1
                    }
                } label: {
                    Text("Back")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.textTertiary)
                }
            }

            Button("Sign Out") {
                authManager.signOut()
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.textTertiary)
            .padding(.top, 8)
        }
        .padding(.horizontal, 28)
        .padding(.top, 24)
    }

    // MARK: - Submit

    private func submit() async {
        isSubmitting = true
        defer { isSubmitting = false }

        let db = Firestore.firestore()

        // Save contact
        if !contactName.isEmpty {
            let contact = Contact(
                clientId: uid,
                name: contactName,
                email: contactEmail,
                phone: contactPhone
            )
            try? db.collection("contacts").addDocument(from: contact)
        }

        // Save showroom
        if !showroomCity.isEmpty {
            let showroom = Showroom(
                clientId: uid,
                city: showroomCity,
                buildingNumber: buildingNumber,
                floorNumber: floorNumber,
                boothNumber: boothNumber
            )
            try? db.collection("showrooms").addDocument(from: showroom)
        }

        await authManager.completeClientOnboarding(uid: uid)
    }
}
