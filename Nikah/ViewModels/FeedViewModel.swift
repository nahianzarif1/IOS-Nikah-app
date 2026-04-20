// ViewModels/FeedViewModel.swift

import Foundation
import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore
@MainActor
final class FeedViewModel: ObservableObject {
    @Published var profiles: [UserModel] = []
    @Published var currentIndex: Int = 0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var matchAlert: Bool = false
    @Published var matchedUserName: String = ""
    @Published var filter: FilterModel = FilterModel()

    private var likedUserIds: Set<String> = []
    private var shortlistedUserIds: Set<String> = []

    var currentProfile: UserModel? {
        guard currentIndex < profiles.count else { return nil }
        return profiles[currentIndex]
    }

    var hasProfiles: Bool {
        currentIndex < profiles.count
    }

    // MARK: - Load Feed
    func loadFeed(currentUser: UserModel) {
        isLoading = true
        errorMessage = nil

        // First load already liked ids to skip them
        guard let uid = currentUser.id else { return }

        MatchService.shared.fetchLikedUserIds(fromUserId: uid) { [weak self] likedIds in
            Task { @MainActor in
                guard let self = self else { return }
                self.likedUserIds = Set(likedIds)

                ShortlistService.shared.fetchShortlistedUserIds(fromUserId: uid) { shortlistIds in
                    Task { @MainActor in
                        self.shortlistedUserIds = Set(shortlistIds)

                        UserService.shared.fetchFeedUsers(
                            currentUser: currentUser,
                            filter: self.filter,
                            alreadySeen: Array(self.likedUserIds)
                        ) { result in
                            Task { @MainActor in
                                self.isLoading = false
                                switch result {
                                case .success(let users):
                                    self.profiles = users.shuffled()
                                    self.currentIndex = 0
                                case .failure(let error):
                                    self.errorMessage = error.localizedDescription
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Like Profile
    func likeCurrentProfile(currentUser: UserModel) {
        guard let myId = currentUser.id,
              let targetUser = currentProfile,
              let targetId = targetUser.id else { return }

        MatchService.shared.likeUser(fromUserId: myId, toUserId: targetId) { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let isMatch):
                    if isMatch {
                        self?.matchedUserName = targetUser.displayName
                        self?.matchAlert = true
                    }
                    self?.advance()
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Pass Profile
    func passCurrentProfile() {
        advance()
    }

    func isCurrentProfileShortlisted() -> Bool {
        guard let id = currentProfile?.id else { return false }
        return shortlistedUserIds.contains(id)
    }

    func toggleShortlistForCurrentProfile(currentUser: UserModel) {
        guard let myId = currentUser.id,
              let targetId = currentProfile?.id else { return }

        let willShortlist = !shortlistedUserIds.contains(targetId)
        ShortlistService.shared.setShortlisted(
            fromUserId: myId,
            toUserId: targetId,
            isShortlisted: willShortlist
        ) { [weak self] error in
            Task { @MainActor in
                guard error == nil else {
                    self?.errorMessage = error?.localizedDescription
                    return
                }
                if willShortlist {
                    self?.shortlistedUserIds.insert(targetId)
                } else {
                    self?.shortlistedUserIds.remove(targetId)
                }
            }
        }
    }

    // MARK: - Advance to next card
    private func advance() {
        currentIndex += 1
    }

    // MARK: - Apply Filter
    func applyFilter(_ newFilter: FilterModel, currentUser: UserModel) {
        filter = newFilter
        loadFeed(currentUser: currentUser)
    }
}
