import SwiftUI

struct LoginView: View {
    @Environment(AuthManager.self) private var authManager

    @State private var showClientLogin = false
    @State private var showClientSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var isSigningIn = false
    @State private var appeared = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.surfacePrimary.ignoresSafeArea()

                // Subtle glow behind logo
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.brand.opacity(0.12), Color.clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 200
                        )
                    )
                    .frame(width: 400, height: 400)
                    .offset(y: -160)
                    .ignoresSafeArea()

                content
            }
            .disabled(isSigningIn)
            .overlay {
                if isSigningIn {
                    Color.black.opacity(0.5).ignoresSafeArea()
                    ProgressView()
                        .tint(.brand)
                        .scaleEffect(1.2)
                }
            }
        }
        .task {
            withAnimation(.easeOut(duration: 0.6)) {
                appeared = true
            }
        }
    }

    private var content: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Logo + branding
                VStack(spacing: 20) {
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .shadow(color: Color.brand.opacity(0.3), radius: 20, y: 8)
                        .scaleEffect(appeared ? 1 : 0.85)
                        .opacity(appeared ? 1 : 0)

                    VStack(spacing: 6) {
                        Text("THE SMITH AGENCY")
                            .font(.system(size: 13, weight: .bold))
                            .tracking(4)
                            .foregroundStyle(.textSecondary)

                        Text("Portal")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.textPrimary)
                    }
                    .opacity(appeared ? 1 : 0)
                }
                .padding(.top, 100)
                .padding(.bottom, 56)

                // Actions
                VStack(spacing: 14) {
                    staffButton
                    divider
                    clientSection
                }
                .padding(.horizontal, 28)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)

                errorMessage

                Spacer(minLength: 60)
            }
        }
    }

    // MARK: - Staff Button

    private var staffButton: some View {
        Button {
            Task {
                isSigningIn = true
                await authManager.signInWithGoogle()
                isSigningIn = false
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "person.badge.shield.checkmark.fill")
                    .font(.system(size: 15))
                Text("Staff Sign In")
                    .font(.system(size: 16, weight: .semibold))
            }
        }
        .buttonStyle(.brand)
    }

    // MARK: - Divider

    private var divider: some View {
        HStack(spacing: 16) {
            Rectangle().fill(Color.borderSubtle).frame(height: 1)
            Text("OR")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.textTertiary)
                .tracking(2)
            Rectangle().fill(Color.borderSubtle).frame(height: 1)
        }
        .padding(.vertical, 16)
    }

    // MARK: - Client Section

    @ViewBuilder
    private var clientSection: some View {
        if showClientLogin {
            clientLoginForm
                .transition(.opacity.combined(with: .move(edge: .bottom)))
        } else {
            Button {
                withAnimation(.spring(response: 0.4)) {
                    showClientLogin = true
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "briefcase.fill")
                        .font(.system(size: 15))
                    Text("Client Login")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(.brand)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.brand.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.brand.opacity(0.2))
                )
            }
        }
    }

    // MARK: - Client Login Form

    private var clientLoginForm: some View {
        VStack(spacing: 14) {
            VStack(spacing: 12) {
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .modifier(DarkFieldStyle(label: "Email"))

                SecureField("Password", text: $password)
                    .textContentType(.password)
                    .modifier(DarkFieldStyle(label: "Password"))
            }

            Button {
                Task {
                    isSigningIn = true
                    await authManager.signInWithEmail(email, password: password)
                    isSigningIn = false
                }
            } label: {
                Text("Sign In")
            }
            .buttonStyle(.brand)
            .disabled(email.isEmpty || password.isEmpty)
            .opacity(email.isEmpty || password.isEmpty ? 0.5 : 1)

            Button("Create an account") {
                showClientSignUp = true
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.brand)
            .padding(.top, 4)
        }
        .sheet(isPresented: $showClientSignUp) {
            ClientSignUpView()
        }
    }

    // MARK: - Error

    @ViewBuilder
    private var errorMessage: some View {
        if let error = authManager.errorMessage {
            Text(error)
                .font(.system(size: 13))
                .foregroundStyle(.red)
                .padding(.horizontal, 28)
                .padding(.top, 16)
        }
    }
}
