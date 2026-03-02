import SwiftUI
import FirebaseCore
import GoogleSignIn
import StripePaymentSheet

@main
struct portalApp: App {
    @State private var authManager: AuthManager

    init() {
        FirebaseApp.configure()
        StripeAPI.defaultPublishableKey = StripeService.publishableKey
        _authManager = State(initialValue: AuthManager())
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authManager)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
