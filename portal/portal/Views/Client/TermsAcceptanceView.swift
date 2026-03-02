import SwiftUI

struct TermsAcceptanceView: View {
    let uid: String
    let firestoreService: FirestoreService
    var onAccepted: () -> Void

    @State private var agreed = false
    @State private var saving = false
    @State private var appearAnimation = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surfacePrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Hero
                        VStack(spacing: 12) {
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(.brand)
                                .scaleEffect(appearAnimation ? 1 : 0.8)
                                .opacity(appearAnimation ? 1 : 0)

                            Text("Terms & Conditions")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(.textPrimary)

                            Text("Please review and accept before booking")
                                .font(.system(size: 14))
                                .foregroundStyle(.textSecondary)
                        }
                        .padding(.top, 8)

                        // Contract text
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(spacing: 8) {
                                Image(systemName: "scroll.fill")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(.brand)
                                Text("AGREEMENT")
                                    .font(.system(size: 10, weight: .bold))
                                    .tracking(2)
                                    .foregroundStyle(.textTertiary)
                            }

                            Text(TermsText.fullText)
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(.textSecondary)
                                .lineSpacing(4)
                        }
                        .padding(18)
                        .background(Color.surfaceCard)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.borderSubtle))

                        // Checkbox
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                agreed.toggle()
                            }
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: agreed ? "checkmark.square.fill" : "square")
                                    .font(.system(size: 22))
                                    .foregroundStyle(agreed ? .brand : .textTertiary)

                                Text("I have read and agree to all Terms and Conditions of the THE SMITH AGENCY CLIENT SERVICES AGREEMENT")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.textPrimary)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(16)
                            .background(Color.surfaceCard)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(agreed ? Color.brand.opacity(0.5) : Color.borderSubtle)
                            )
                        }

                        // Accept button
                        Button {
                            Task { await acceptTerms() }
                        } label: {
                            if saving {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Accept & Continue")
                            }
                        }
                        .buttonStyle(.brand)
                        .disabled(!agreed || saving)
                        .opacity(agreed ? 1 : 0.5)

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.textSecondary)
                    }
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                    appearAnimation = true
                }
            }
        }
    }

    private func acceptTerms() async {
        saving = true
        await firestoreService.acceptTerms(uid: uid, version: TermsText.currentVersion)
        saving = false
        dismiss()
        onAccepted()
    }
}
