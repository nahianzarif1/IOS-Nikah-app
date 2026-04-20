import Foundation
import FirebaseFirestore

@MainActor
final class RequestViewModel: ObservableObject {
    @Published var incomingRequests: [InterestRequestModel] = []
    @Published var requestUsers: [String: UserModel] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var listener: ListenerRegistration?

    func startListening(userId: String) {
        isLoading = true
        listener?.remove()

        listener = RequestService.shared.listenToIncomingRequests(userId: userId) { [weak self] result in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isLoading = false
                switch result {
                case .success(let requests):
                    self.incomingRequests = requests
                    self.preloadRequestUsers()
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    func accept(_ request: InterestRequestModel) {
        guard let requestId = request.id else { return }
        RequestService.shared.updateRequestStatus(requestId: requestId, status: .accepted) { [weak self] result in
            Task { @MainActor [weak self] in
                if case .failure(let error) = result {
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func reject(_ request: InterestRequestModel) {
        guard let requestId = request.id else { return }
        RequestService.shared.updateRequestStatus(requestId: requestId, status: .rejected) { [weak self] result in
            Task { @MainActor [weak self] in
                if case .failure(let error) = result {
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func preloadRequestUsers() {
        for request in incomingRequests where requestUsers[request.fromUserId] == nil {
            UserService.shared.fetchUser(uid: request.fromUserId) { [weak self] result in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    if case .success(let user) = result {
                        self.requestUsers[request.fromUserId] = user
                    }
                }
            }
        }
    }
}
