import SwiftUI

struct ContentView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var firestoreService = FirestoreService()
    @State private var storageService = StorageService()

    var body: some View {
        Group {
            switch authManager.authState {
            case .loading:
                SplashView()

            case .unauthenticated:
                LoginView()

            case .staffOnboarding(let uid):
                StaffOnboardingView(uid: uid)

            case .staffAuthenticated(let uid):
                StaffTabView(
                    uid: uid,
                    firestoreService: firestoreService,
                    storageService: storageService
                )

            case .clientAuthenticated(let uid):
                ClientTabView(
                    uid: uid,
                    firestoreService: firestoreService
                )

            case .clientOnboarding(let uid, let email):
                ClientOnboardingView(uid: uid, email: email)
            }
        }
        .animation(.default, value: authState)
    }

    private var authState: String {
        switch authManager.authState {
        case .loading: return "loading"
        case .unauthenticated: return "unauth"
        case .staffOnboarding: return "staffOnboarding"
        case .staffAuthenticated: return "staff"
        case .clientAuthenticated: return "client"
        case .clientOnboarding: return "onboarding"
        }
    }
}
