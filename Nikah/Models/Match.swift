// Models/Match.swift
import SwiftUI
import Foundation
import FirebaseFirestore

struct MatchModel: Identifiable, Codable {
    var id: String?
    var users: [String]      // [userId1, userId2]
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case users
        case createdAt
    }

    init(id: String? = nil, users: [String] = [], createdAt: Date = Date()) {
        self.id = id
        self.users = users
        self.createdAt = createdAt
    }

    func otherUserId(currentUserId: String) -> String? {
        users.first(where: { $0 != currentUserId })
    }

    static func from(_ document: DocumentSnapshot) -> MatchModel? {
        guard let data = document.data() else { return nil }
        return MatchModel(
            id: document.documentID,
            users: data["users"] as? [String] ?? [],
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }

    func toFirestoreData() -> [String: Any] {
        return [
            "users": users,
            "createdAt": Timestamp(date: createdAt)
        ]
    }
}

struct LikeModel: Identifiable, Codable {
    var id: String?
    var fromUserId: String
    var toUserId: String
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case fromUserId
        case toUserId
        case createdAt
    }

    init(id: String? = nil, fromUserId: String = "", toUserId: String = "", createdAt: Date = Date()) {
        self.id = id
        self.fromUserId = fromUserId
        self.toUserId = toUserId
        self.createdAt = createdAt
    }

    func toFirestoreData() -> [String: Any] {
        return [
            "fromUserId": fromUserId,
            "toUserId": toUserId,
            "createdAt": Timestamp(date: createdAt)
        ]
    }
}

