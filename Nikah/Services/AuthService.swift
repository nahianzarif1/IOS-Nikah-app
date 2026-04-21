// Services/AuthService.swift

import Foundation
import FirebaseAuth
import FirebaseFirestore

final class AuthService {
    static let shared = AuthService()
    private let manager = FirebaseManager.shared
    private init() {}

    // MARK: - Register
    func register(email: String, password: String, gender: String, completion: @escaping (Result<UserModel, Error>) -> Void) {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        manager.auth.createUser(withEmail: normalizedEmail, password: password) { [weak self] result, error in
            guard let self = self else { return }
            if let error = error {
                completion(.failure(error))
                return
            }
            let authUser = result?.user
            guard let uid = result?.user.uid else {
                completion(.failure(NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "UID not found"])))
                return
            }

            let newUser = UserModel(
                id: uid,
                displayName: "",
                email: normalizedEmail,
                gender: gender,
                age: 0,
                dateOfBirth: Date(),
                createdAt: Date(),
                lastActive: Date()
            )

            self.manager.usersCollection.document(uid).setData(newUser.toFirestoreData()) { err in
                if let err = err {
                    if let authUser {
                        authUser.delete { _ in
                            completion(.failure(err))
                        }
                    } else {
                        completion(.failure(err))
                    }
                } else {
                    completion(.success(newUser))
                }
            }
        }
    }

    // MARK: - Login
    func login(email: String, password: String, completion: @escaping (Result<String, Error>) -> Void) {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        manager.auth.signIn(withEmail: normalizedEmail, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let uid = result?.user.uid else {
                completion(.failure(NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "UID not found"])))
                return
            }
            completion(.success(uid))
        }
    }

    // MARK: - Logout
    func logout() throws {
        try manager.auth.signOut()
    }

    // MARK: - Delete Account
    func deleteAccount(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let uid = manager.auth.currentUser?.uid else {
            completion(.failure(NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not logged in"])))
            return
        }
        manager.usersCollection.document(uid).delete { [weak self] error in
            if let error = error {
                completion(.failure(error))
                return
            }
            self?.manager.auth.currentUser?.delete { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }

    var currentUserId: String? {
        manager.auth.currentUser?.uid
    }

    var isLoggedIn: Bool {
        manager.auth.currentUser != nil
    }
}
