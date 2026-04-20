// Views/Chat/ChatDetailView.swift

import SwiftUI

struct ChatDetailView: View {
    let match: MatchModel
    let otherUser: UserModel
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var chatVM = ChatViewModel()
    @State private var messageText: String = ""
    @State private var showVoiceNoteInfo = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // MARK: Message List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(chatVM.messages) { message in
                            MessageBubble(
                                message: message,
                                isFromCurrentUser: message.senderId == authVM.currentUser?.id
                            )
                            .id(message.id)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .onChange(of: chatVM.messages.count) {
                    if let lastId = chatVM.messages.last?.id {
                        withAnimation {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            // MARK: Input Bar
            HStack(spacing: 10) {
                Button {
                    showVoiceNoteInfo = true
                } label: {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.nikahMaroon)
                        .frame(width: 38, height: 38)
                        .background(Color.nikahCream)
                        .clipShape(Circle())
                }

                TextField("Type a message...", text: $messageText, axis: .vertical)
                    .lineLimit(1...5)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                    .focused($isInputFocused)

                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 42, height: 42)
                        .background(messageText.trimmed.isEmpty ? Color(.systemGray4) : Color.nikahGreen)
                        .clipShape(Circle())
                }
                .disabled(messageText.trimmed.isEmpty)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.systemBackground))
        }
        .navigationTitle(otherUser.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    ProfileDetailView(user: otherUser)
                        .environmentObject(authVM)
                } label: {
                    Group {
                        if let url = otherUser.firstPhoto.flatMap({ URL(string: $0) }) {
                            AsyncImage(url: url) { phase in
                                if case .success(let img) = phase {
                                    img.resizable().scaledToFill()
                                } else {
                                    Color(.systemGray4)
                                }
                            }
                        } else {
                            Color(.systemGray4)
                        }
                    }
                    .frame(width: 34, height: 34)
                    .clipShape(Circle())
                }
            }
        }
        .onAppear {
            if let matchId = match.id {
                chatVM.startListeningToMessages(matchId: matchId)
            }
        }
        .alert("Voice Notes", isPresented: $showVoiceNoteInfo) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Voice note messaging is in progress and will be available in an upcoming update.")
        }
        .onDisappear {
            chatVM.stopListening()
        }
    }

    private func sendMessage() {
        guard let matchId = match.id,
              let senderId = authVM.currentUser?.id else { return }
        chatVM.sendMessage(matchId: matchId, senderId: senderId, text: messageText)
        messageText = ""
    }
}

// MARK: - Message Bubble
struct MessageBubble: View {
    let message: MessageModel
    let isFromCurrentUser: Bool

    var body: some View {
        HStack {
            if isFromCurrentUser { Spacer(minLength: 60) }

            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(.system(size: 15))
                    .foregroundColor(isFromCurrentUser ? .white : .primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(isFromCurrentUser ? Color.nikahGreen : Color(.systemGray5))
                    .cornerRadius(18, corners: isFromCurrentUser
                        ? [.topLeft, .topRight, .bottomLeft]
                        : [.topLeft, .topRight, .bottomRight]
                    )

                Text(message.timestamp.timeAgoDisplay)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }

            if !isFromCurrentUser { Spacer(minLength: 60) }
        }
    }
}
