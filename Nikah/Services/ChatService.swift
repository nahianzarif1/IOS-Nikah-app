// Services/ChatService.swift

import Foundation
import Combine
import FirebaseFirestore

final class ChatService {
    static let shared = ChatService()
    private let manager = FirebaseManager.shared
    private init() {}

    // MARK: - Send Message
    func sendMessage(_ message: MessageModel, completion: @escaping (Error?) -> Void) {
        manager.messagesCollection(matchId: message.matchId)
            .addDocument(data: message.toFirestoreData(), completion: completion)
    }

    // MARK: - Listen to Messages
    func listenToMessages(matchId: String, completion: @escaping (Result<[MessageModel], Error>) -> Void) -> ListenerRegistration {
        return manager.messagesCollection(matchId: matchId)
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                let messages: [MessageModel] = snapshot?.documents.compactMap {
                    MessageModel.from($0, matchId: matchId)
                } ?? []
                completion(.success(messages))
            }
    }
}

