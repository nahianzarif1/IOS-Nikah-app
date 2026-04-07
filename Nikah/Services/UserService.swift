// Services/UserService.swift
import Foundation
import FirebaseFirestore

final class UserService {
    static let shared = UserService()
    private let manager = FirebaseManager.shared
    private init() {}

    // MARK: - Fetch Current User
    func fetchUser(uid: String, completion: @escaping (Result<UserModel, Error>) -> Void) {
        manager.usersCollection.document(uid).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let snapshot = snapshot, snapshot.exists,
                  let user = UserModel.from(snapshot) else {
                completion(.failure(NSError(domain: "UserService", code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "User not found"])))
                return
            }
            completion(.success(user))
        }
    }

    // MARK: - Update User
    func updateUser(_ user: UserModel, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let uid = user.id else {
            completion(.failure(NSError(domain: "UserService", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "User ID missing"])))
            return
        }
        manager.usersCollection.document(uid).setData(user.toFirestoreData(), merge: true) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    // MARK: - Update Last Active
    func updateLastActive(uid: String) {
        manager.usersCollection.document(uid).updateData(["lastActive": Timestamp(date: Date())])
    }

    // MARK: - Fetch Feed Users (opposite gender, not blocked)
    func fetchFeedUsers(
        currentUser: UserModel,
        filter: FilterModel,
        alreadySeen: [String],
        completion: @escaping (Result<[UserModel], Error>) -> Void
    ) {
        let oppositeGender = currentUser.gender == "male" ? "female" : "male"

        var query: Query = manager.usersCollection
            .whereField("gender", isEqualTo: oppositeGender)
            .whereField("profileCompleted", isEqualTo: true)
            .limit(to: 30)

        if !filter.district.isEmpty {
            query = query.whereField("district", isEqualTo: filter.district)
        }
        if !filter.maritalStatus.isEmpty {
            query = query.whereField("maritalStatus", isEqualTo: filter.maritalStatus)
        }

        query.getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            let users: [UserModel] = snapshot?.documents.compactMap { doc in
                UserModel.from(doc)
            } ?? []

            let blockedByMe = currentUser.blockedUsers
            let filtered = users.filter { user in
                guard let uid = user.id else { return false }
                if uid == currentUser.id { return false }
                if alreadySeen.contains(uid) { return false }
                if blockedByMe.contains(uid) { return false }
                if user.blockedUsers.contains(currentUser.id ?? "") { return false }
                if user.age < filter.minAge || user.age > filter.maxAge { return false }
                if user.height < filter.minHeight || user.height > filter.maxHeight { return false }
                if !filter.education.isEmpty &&
                   !user.education.localizedCaseInsensitiveContains(filter.education) { return false }
                if !filter.profession.isEmpty &&
                   !user.profession.localizedCaseInsensitiveContains(filter.profession) { return false }
                return true
            }
            completion(.success(filtered))
        }
    }

    // MARK: - Block User
    func blockUser(currentUserId: String, blockedUserId: String, completion: @escaping (Error?) -> Void) {
        manager.usersCollection.document(currentUserId).updateData([
            "blockedUsers": FieldValue.arrayUnion([blockedUserId])
        ], completion: completion)
    }

    // MARK: - Report User
    func reportUser(reportedUserId: String, reportedBy: String, reason: String, completion: @escaping (Error?) -> Void) {
        let data: [String: Any] = [
            "reportedUserId": reportedUserId,
            "reportedBy": reportedBy,
            "reason": reason,
            "createdAt": Timestamp(date: Date())
        ]
        manager.reportsCollection.addDocument(data: data, completion: completion)
    }
}

