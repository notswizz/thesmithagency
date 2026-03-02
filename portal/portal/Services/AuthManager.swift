import Foundation
import UIKit
import FirebaseAuth
import GoogleSignIn
import FirebaseFirestore

enum AuthState: Sendable {
    case loading
    case unauthenticated
    case staffAuthenticated(String)
    case clientAuthenticated(String)
    case staffOnboarding(String)          // uid — new staff, needs profile info
    case clientOnboarding(String, String) // uid, email
}

@Observable
final class AuthManager {
    var authState: AuthState = .loading
    var errorMessage: String?

    // Tracks whether the current session was a Google Sign-In (staff) vs email/password (client)
    private var lastSignInMethod: SignInMethod?
    private var authListener: AuthStateDidChangeListenerHandle?

    enum SignInMethod {
        case google, email
    }

    init() {
        listenToAuthState()
    }

    deinit {
        if let listener = authListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }

    private func listenToAuthState() {
        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            Task {
                await self.resolveUser(user)
            }
        }
    }

    private func resolveUser(_ user: User?) async {
        guard let user else {
            authState = .unauthenticated
            return
        }

        let email = user.email ?? ""
        let db = Firestore.firestore()

        // Check if this user exists in the staff collection (by doc ID or email)
        do {
            let staffDoc = try await db.collection("staff").document(user.uid).getDocument()
            if staffDoc.exists {
                let data = staffDoc.data() ?? [:]
                let phone = data["phone"] as? String ?? ""
                let location = data["location"] as? String ?? ""
                if phone.isEmpty && location.isEmpty {
                    authState = .staffOnboarding(user.uid)
                } else {
                    authState = .staffAuthenticated(user.uid)
                }
                return
            }
            // Fallback: search by email for legacy data
            if !email.isEmpty {
                let staffByEmail = try await db.collection("staff")
                    .whereField("email", isEqualTo: email)
                    .limit(to: 1)
                    .getDocuments()
                if let doc = staffByEmail.documents.first {
                    let data = doc.data()
                    let phone = data["phone"] as? String ?? ""
                    let location = data["location"] as? String ?? ""
                    if phone.isEmpty && location.isEmpty {
                        authState = .staffOnboarding(user.uid)
                    } else {
                        authState = .staffAuthenticated(user.uid)
                    }
                    return
                }
            }
        } catch { /* not staff, continue */ }

        // Check if this user exists in the clients collection (by doc ID or email)
        do {
            let clientDoc = try await db.collection("clients").document(user.uid).getDocument()
            if clientDoc.exists {
                let data = clientDoc.data() ?? [:]
                let onboarded = data["onboardingCompleted"] as? Bool ?? true
                if onboarded {
                    authState = .clientAuthenticated(user.uid)
                } else {
                    authState = .clientOnboarding(user.uid, email)
                }
                return
            }
            if !email.isEmpty {
                let clientByEmail = try await db.collection("clients")
                    .whereField("email", isEqualTo: email)
                    .limit(to: 1)
                    .getDocuments()
                if let doc = clientByEmail.documents.first {
                    let data = doc.data()
                    let onboarded = data["onboardingCompleted"] as? Bool ?? true
                    if onboarded {
                        authState = .clientAuthenticated(user.uid)
                    } else {
                        authState = .clientOnboarding(user.uid, email)
                    }
                    return
                }
            }
        } catch { /* not client, continue */ }

        // User exists in neither collection — route based on sign-in method
        if lastSignInMethod == .google {
            // New staff — create their profile from Google account info
            do {
                let displayName = user.displayName ?? ""
                let staff = Staff(
                    name: displayName,
                    email: email,
                    photoURL: user.photoURL?.absoluteString,
                    payRate: "18",
                    role: "staff",
                    active: true,
                    createdAt: Timestamp(),
                    updatedAt: Timestamp()
                )
                try db.collection("staff").document(user.uid).setData(from: staff)
            } catch { /* profile will be blank, they can fill it in */ }
            authState = .staffOnboarding(user.uid)
        } else {
            // Email/password user with no client doc — needs onboarding
            authState = .clientOnboarding(user.uid, email)
        }
    }

    func signInWithGoogle() async {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootVC = window.rootViewController else {
            errorMessage = "Unable to find root view controller"
            return
        }

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
            guard let idToken = result.user.idToken?.tokenString else {
                errorMessage = "Missing ID token"
                return
            }
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            lastSignInMethod = .google
            try await Auth.auth().signIn(with: credential)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signInWithEmail(_ email: String, password: String) async {
        do {
            lastSignInMethod = .email
            try await Auth.auth().signIn(withEmail: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signUpClient(email: String, password: String, companyName: String, website: String) async {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let client = Client(
                name: companyName,
                email: email,
                website: website,
                onboardingCompleted: false,
                createdAt: Timestamp(),
                updatedAt: Timestamp()
            )
            try Firestore.firestore()
                .collection("clients")
                .document(result.user.uid)
                .setData(from: client)
            lastSignInMethod = .email
            authState = .clientOnboarding(result.user.uid, email)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func completeClientOnboarding(uid: String) async {
        do {
            try await Firestore.firestore()
                .collection("clients")
                .document(uid)
                .updateData([
                    "onboardingCompleted": true,
                    "updatedAt": Timestamp()
                ])
            authState = .clientAuthenticated(uid)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func completeStaffOnboarding(uid: String, phone: String, location: String, address: String, college: String, instagram: String, dressSize: String, shoeSize: String, experience: String) async {
        do {
            try await Firestore.firestore()
                .collection("staff")
                .document(uid)
                .updateData([
                    "phone": phone,
                    "location": location,
                    "address": address,
                    "college": college,
                    "instagram": instagram,
                    "dressSize": dressSize,
                    "shoeSize": shoeSize,
                    "retailWholesaleExperience": experience,
                    "updatedAt": Timestamp(),
                ])
            authState = .staffAuthenticated(uid)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            authState = .unauthenticated
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
