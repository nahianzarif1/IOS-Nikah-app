// ViewModels/ChatViewModel.swift

import Foundation
import SwiftUI
import Combine
import FirebaseFirestore

@MainActor
final class ChatViewModel: ObservableObject {

    @Published var matches: [MatchModel] = []
    @Published var matchedUsers: [String: UserModel] = [:]
    @Published var messages: [MessageModel] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private var matchesListener: ListenerRegistration?
    private var messagesListener: ListenerRegistration?

    // MARK: - Listen to Matches
    func startListeningToMatches(userId: String) {
        isLoading = true
        matchesListener = MatchService.shared.fetchMatches(userId: userId) { [weak self] result in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isLoading = false
                switch result {
                case .success(let matches):
                    self.matches = matches
                    self.fetchMatchedUsers(matches: matches, currentUserId: userId)
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Fetch Users for Matches
    private func fetchMatchedUsers(matches: [MatchModel], currentUserId: String) {
        for match in matches {
            if let otherId = match.otherUserId(currentUserId: currentUserId),
               matchedUsers[otherId] == nil {
                UserService.shared.fetchUser(uid: otherId) { [weak self] result in
                    Task { @MainActor [weak self] in
                        guard let self else { return }
                        if case .success(let user) = result {
                            self.matchedUsers[otherId] = user
                        }
                    }
                }
            }
        }
    }

    // MARK: - Listen to Messages
    func startListeningToMessages(matchId: String) {
        messagesListener?.remove()
        messagesListener = ChatService.shared.listenToMessages(matchId: matchId) { [weak self] result in
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch result {
                case .success(let msgs):
                    self.messages = msgs
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Send Message
    func sendMessage(matchId: String, senderId: String, text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let message = MessageModel(
            matchId: matchId,
            senderId: senderId,
            text: trimmed,
            timestamp: Date()
        )
        ChatService.shared.sendMessage(message) { error in
            if let error = error {
                print("Send message error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Stop Listeners
    func stopListening() {
        matchesListener?.remove()
        messagesListener?.remove()
    }

    // deinit cannot call @MainActor methods — detach listeners directly
    deinit {
        matchesListener?.remove()
        messagesListener?.remove()
    }
}
