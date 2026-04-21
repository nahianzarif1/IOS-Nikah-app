import Foundation
import FirebaseFirestore

final class MatchService {
    static let shared = MatchService()
    private let manager = FirebaseManager.shared

    private init() {}

    // MARK: - Like a User
    /// Returns true when the like results in a mutual match.
    func likeUser(fromUserId: String, toUserId: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        validateMatchEligibility(fromUserId: fromUserId, toUserId: toUserId) { [weak self] validation in
            guard let self else { return }

            switch validation {
            case .failure(let error):
                completion(.failure(error))

            case .success(let usersById):
                self.saveLike(fromUserId: fromUserId, toUserId: toUserId) { result in
                    switch result {
                    case .failure(let error):
                        completion(.failure(error))

                    case .success:
                        self.checkIfReverseLikeExists(fromUserId: fromUserId, toUserId: toUserId) { result in
                            switch result {
                            case .failure(let error):
                                completion(.failure(error))

                            case .success(let reverseLikeExists):
                                guard reverseLikeExists else {
                                    completion(.success(false))
                                    return
                                }

                                self.upsertMatch(
                                    currentUser: usersById[fromUserId],
                                    otherUser: usersById[toUserId]
                                ) { result in
                                    switch result {
                                    case .success:
                                        completion(.success(true))
                                    case .failure(let error):
                                        completion(.failure(error))
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Access Validation
    func validateChatAccess(matchId: String, userId: String, completion: @escaping (Result<MatchModel, Error>) -> Void) {
        manager.matchesCollection.document(matchId).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let snapshot, snapshot.exists, let match = MatchModel.from(snapshot) else {
                completion(.failure(NSError(
                    domain: "MatchService",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Match not found."]
                )))
                return
            }

            guard match.users.contains(userId) else {
                completion(.failure(NSError(
                    domain: "MatchService",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "You can only chat after a valid mutual match."]
                )))
                return
            }

            completion(.success(match))
        }
    }

    // MARK: - Fetch Matches
    func fetchMatches(userId: String, completion: @escaping (Result<[MatchModel], Error>) -> Void) -> ListenerRegistration {
        manager.matchesCollection
            .whereField("users", arrayContains: userId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                let matches = snapshot?.documents.compactMap(MatchModel.from) ?? []
                completion(.success(matches))
            }
    }

    func reconcileMatches(for userId: String, completion: ((Error?) -> Void)? = nil) {
        manager.likesCollection
            .whereField("fromUserId", isEqualTo: userId)
            .getDocuments { [weak self] snapshot, error in
                guard let self else { return }

                if let error = error {
                    completion?(error)
                    return
                }

                let outgoingLikes = snapshot?.documents.compactMap(LikeModel.from) ?? []
                let targetIds = Array(Set(outgoingLikes.map(\.toUserId))).filter { !$0.isEmpty }

                guard !targetIds.isEmpty else {
                    completion?(nil)
                    return
                }

                self.fetchUsers(for: [userId] + targetIds) { result in
                    switch result {
                    case .failure(let error):
                        completion?(error)

                    case .success(let usersById):
                        let group = DispatchGroup()
                        var firstError: Error?

                        for targetId in targetIds {
                            group.enter()
                            self.checkIfReverseLikeExists(fromUserId: userId, toUserId: targetId) { reverseResult in
                                switch reverseResult {
                                case .failure(let error):
                                    if firstError == nil {
                                        firstError = error
                                    }
                                    group.leave()

                                case .success(let exists):
                                    guard exists else {
                                        group.leave()
                                        return
                                    }
                                    self.upsertMatch(
                                        currentUser: usersById[userId],
                                        otherUser: usersById[targetId]
                                    ) { matchResult in
                                        if case .failure(let error) = matchResult, firstError == nil {
                                            firstError = error
                                        }
                                        group.leave()
                                    }
                                }
                            }
                        }

                        group.notify(queue: .main) {
                            completion?(firstError)
                        }
                    }
                }
            }
    }

    // MARK: - Fetch Already Liked
    func fetchLikedUserIds(fromUserId: String, completion: @escaping ([String]) -> Void) {
        manager.likesCollection
            .whereField("fromUserId", isEqualTo: fromUserId)
            .getDocuments { snapshot, _ in
                let ids = snapshot?.documents.compactMap { LikeModel.from($0)?.toUserId } ?? []
                completion(Array(Set(ids)))
            }
    }

    // MARK: - Like Persistence
    private func saveLike(fromUserId: String, toUserId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let like = LikeModel(
            id: likeDocumentId(fromUserId: fromUserId, toUserId: toUserId),
            fromUserId: fromUserId,
            toUserId: toUserId,
            createdAt: Date()
        )

        manager.likesCollection.document(like.id ?? UUID().uuidString).setData(like.toFirestoreData(), merge: true) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    private func checkIfReverseLikeExists(fromUserId: String, toUserId: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        let reverseLikeId = likeDocumentId(fromUserId: toUserId, toUserId: fromUserId)
        manager.likesCollection.document(reverseLikeId).getDocument { [weak self] snapshot, error in
            guard let self else { return }

            if let error = error {
                completion(.failure(error))
                return
            }

            if snapshot?.exists == true {
                completion(.success(true))
                return
            }

            // Compatibility with older random-ID like documents already in Firestore.
            self.manager.likesCollection
                .whereField("fromUserId", isEqualTo: toUserId)
                .whereField("toUserId", isEqualTo: fromUserId)
                .getDocuments { snapshot, error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(!(snapshot?.documents.isEmpty ?? true)))
                    }
                }
        }
    }

    // MARK: - Match Persistence
    private func upsertMatch(currentUser: UserModel?, otherUser: UserModel?, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUser, let otherUser,
              let currentUserId = currentUser.id, let otherUserId = otherUser.id else {
            completion(.failure(NSError(
                domain: "MatchService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Match users are missing."]
            )))
            return
        }

        let matchId = matchDocumentId(userId1: currentUserId, userId2: otherUserId)
        let userIds = [currentUserId, otherUserId].sorted()
        let match = MatchModel(
            id: matchId,
            users: userIds,
            createdAt: Date(),
            userSnapshots: [
                currentUserId: MatchUserSnapshot(user: currentUser),
                otherUserId: MatchUserSnapshot(user: otherUser)
            ]
        )

        manager.matchesCollection.document(matchId).setData(match.toFirestoreData(), merge: true) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    // MARK: - Validation
    private func validateMatchEligibility(
        fromUserId: String,
        toUserId: String,
        completion: @escaping (Result<[String: UserModel], Error>) -> Void
    ) {
        guard fromUserId != toUserId else {
            completion(.failure(NSError(
                domain: "MatchService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "You cannot match with yourself."]
            )))
            return
        }

        fetchUsers(for: [fromUserId, toUserId]) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))

            case .success(let usersById):
                guard let currentUser = usersById[fromUserId], let otherUser = usersById[toUserId] else {
                    completion(.failure(NSError(
                        domain: "MatchService",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "One or both users could not be found."]
                    )))
                    return
                }

                guard currentUser.profileCompleted, otherUser.profileCompleted else {
                    completion(.failure(NSError(
                        domain: "MatchService",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Both profiles must be completed before matching."]
                    )))
                    return
                }

                let currentGender = currentUser.gender.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                let otherGender = otherUser.gender.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                let validPair = Set([currentGender, otherGender]) == Set(["male", "female"])

                guard validPair else {
                    completion(.failure(NSError(
                        domain: "MatchService",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Matches are only allowed between one male profile and one female profile."]
                    )))
                    return
                }

                guard !currentUser.blockedUsers.contains(toUserId),
                      !otherUser.blockedUsers.contains(fromUserId) else {
                    completion(.failure(NSError(
                        domain: "MatchService",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "This match is no longer available."]
                    )))
                    return
                }

                completion(.success(usersById))
            }
        }
    }

    private func fetchUsers(for userIds: [String], completion: @escaping (Result<[String: UserModel], Error>) -> Void) {
        let ids = Array(Set(userIds)).filter { !$0.isEmpty }
        guard !ids.isEmpty else {
            completion(.success([:]))
            return
        }

        var usersById: [String: UserModel] = [:]
        var firstError: Error?
        let group = DispatchGroup()

        for userId in ids {
            group.enter()
            manager.usersCollection.document(userId).getDocument { snapshot, error in
                defer { group.leave() }

                if let error = error {
                    firstError = error
                    return
                }

                guard let snapshot, snapshot.exists, let user = UserModel.from(snapshot) else {
                    firstError = NSError(
                        domain: "MatchService",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "User not found."]
                    )
                    return
                }

                usersById[userId] = user
            }
        }

        group.notify(queue: .main) {
            if let firstError {
                completion(.failure(firstError))
            } else {
                completion(.success(usersById))
            }
        }
    }

    // MARK: - IDs
    private func likeDocumentId(fromUserId: String, toUserId: String) -> String {
        "\(fromUserId)_likes_\(toUserId)"
    }

    private func matchDocumentId(userId1: String, userId2: String) -> String {
        [userId1, userId2].sorted().joined(separator: "_")
    }
}
