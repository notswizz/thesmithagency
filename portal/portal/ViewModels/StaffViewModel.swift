import Foundation
import UIKit

@Observable
final class StaffViewModel {
    var staff: Staff?
    var isLoading = false
    var errorMessage: String?

    // Profile editing
    var phone = ""
    var location = ""
    var address = ""
    var college = ""
    var dressSize = ""
    var shoeSize = ""
    var instagram = ""
    var experience = ""

    // Direct deposit
    var bankHolderName = ""
    var bankRouting = ""
    var bankAccount = ""
    var bankAccountConfirm = ""
    var bankAccountType = "checking"

    var hasChanges: Bool {
        guard let s = staff else { return false }
        return phone != (s.phone ?? "")
            || location != (s.location ?? "")
            || address != (s.address ?? "")
            || college != (s.college ?? "")
            || dressSize != (s.dressSize ?? "")
            || shoeSize != (s.shoeSize ?? "")
            || instagram != (s.instagram ?? "")
            || experience != (s.retailWholesaleExperience ?? "")
    }

    var hasBankChanges: Bool {
        guard let s = staff else { return false }
        return bankHolderName != (s.bankAccountHolderName ?? "")
            || bankRouting != (s.bankRoutingNumber ?? "")
            || bankAccount != (s.bankAccountNumber ?? "")
            || bankAccountType != (s.bankAccountType ?? "checking")
    }

    var bankFormValid: Bool {
        !bankHolderName.isEmpty
            && bankRouting.count == 9
            && !bankAccount.isEmpty
            && bankAccount == bankAccountConfirm
    }

    private let firestoreService: FirestoreService
    private let storageService: StorageService

    init(firestoreService: FirestoreService, storageService: StorageService) {
        self.firestoreService = firestoreService
        self.storageService = storageService
    }

    func loadStaff(uid: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            staff = try await firestoreService.fetchStaff(uid: uid)
            if let s = staff {
                phone = s.phone ?? ""
                location = s.location ?? ""
                address = s.address ?? ""
                college = s.college ?? ""
                dressSize = s.dressSize ?? ""
                shoeSize = s.shoeSize ?? ""
                instagram = s.instagram ?? ""
                experience = s.retailWholesaleExperience ?? ""
                bankHolderName = s.bankAccountHolderName ?? ""
                bankRouting = s.bankRoutingNumber ?? ""
                bankAccount = s.bankAccountNumber ?? ""
                bankAccountConfirm = s.bankAccountNumber ?? ""
                bankAccountType = s.bankAccountType ?? "checking"
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveProfile() async {
        guard var s = staff else { return }
        s.phone = phone
        s.location = location
        s.address = address
        s.college = college
        s.dressSize = dressSize
        s.shoeSize = shoeSize
        s.instagram = instagram
        s.retailWholesaleExperience = experience
        do {
            try await firestoreService.updateStaff(s)
            staff = s
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveDirectDeposit() async {
        guard var s = staff else { return }
        s.bankAccountHolderName = bankHolderName
        s.bankRoutingNumber = bankRouting
        s.bankAccountNumber = bankAccount
        s.bankAccountType = bankAccountType
        s.directDepositCompleted = true
        do {
            try await firestoreService.updateStaff(s)
            staff = s
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func uploadHeadshot(uid: String, image: UIImage) async {
        do {
            let url = try await storageService.uploadHeadshot(uid: uid, image: image)
            staff?.photoURL = url
            if var s = staff {
                s.photoURL = url
                try await firestoreService.updateStaff(s)
                staff = s
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func uploadResume(uid: String, data: Data, filename: String) async {
        do {
            let url = try await storageService.uploadResume(uid: uid, data: data, filename: filename)
            if var s = staff {
                s.resumeURL = url
                try await firestoreService.updateStaff(s)
                staff = s
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
