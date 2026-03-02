import SwiftUI
import PhotosUI

struct StaffOnboardingView: View {
    let uid: String
    @Environment(AuthManager.self) private var authManager

    @State private var currentStep = 0
    @State private var isSubmitting = false

    // Contact
    @State private var phone = ""
    @State private var location = ""
    @State private var address = ""
    @State private var college = ""
    @State private var instagram = ""

    // Sizing
    @State private var dressSize = ""
    @State private var shoeSize = ""

    // Experience
    @State private var experience = ""

    private let steps = ["Contact", "Sizing", "Experience"]

    private var canContinue: Bool {
        switch currentStep {
        case 0: return !phone.isEmpty && !location.isEmpty
        case 1: return true
        case 2: return true
        default: return false
        }
    }

    var body: some View {
        ZStack {
            Color.surfacePrimary.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.brand.opacity(0.08))
                                .frame(width: 120, height: 120)
                            Circle()
                                .fill(Color.brand.opacity(0.04))
                                .frame(width: 160, height: 160)
                            Image(systemName: "person.crop.circle.badge.plus")
                                .font(.system(size: 40, weight: .medium))
                                .foregroundStyle(.brand)
                        }

                        VStack(spacing: 6) {
                            Text("WELCOME")
                                .font(.system(size: 18, weight: .bold))
                                .tracking(2)
                                .foregroundStyle(.textPrimary)
                            Text("Let's set up your profile")
                                .font(.system(size: 13))
                                .foregroundStyle(.textTertiary)
                        }
                    }
                    .padding(.top, 60)
                    .padding(.bottom, 36)

                    // Step indicator
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

                    // Step content
                    VStack(spacing: 12) {
                        switch currentStep {
                        case 0:
                            TextField("Phone", text: $phone)
                                .keyboardType(.phonePad)
                                .modifier(DarkFieldStyle(label: "Phone"))

                            VStack(alignment: .leading, spacing: 6) {
                                Text("LOCATION")
                                    .font(.system(size: 10, weight: .bold))
                                    .tracking(1)
                                    .foregroundStyle(.textTertiary)
                                HStack {
                                    ForEach(AppConstants.locations, id: \.self) { city in
                                        Button {
                                            location = city
                                        } label: {
                                            Text(city)
                                                .font(.system(size: 13, weight: .semibold))
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 10)
                                                .background(location == city ? Color.brand : Color.surfaceElevated)
                                                .foregroundStyle(location == city ? .white : .textSecondary)
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .strokeBorder(location == city ? Color.brand : Color.borderSubtle)
                                                )
                                        }
                                    }
                                }
                            }

                            AddressSearchField(label: "Address", text: $address)
                            TextField("College", text: $college)
                                .modifier(DarkFieldStyle(label: "College"))
                            TextField("@handle", text: $instagram)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .modifier(DarkFieldStyle(label: "Instagram"))
                        case 1:
                            TextField("Dress Size", text: $dressSize)
                                .modifier(DarkFieldStyle(label: "Dress Size"))
                            TextField("Shoe Size", text: $shoeSize)
                                .modifier(DarkFieldStyle(label: "Shoe Size"))
                        case 2:
                            VStack(alignment: .leading, spacing: 6) {
                                Text("RETAIL/WHOLESALE EXPERIENCE")
                                    .font(.system(size: 10, weight: .bold))
                                    .tracking(1)
                                    .foregroundStyle(.textTertiary)
                                TextEditor(text: $experience)
                                    .font(.system(size: 15))
                                    .foregroundStyle(.textPrimary)
                                    .scrollContentBackground(.hidden)
                                    .frame(minHeight: 120)
                                    .padding(14)
                                    .background(Color.surfaceElevated)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(Color.borderSubtle)
                                    )
                            }
                        default:
                            EmptyView()
                        }
                    }
                    .padding(.horizontal, 28)

                    // Navigation buttons
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
                                Task {
                                    isSubmitting = true
                                    await authManager.completeStaffOnboarding(
                                        uid: uid,
                                        phone: phone,
                                        location: location,
                                        address: address,
                                        college: college,
                                        instagram: instagram,
                                        dressSize: dressSize,
                                        shoeSize: shoeSize,
                                        experience: experience
                                    )
                                    isSubmitting = false
                                }
                            } label: {
                                if isSubmitting {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Complete Profile")
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

                    Spacer(minLength: 40)
                }
            }
        }
    }
}
