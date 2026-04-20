import Foundation
import Combine

@MainActor
final class ShortlistViewModel: ObservableObject {
    @Published var users: [UserModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadShortlistedUsers(currentUserId: String) {
        isLoading = true
        errorMessage = nil

        ShortlistService.shared.fetchShortlistedUserIds(fromUserId: currentUserId) { [weak self] ids in
            Task { @MainActor [weak self] in
                guard let self else { return }
                guard !ids.isEmpty else {
                    self.users = []
                    self.isLoading = false
                    return
                }

                let group = DispatchGroup()
                var loadedUsers: [UserModel] = []

                for id in ids {
                    group.enter()
                    UserService.shared.fetchUser(uid: id) { result in
                        if case .success(let user) = result {
                            loadedUsers.append(user)
                        }
                        group.leave()
                    }
                }

                group.notify(queue: .main) {
                    self.users = loadedUsers.sorted { $0.lastActive > $1.lastActive }
                    self.isLoading = false
                }
            }
        }
    }

    func removeFromShortlist(currentUserId: String, targetUserId: String) {
        ShortlistService.shared.setShortlisted(fromUserId: currentUserId, toUserId: targetUserId, isShortlisted: false) { [weak self] error in
            Task { @MainActor [weak self] in
                if let error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                self?.users.removeAll { $0.id == targetUserId }
            }
        }
    }
}
