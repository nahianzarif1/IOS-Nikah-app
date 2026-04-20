import Foundation
import FirebaseFirestore

final class RequestService {
    static let shared = RequestService()
    private let manager = FirebaseManager.shared

    private init() {}

    func listenToIncomingRequests(userId: String, completion: @escaping (Result<[InterestRequestModel], Error>) -> Void) -> ListenerRegistration {
        manager.requestsCollection
            .whereField("toUserId", isEqualTo: userId)
            .whereField("status", isEqualTo: RequestStatus.pending.rawValue)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                let requests = snapshot?.documents.compactMap(InterestRequestModel.from) ?? []
                completion(.success(requests))
            }
    }

    func updateRequestStatus(requestId: String, status: RequestStatus, completion: @escaping (Result<Void, Error>) -> Void) {
        manager.requestsCollection.document(requestId).updateData([
            "status": status.rawValue,
            "updatedAt": Timestamp(date: Date())
        ]) { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                completion(.failure(error))
                return
            }

            guard status == .accepted else {
                completion(.success(()))
                return
            }

            self.manager.requestsCollection.document(requestId).getDocument { snapshot, fetchError in
                if let fetchError = fetchError {
                    completion(.failure(fetchError))
                    return
                }

                guard let document = snapshot,
                      let request = InterestRequestModel.from(document) else {
                    completion(.failure(NSError(domain: "RequestService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Request not found"])) )
                    return
                }

                MatchService.shared.ensureMatch(userId1: request.fromUserId, userId2: request.toUserId) { matchResult in
                    switch matchResult {
                    case .success:
                        completion(.success(()))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
        }
    }
}
