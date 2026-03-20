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
        let like = LikeModel(fromUserId: fromUserId, toUserId: toUserId, createdAt: Date())
        manager.likesCollection.addDocument(data: like.toFirestoreData()) { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                completion(.failure(error))
                return
            }
            // Check if reverse like exists
            self.manager.likesCollection
                .whereField("fromUserId", isEqualTo: toUserId)
                .whereField("toUserId", isEqualTo: fromUserId)
                .getDocuments { snapshot, error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    let reverseLikeExists = !(snapshot?.documents.isEmpty ?? true)
                    if reverseLikeExists {
                        self.createMatch(userId1: fromUserId, userId2: toUserId) { result in
                            switch result {
                            case .success:
                                completion(.success(true))
                            case .failure(let err):
                                completion(.failure(err))
                            }
                        }
                    } else {
                        completion(.success(false))
                    }
                }
        }
    }

    // MARK: - Create Match
    private func createMatch(userId1: String, userId2: String, completion: @escaping (Result<Void, Error>) -> Void) {
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
        manager.likesCollection
            .whereField("fromUserId", isEqualTo: fromUserId)
            .getDocuments { snapshot, _ in
                let ids = snapshot?.documents.compactMap {
                    $0.data()["toUserId"] as? String
                } ?? []
                completion(ids)
            }
    }
}

