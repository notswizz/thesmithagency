import Foundation
import FirebaseStorage
import UIKit

@Observable
final class StorageService {
    private let storage = Storage.storage()

    func uploadHeadshot(uid: String, image: UIImage) async throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw StorageError.invalidImage
        }
        let ref = storage.reference().child("staff/\(uid)/headshot.jpg")
        _ = try await ref.putDataAsync(data)
        let url = try await ref.downloadURL()
        return url.absoluteString
    }

    func uploadResume(uid: String, data: Data, filename: String) async throws -> String {
        let ref = storage.reference().child("staff/\(uid)/resume.pdf")
        let metadata = StorageMetadata()
        metadata.contentType = "application/pdf"
        _ = try await ref.putDataAsync(data, metadata: metadata)
        let url = try await ref.downloadURL()
        return url.absoluteString
    }
}

enum StorageError: LocalizedError {
    case invalidImage

    var errorDescription: String? {
        switch self {
        case .invalidImage: return "Could not process image data"
        }
    }
}
