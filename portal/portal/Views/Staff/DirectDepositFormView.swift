import SwiftUI

struct DirectDepositFormView: View {
    @Bindable var viewModel: StaffViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showSaved = false
    @State private var isSaving = false
    @State private var appearAnimation = false

    private var maskedAccount: String {
        guard let existing = viewModel.staff?.bankAccountNumber, !existing.isEmpty else { return "" }
        let last4 = String(existing.suffix(4))
        return String(repeating: "•", count: max(0, existing.count - 4)) + last4
    }

    private var isEditing: Bool {
        viewModel.staff?.directDepositCompleted == true
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surfacePrimary.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {

                        // ── Hero ──────────────────────────
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
                                Image(systemName: "banknote.fill")
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundStyle(.brand)
                            }
                            .scaleEffect(appearAnimation ? 1 : 0.8)
                            .opacity(appearAnimation ? 1 : 0)

                            Text("Direct Deposit")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(.textPrimary)

                            Text("Your banking info is stored securely")
                                .font(.system(size: 13))
                                .foregroundStyle(.textTertiary)
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 28)

                        // ── Form ──────────────────────────
                        VStack(spacing: 24) {

                            // Account holder
                            sectionCard(icon: "person.text.rectangle", title: "ACCOUNT HOLDER") {
                                formField("Full legal name", text: $viewModel.bankHolderName, icon: "person")
                            }

                            // Account type
                            sectionCard(icon: "building.columns", title: "ACCOUNT TYPE") {
                                HStack(spacing: 12) {
                                    accountTypeButton("Checking", value: "checking", icon: "checkmark.rectangle")
                                    accountTypeButton("Savings", value: "savings", icon: "banknote")
                                }
                            }

                            // Routing number
                            sectionCard(icon: "arrow.left.arrow.right", title: "ROUTING NUMBER") {
                                formField("9-digit routing number", text: $viewModel.bankRouting, icon: "number", keyboard: .numberPad)

                                if !viewModel.bankRouting.isEmpty && viewModel.bankRouting.count != 9 {
                                    HStack(spacing: 6) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.system(size: 11))
                                        Text("Routing number must be 9 digits")
                                            .font(.system(size: 12))
                                    }
                                    .foregroundStyle(.orange)
                                    .transition(.opacity)
                                }
                            }

                            // Account number
                            sectionCard(icon: "lock.shield", title: "ACCOUNT NUMBER") {
                                formField("Account number", text: $viewModel.bankAccount, icon: "creditcard", keyboard: .numberPad, secure: true)
                                formField("Confirm account number", text: $viewModel.bankAccountConfirm, icon: "checkmark.shield", keyboard: .numberPad, secure: true)

                                if !viewModel.bankAccountConfirm.isEmpty && viewModel.bankAccount != viewModel.bankAccountConfirm {
                                    HStack(spacing: 6) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.system(size: 11))
                                        Text("Account numbers don't match")
                                            .font(.system(size: 12))
                                    }
                                    .foregroundStyle(.red)
                                    .transition(.opacity)
                                }
                            }

                            // Security note
                            HStack(spacing: 10) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.brand)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Secure & Encrypted")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(.textPrimary)
                                    Text("Your banking details are encrypted and stored securely. Only authorized administrators can access payment information.")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.textTertiary)
                                        .lineSpacing(3)
                                }
                            }
                            .padding(16)
                            .background(Color.brand.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.brand.opacity(0.15)))

                            // Submit button
                            Button {
                                Task {
                                    isSaving = true
                                    await viewModel.saveDirectDeposit()
                                    isSaving = false
                                    showSaved = true
                                }
                            } label: {
                                HStack(spacing: 10) {
                                    if isSaving {
                                        ProgressView()
                                            .tint(.white)
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "checkmark.shield.fill")
                                            .font(.system(size: 14, weight: .semibold))
                                        Text(isEditing ? "Update Direct Deposit" : "Save Direct Deposit")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                }
                            }
                            .buttonStyle(.brand)
                            .disabled(!viewModel.bankFormValid || isSaving)
                            .opacity(viewModel.bankFormValid && !isSaving ? 1 : 0.4)
                        }
                        .padding(.horizontal, 20)

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.textSecondary)
                    }
                }
            }
            .alert("Saved", isPresented: $showSaved) {
                Button("Done") { dismiss() }
            } message: {
                Text("Your direct deposit information has been saved successfully.")
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

    // MARK: - Form Field

    private func formField(
        _ placeholder: String,
        text: Binding<String>,
        icon: String,
        keyboard: UIKeyboardType = .default,
        secure: Bool = false
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(.textTertiary)
                .frame(width: 18)
            if secure {
                SecureField("", text: text, prompt: Text(placeholder).foregroundStyle(.textTertiary.opacity(0.7)))
                    .font(.system(size: 15))
                    .foregroundStyle(.textPrimary)
                    .keyboardType(keyboard)
                    .textContentType(.none)
                    .autocorrectionDisabled()
            } else {
                TextField("", text: text, prompt: Text(placeholder).foregroundStyle(.textTertiary.opacity(0.7)))
                    .font(.system(size: 15))
                    .foregroundStyle(.textPrimary)
                    .keyboardType(keyboard)
                    .autocorrectionDisabled()
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(Color.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Account Type Button

    private func accountTypeButton(_ label: String, value: String, icon: String) -> some View {
        let selected = viewModel.bankAccountType == value
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.bankAccountType = value
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(label)
                    .font(.system(size: 14, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(selected ? .white : .textSecondary)
            .background(selected ? Color.brand : Color.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(selected ? Color.brand : Color.borderSubtle)
            )
        }
    }
}
