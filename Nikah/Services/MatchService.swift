// Services/MatchService.swift

import Foundation
import FirebaseFirestore

final class MatchService {
    static let shared = MatchService()
    private let manager = FirebaseManager.shared
    private init() {}

    // MARK: - Like a User
    /// Returns true in completion if a mutual match was created
    func likeUser(fromUserId: String, toUserId: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        let now = Date()

        // If the target user already has a pending request to me, accepting it should create a match immediately.
        manager.requestsCollection
            .whereField("fromUserId", isEqualTo: toUserId)
            .whereField("toUserId", isEqualTo: fromUserId)
            .whereField("status", isEqualTo: RequestStatus.pending.rawValue)
            .limit(to: 1)
            .getDocuments { [weak self] reverseSnapshot, reverseError in
                guard let self = self else { return }
                if let reverseError = reverseError {
                    completion(.failure(reverseError))
                    return
                }

                if let reverseDoc = reverseSnapshot?.documents.first {
                    reverseDoc.reference.updateData([
                        "status": RequestStatus.accepted.rawValue,
                        "updatedAt": Timestamp(date: now)
                    ]) { updateError in
                        if let updateError = updateError {
                            completion(.failure(updateError))
                            return
                        }

                        self.ensureMatch(userId1: fromUserId, userId2: toUserId) { matchResult in
                            switch matchResult {
                            case .success:
                                completion(.success(true))
                            case .failure(let error):
                                completion(.failure(error))
                            }
                        }
                    }
                    return
                }

        let request = InterestRequestModel(
            fromUserId: fromUserId,
            toUserId: toUserId,
            status: .pending,
            createdAt: now,
            updatedAt: now
        )

                self.manager.requestsCollection
                    .whereField("fromUserId", isEqualTo: fromUserId)
                    .whereField("toUserId", isEqualTo: toUserId)
                    .getDocuments { snapshot, error in
                        if let error = error {
                            completion(.failure(error))
                            return
                        }

                        if let existing = snapshot?.documents.first {
                            existing.reference.updateData([
                                "status": RequestStatus.pending.rawValue,
                                "updatedAt": Timestamp(date: now)
                            ]) { updateError in
                                if let updateError = updateError {
                                    completion(.failure(updateError))
                                } else {
                                    completion(.success(false))
                                }
                            }
                        } else {
                            self.manager.requestsCollection.addDocument(data: request.toFirestoreData()) { addError in
                                if let addError = addError {
                                    completion(.failure(addError))
                                } else {
                                    completion(.success(false))
                                }
                            }
                        }
                    }
            }
    }

    // MARK: - Create Match
    func ensureMatch(userId1: String, userId2: String, completion: @escaping (Result<Void, Error>) -> Void) {
        manager.matchesCollection
            .whereField("users", arrayContains: userId1)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    completion(.failure(error))
                    return
                }
                let alreadyMatched = snapshot?.documents.contains { doc in
                    let users = doc.data()["users"] as? [String] ?? []
                    return users.contains(userId2)
                } ?? false

                if alreadyMatched {
                    completion(.success(()))
                    return
                }

                let match = MatchModel(users: [userId1, userId2], createdAt: Date())
                self.manager.matchesCollection.addDocument(data: match.toFirestoreData()) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                    }
                }
            }
    }

    // MARK: - Fetch Matches for user
    func fetchMatches(userId: String, completion: @escaping (Result<[MatchModel], Error>) -> Void) -> ListenerRegistration {
        return manager.matchesCollection
            .whereField("users", arrayContains: userId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                let matches: [MatchModel] = snapshot?.documents.compactMap {
                    MatchModel.from($0)
                } ?? []
                completion(.success(matches))
            }
    }

    // MARK: - Check Already Liked
    func fetchLikedUserIds(fromUserId: String, completion: @escaping ([String]) -> Void) {
        manager.requestsCollection
            .whereField("fromUserId", isEqualTo: fromUserId)
            .getDocuments { snapshot, _ in
                let ids = snapshot?.documents.compactMap {
                    $0.data()["toUserId"] as? String
                } ?? []
                completion(ids)
            }
    }
}