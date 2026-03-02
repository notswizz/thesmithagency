import SwiftUI

struct PaymentSuccessView: View {
    let showName: String
    @Environment(\.dismiss) private var dismiss

    @State private var animateRing = false
    @State private var animateCheck = false
    @State private var animateContent = false

    var body: some View {
        ZStack {
            Color.surfacePrimary.ignoresSafeArea()

            // Subtle radial glow behind the checkmark
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.brand.opacity(0.08), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .offset(y: -80)
                .opacity(animateRing ? 1 : 0)

            VStack(spacing: 0) {
                Spacer()

                // ── Checkmark animation ──────────────────
                ZStack {
                    // Outer ring
                    Circle()
                        .stroke(Color.brand.opacity(0.08), lineWidth: 2)
                        .frame(width: 140, height: 140)
                        .scaleEffect(animateRing ? 1 : 0.6)
                        .opacity(animateRing ? 1 : 0)

                    // Inner glow
                    Circle()
                        .fill(Color.brand.opacity(0.1))
                        .frame(width: 100, height: 100)
                        .scaleEffect(animateCheck ? 1 : 0.4)
                        .opacity(animateCheck ? 1 : 0)

                    // Check icon
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.brand)
                        .scaleEffect(animateCheck ? 1 : 0.2)
                        .opacity(animateCheck ? 1 : 0)
                }
                .padding(.bottom, 32)

                // ── Text ─────────────────────────────────
                VStack(spacing: 10) {
                    Text("Booking Confirmed")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.textPrimary)

                    Text("Your deposit has been processed\nand your booking for **\(showName)** is confirmed.")
                        .font(.system(size: 15))
                        .foregroundStyle(.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 32)
                }
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 12)
                .padding(.bottom, 32)

                // ── Receipt card ─────────────────────────
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Deposit Paid")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.textTertiary)
                                .tracking(1)
                            Text("$100.00")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(.brand)
                        }
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(Color.brand.opacity(0.12))
                                .frame(width: 44, height: 44)
                            Image(systemName: "creditcard.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(.brand)
                        }
                    }

                    Divider().overlay(Color.borderSubtle)

                    HStack {
                        Text("Status")
                            .font(.system(size: 13))
                            .foregroundStyle(.textTertiary)
                        Spacer()
                        HStack(spacing: 5) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                            Text("Confirmed")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.green)
                        }
                    }
                }
                .padding(20)
                .background(Color.surfaceCard)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.borderSubtle))
                .padding(.horizontal, 28)
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 16)

                Spacer()

                // ── CTA ──────────────────────────────────
                VStack(spacing: 8) {
                    Button { dismiss() } label: {
                        Text("Done")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .buttonStyle(.brand)

                    Text("You'll receive a confirmation once staff are assigned")
                        .font(.system(size: 11))
                        .foregroundStyle(.textTertiary)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
                .opacity(animateContent ? 1 : 0)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.65).delay(0.1)) {
                animateRing = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.3)) {
                animateCheck = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.6)) {
                animateContent = true
            }
        }
    }
}
