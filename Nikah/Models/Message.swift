// Models/Message.swift

import Foundation
import FirebaseFirestore

struct MessageModel: Identifiable, Codable {
    var id: String?
    var matchId: String
    var senderId: String
    var text: String
    var messageType: String
    var audioURL: String?
    var audioDuration: Double?
    var timestamp: Date

    enum CodingKeys: String, CodingKey {
        case matchId
        case senderId
        case text
        case messageType
        case audioURL
        case audioDuration
        case timestamp
    }

    init(
        id: String? = nil,
        matchId: String = "",
        senderId: String = "",
        text: String = "",
        messageType: String = "text",
        audioURL: String? = nil,
        audioDuration: Double? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.matchId = matchId
        self.senderId = senderId
        self.text = text
        self.messageType = messageType
        self.audioURL = audioURL
        self.audioDuration = audioDuration
        self.timestamp = timestamp
    }

    static func from(_ document: DocumentSnapshot, matchId: String) -> MessageModel? {
        guard let data = document.data() else { return nil }
        return MessageModel(
            id: document.documentID,
            matchId: matchId,
            senderId: data["senderId"] as? String ?? "",
            text: data["text"] as? String ?? "",
            messageType: data["messageType"] as? String ?? "text",
            audioURL: data["audioURL"] as? String,
            audioDuration: data["audioDuration"] as? Double,
            timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
        )
    }

    func toFirestoreData() -> [String: Any] {
        var payload: [String: Any] = [
            "matchId": matchId,
            "senderId": senderId,
            "text": text,
            "messageType": messageType,
            "timestamp": Timestamp(date: timestamp)
        ]

        if let audioURL {
            payload["audioURL"] = audioURL
        }
        if let audioDuration {
            payload["audioDuration"] = audioDuration
        }

        return payload
    }
}

