// Models/Message.swift

import Foundation
import FirebaseFirestore

struct MessageModel: Identifiable, Codable {
    var id: String?
    var matchId: String
    var senderId: String
    var text: String
    var timestamp: Date

    enum CodingKeys: String, CodingKey {
        case matchId
        case senderId
        case text
        case timestamp
    }

    init(
        id: String? = nil,
        matchId: String = "",
        senderId: String = "",
        text: String = "",
        timestamp: Date = Date()
    ) {
        self.id = id
        self.matchId = matchId
        self.senderId = senderId
        self.text = text
        self.timestamp = timestamp
    }

    static func from(_ document: DocumentSnapshot, matchId: String) -> MessageModel? {
        guard let data = document.data() else { return nil }
        return MessageModel(
            id: document.documentID,
            matchId: matchId,
            senderId: data["senderId"] as? String ?? "",
            text: data["text"] as? String ?? "",
            timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
        )
    }

    func toFirestoreData() -> [String: Any] {
        return [
            "matchId": matchId,
            "senderId": senderId,
            "text": text,
            "timestamp": Timestamp(date: timestamp)
        ]
    }
}

