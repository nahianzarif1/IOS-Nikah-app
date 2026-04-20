import Foundation
import FirebaseFirestore

final class ShortlistService {
    static let shared = ShortlistService()
    private let manager = FirebaseManager.shared

    private init() {}

    func fetchShortlistedUserIds(fromUserId: String, completion: @escaping ([String]) -> Void) {
        manager.shortlistsCollection
            .whereField("fromUserId", isEqualTo: fromUserId)
            .getDocuments { snapshot, _ in
                let ids = snapshot?.documents.compactMap {
                    $0.data()["toUserId"] as? String
                } ?? []
                completion(ids)
            }
    }

    func setShortlisted(fromUserId: String, toUserId: String, isShortlisted: Bool, completion: @escaping (Error?) -> Void) {
        let query = manager.shortlistsCollection
            .whereField("fromUserId", isEqualTo: fromUserId)
            .whereField("toUserId", isEqualTo: toUserId)

        query.getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            if let error = error {
                completion(error)
                return
            }

            let existingDocs = snapshot?.documents ?? []

            if isShortlisted {
                if existingDocs.isEmpty {
                    self.manager.shortlistsCollection.addDocument(data: [
                        "fromUserId": fromUserId,
                        "toUserId": toUserId,
                        "createdAt": Timestamp(date: Date())
                    ], completion: completion)
                } else {
                    completion(nil)
                }
            } else {
                let batch = self.manager.firestore.batch()
                for doc in existingDocs {
                    batch.deleteDocument(doc.reference)
                }
                batch.commit(completion: completion)
            }
        }
    }
}
