// ViewModels/ChatViewModel.swift

import Foundation
import SwiftUI
import Combine
import FirebaseFirestore

@MainActor
final class ChatViewModel: ObservableObject {

    @Published var matches: [MatchModel] = []
    @Published var matchedUsers: [String: UserModel] = [:]
    @Published var matchedUsersByMatchId: [String: UserModel] = [:]
    @Published var messages: [MessageModel] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private var matchesListener: ListenerRegistration?
    private var messagesListener: ListenerRegistration?
    private var activeMatchesRequestID = UUID()

    // MARK: - Listen to Matches
    func startListeningToMatches(userId: String) {
        isLoading = true
        matchesListener = MatchService.shared.fetchMatches(userId: userId) { [weak self] result in
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch result {
                case .success(let matches):
                    self.matches = matches
                    self.fetchMatchedUsers(matches: matches, currentUserId: userId)
                case .failure(let error):
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Fetch Users for Matches
    private func fetchMatchedUsers(matches: [MatchModel], currentUserId: String) {
        let requestID = UUID()
        activeMatchesRequestID = requestID

        let snapshotUsersByMatchId = matches.reduce(into: [String: UserModel]()) { partial, match in
            guard let matchId = match.id,
                  let user = match.otherUser(currentUserId: currentUserId) else {
                return
            }
            partial[matchId] = user
        }

        let snapshotUsersById: [String: UserModel] = Dictionary(uniqueKeysWithValues: snapshotUsersByMatchId.values.compactMap { user -> (String, UserModel)? in
            guard let id = user.id else { return nil }
            return (id, user)
        })

        let otherUserIdsByMatchId = matches.reduce(into: [String: String]()) { partial, match in
            guard let matchId = match.id,
                  let otherUserId = match.otherUserId(currentUserId: currentUserId) else { return }
            partial[matchId] = otherUserId
        }

        let staleMatchIDs = Set(matchedUsersByMatchId.keys).subtracting(otherUserIdsByMatchId.keys)
        for matchID in staleMatchIDs {
            matchedUsersByMatchId.removeValue(forKey: matchID)
        }

        let otherUserIds = Array(Set(otherUserIdsByMatchId.values))
        guard !otherUserIds.isEmpty else {
            matchedUsers = snapshotUsersById
            matchedUsersByMatchId = snapshotUsersByMatchId
            isLoading = false
            errorMessage = matches.isEmpty ? nil : "Some matches are invalid and could not be loaded."
            return
        }

        if snapshotUsersByMatchId.count == matches.count {
            matchedUsers = snapshotUsersById
            matchedUsersByMatchId = snapshotUsersByMatchId
            isLoading = false
            errorMessage = nil
            return
        }

        let unresolvedUserIds = otherUserIds.filter { snapshotUsersById[$0] == nil }
        guard !unresolvedUserIds.isEmpty else {
            matchedUsers = snapshotUsersById
            matchedUsersByMatchId = snapshotUsersByMatchId
            isLoading = false
            errorMessage = nil
            return
        }

        UserService.shared.fetchUsers(uids: otherUserIds) { [weak self] result in
            Task { @MainActor [weak self] in
                guard let self else { return }
                guard self.activeMatchesRequestID == requestID else { return }

                self.isLoading = false

                switch result {
                case .failure(let error):
                    self.errorMessage = error.localizedDescription

                case .success(let usersById):
                    let resolvedUsersById = snapshotUsersById.merging(usersById) { current, _ in current }
                    self.matchedUsers = resolvedUsersById
                    self.matchedUsersByMatchId = otherUserIdsByMatchId.reduce(into: snapshotUsersByMatchId) { partial, item in
                        let (matchId, otherUserId) = item
                        if let user = resolvedUsersById[otherUserId] {
                            partial[matchId] = user
                        }
                    }

                    let missingUserIDs = Set(otherUserIds).subtracting(resolvedUsersById.keys)
                    if !missingUserIDs.isEmpty {
                        self.errorMessage = "Some matched profiles could not be loaded."
                    } else if self.matchedUsersByMatchId.count != matches.count {
                        self.errorMessage = "Some matches are invalid and could not be loaded."
                    } else {
                        self.errorMessage = nil
                    }
                }
            }
        }
    }

    // MARK: - Listen to Messages
    func startListeningToMessages(matchId: String, userId: String) {
        messagesListener?.remove()
        messages = []
        MatchService.shared.validateChatAccess(matchId: matchId, userId: userId) { [weak self] validation in
            Task { @MainActor [weak self] in
                guard let self else { return }

                switch validation {
                case .failure(let error):
                    self.errorMessage = error.localizedDescription

                case .success:
                    self.errorMessage = nil
                    self.messagesListener = ChatService.shared.listenToMessages(matchId: matchId) { [weak self] result in
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
        ChatService.shared.sendMessage(message) { [weak self] error in
            Task { @MainActor [weak self] in
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    print("Send message error: \(error.localizedDescription)")
                } else {
                    self?.errorMessage = nil
                }
            }
        }
    }

    // MARK: - Stop Listeners
    func stopListening() {
        matchesListener?.remove()
        messagesListener?.remove()
        activeMatchesRequestID = UUID()
    }

    // deinit cannot call @MainActor methods — detach listeners directly
    deinit {
        matchesListener?.remove()
        messagesListener?.remove()
    }
}
