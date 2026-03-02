import SwiftUI

struct ClientSignUpView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var companyName = ""
    @State private var website = ""
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surfacePrimary.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Header
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.brand.opacity(0.1))
                                    .frame(width: 80, height: 80)
                                Image(systemName: "briefcase.fill")
                                    .font(.system(size: 30, weight: .medium))
                                    .foregroundStyle(.brand)
                            }

                            Text("CREATE ACCOUNT")
                                .font(.system(size: 18, weight: .bold))
                                .tracking(2)
                                .foregroundStyle(.textPrimary)
                            Text("Set up your client profile")
                                .font(.system(size: 13))
                                .foregroundStyle(.textTertiary)
                        }
                        .padding(.top, 40)
                        .padding(.bottom, 36)

                        // Form fields
                        VStack(spacing: 12) {
                            TextField("Company Name", text: $companyName)
                                .textContentType(.organizationName)
                                .modifier(DarkFieldStyle(label: "Company Name"))

                            TextField("Website", text: $website)
                                .textContentType(.URL)
                                .keyboardType(.URL)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .modifier(DarkFieldStyle(label: "Website"))

                            TextField("Email", text: $email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .modifier(DarkFieldStyle(label: "Email"))

                            SecureField("Password", text: $password)
                                .textContentType(.newPassword)
                                .modifier(DarkFieldStyle(label: "Password"))
                        }
                        .padding(.horizontal, 28)

                        // Submit
                        Button {
                            Task {
                                isSubmitting = true
                                await authManager.signUpClient(
                                    email: email,
                                    password: password,
                                    companyName: companyName,
                                    website: website
                                )
                                isSubmitting = false
                                dismiss()
                            }
                        } label: {
                            if isSubmitting {
                                ProgressView().tint(.white)
                            } else {
                                Text("Create Account")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .buttonStyle(.brand)
                        .disabled(companyName.isEmpty || email.isEmpty || password.count < 6)
                        .opacity(companyName.isEmpty || email.isEmpty || password.count < 6 ? 0.5 : 1)
                        .padding(.horizontal, 28)
                        .padding(.top, 24)

                        if let error = authManager.errorMessage {
                            Text(error)
                                .font(.system(size: 13))
                                .foregroundStyle(.red)
                                .padding(.horizontal, 28)
                                .padding(.top, 16)
                        }
                    }
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
        }
    }
}
