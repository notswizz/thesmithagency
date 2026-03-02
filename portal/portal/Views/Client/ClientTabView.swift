import SwiftUI

struct ClientTabView: View {
    let uid: String
    let firestoreService: FirestoreService
    @Environment(AuthManager.self) private var authManager
    @State private var clientVM: ClientViewModel
    @State private var bookingVM: BookingViewModel

    @State private var stripeService = StripeService()
    @State private var showNewBooking = false
    @State private var showCompanyProfile = false
    @State private var showTerms = false

    init(uid: String, firestoreService: FirestoreService) {
        self.uid = uid
        self.firestoreService = firestoreService
        _clientVM = State(initialValue: ClientViewModel(firestoreService: firestoreService))
        _bookingVM = State(initialValue: BookingViewModel(firestoreService: firestoreService))
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ClientBookingsView(
                uid: uid,
                viewModel: bookingVM,
                firestoreService: firestoreService,
                onCompanyTap: { showCompanyProfile = true },
                onNewBooking: { startNewBooking() }
            )

            // FAB
            Button {
                startNewBooking()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(
                        LinearGradient(
                            colors: [Color.brand, Color.brandDark],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                    .shadow(color: Color.brand.opacity(0.4), radius: 8, y: 4)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 24)
        }
        .task {
            await clientVM.loadClient(uid: uid)
            let clientDocId = clientVM.client?.id ?? uid
            await bookingVM.loadClientBookings(clientId: clientDocId)
        }
        .sheet(isPresented: $showNewBooking) {
            BookStaffView(
                uid: uid,
                clientEmail: clientVM.client?.email ?? "",
                clientName: clientVM.client?.name ?? "",
                viewModel: bookingVM,
                clientVM: clientVM,
                stripeService: stripeService
            )
        }
        .sheet(isPresented: $showCompanyProfile) {
            CompanyProfileView(uid: uid, viewModel: clientVM)
        }
        .sheet(isPresented: $showTerms) {
            TermsAcceptanceView(
                uid: uid,
                firestoreService: firestoreService,
                onAccepted: {
                    Task {
                        await clientVM.loadClient(uid: uid)
                        showNewBooking = true
                    }
                }
            )
        }
    }

    private func startNewBooking() {
        let needsTC = clientVM.client?.tcAcceptedAt == nil
            || clientVM.client?.tcVersion != TermsText.currentVersion
        if needsTC {
            showTerms = true
        } else {
            showNewBooking = true
        }
    }
}
