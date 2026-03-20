// ViewModels/ProfileViewModel.swift

import Foundation
import SwiftUI
import UIKit
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var user: UserModel
    @Published var isLoading: Bool = false
    @Published var isSaving: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var isUploadingPhoto: Bool = false

    init(user: UserModel) {
        self.user = user
    }

    // MARK: - Save Profile
    func saveProfile(completion: (() -> Void)? = nil) {
        isSaving = true
        errorMessage = nil

        // Mark profile completed if ready
        if user.isProfileReady && !user.displayName.isEmpty {
            user.profileCompleted = true
        }

        UserService.shared.updateUser(user) { [weak self] result in
            Task { @MainActor in
                self?.isSaving = false
                switch result {
                case .success:
                    self?.successMessage = "Profile saved successfully!"
                    completion?()
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Upload Photo
    func uploadPhoto(_ image: UIImage) {
        isUploadingPhoto = true
        errorMessage = nil
        CloudinaryService.uploadImage(image: image) { [weak self] urlString in
            Task { @MainActor in
                self?.isUploadingPhoto = false
                if let url = urlString {
                    self?.user.photos.append(url)
                } else {
                    self?.errorMessage = "Failed to upload photo. Please try again."
                }
            }
        }
    }

    // MARK: - Remove Photo
    func removePhoto(at index: Int) {
        guard index < user.photos.count else { return }
        user.photos.remove(at: index)
    }

    // MARK: - Calculate Age from DOB
    func updateAgeFromDOB() {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year], from: user.dateOfBirth, to: now)
        user.age = components.year ?? 0
    }

    // MARK: - Block User
    func blockUser(blockedId: String) {
        guard let myId = user.id else { return }
        UserService.shared.blockUser(currentUserId: myId, blockedUserId: blockedId) { error in
            Task { @MainActor in
                if let error = error {
                    print("Block error: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Report User
    func reportUser(reportedUserId: String, reason: String) {
        guard let myId = user.id else { return }
        UserService.shared.reportUser(reportedUserId: reportedUserId, reportedBy: myId, reason: reason) { error in
            if let error = error {
                print("Report error: \(error.localizedDescription)")
            }
        }
    }
}
