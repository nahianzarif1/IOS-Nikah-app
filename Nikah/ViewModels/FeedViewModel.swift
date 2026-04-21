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
    private var passedUserIds: [String] = []

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

        guard let uid = currentUser.id else {
            isLoading = false
            errorMessage = "Unable to load the feed right now. Please refresh your profile and try again."
            return
        }

        let passedUsers = passedUserIds

        MatchService.shared.fetchLikedUserIds(fromUserId: uid) { [weak self] likedIds in
            Task { @MainActor in
                guard let self = self else { return }
                self.likedUserIds = Set(likedIds)

                UserService.shared.fetchFeedUsers(
                    currentUser: currentUser,
                    filter: self.filter,
                    alreadySeen: Array(self.likedUserIds)
                ) { result in
                    Task { @MainActor in
                        self.isLoading = false
                        switch result {
                        case .success(let users):
                            var refreshedUsers = users.shuffled()
                            if !passedUsers.isEmpty {
                                refreshedUsers.sort { lhs, rhs in
                                    let lhsPassed = lhs.id.map(passedUsers.contains) ?? false
                                    let rhsPassed = rhs.id.map(passedUsers.contains) ?? false
                                    if lhsPassed != rhsPassed {
                                        return lhsPassed
                                    }
                                    return lhs.displayName < rhs.displayName
                                }
                            }
                            self.profiles = refreshedUsers
                            self.currentIndex = 0
                            self.passedUserIds = []
                        case .failure(let error):
                            self.errorMessage = error.localizedDescription
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
        if let passedId = currentProfile?.id, !passedId.isEmpty {
            passedUserIds.append(passedId)
        }
        advance()
    }

    func refreshDiscover(currentUser: UserModel) {
        loadFeed(currentUser: currentUser)
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
