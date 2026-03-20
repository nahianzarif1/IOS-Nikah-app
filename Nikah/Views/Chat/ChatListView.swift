// Views/Chat/ChatListView.swift

import SwiftUI

struct ChatListView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var chatVM = ChatViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if chatVM.isLoading {
                    ProgressView("Loading chats...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if chatVM.matches.isEmpty {
                    emptyChatView
                } else {
                    chatList
                }
            }
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                if let uid = authVM.currentUser?.id {
                    chatVM.startListeningToMatches(userId: uid)
                }
            }
            .onDisappear {
                chatVM.stopListening()
            }
        }
    }

    private var chatList: some View {
        List {
            ForEach(chatVM.matches) { match in
                if let otherId = match.otherUserId(currentUserId: authVM.currentUser?.id ?? ""),
                   let otherUser = chatVM.matchedUsers[otherId] {
                    NavigationLink {
                        ChatDetailView(match: match, otherUser: otherUser)
                            .environmentObject(authVM)
                    } label: {
                        ChatRowView(user: otherUser, match: match)
                    }
                    .listRowSeparator(.visible)
                }
            }
        }
        .listStyle(.plain)
    }

    private var emptyChatView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 64))
                .foregroundColor(.secondary.opacity(0.4))
            Text("No Messages Yet")
                .font(.title2).fontWeight(.bold)
            Text("Match with someone to start chatting!")
                .font(.subheadline).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Chat Row
struct ChatRowView: View {
    let user: UserModel
    let match: MatchModel

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Group {
                if let url = user.firstPhoto.flatMap({ URL(string: $0) }) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img): img.resizable().scaledToFill()
                        default: Color(.systemGray4)
                        }
                    }
                } else {
                    Color(.systemGray4)
                        .overlay(Image(systemName: "person.fill").foregroundColor(.secondary))
                }
            }
            .frame(width: 56, height: 56)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(user.displayName)
                    .font(.system(size: 16, weight: .semibold))
                Text("Tap to chat")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(match.createdAt.timeAgoDisplay)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 6)
    }
}
