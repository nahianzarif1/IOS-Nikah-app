// Views/Matches/MatchListView.swift

import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

struct MatchListView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var chatVM = ChatViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if chatVM.isLoading {
                    ProgressView("Loading matches...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if chatVM.matches.isEmpty {
                    emptyMatchesView
                } else {
                    matchList
                }
            }
            .navigationTitle("Matches")
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

    private var matchList: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 16
            ) {
                ForEach(chatVM.matches) { match in
                    if let otherId = match.otherUserId(currentUserId: authVM.currentUser?.id ?? ""),
                       let otherUser = chatVM.matchedUsers[otherId] {
                        NavigationLink {
                            ChatDetailView(match: match, otherUser: otherUser)
                                .environmentObject(authVM)
                        } label: {
                            MatchCardView(user: otherUser)
                        }
                    } else {
                        MatchCardPlaceholder()
                    }
                }
            }
            .padding()
        }
        .background(Color.nikahBackground)
    }

    private var emptyMatchesView: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.slash.fill")
                .font(.system(size: 72))
                .foregroundColor(.secondary.opacity(0.4))

            Text("No Matches Yet")
                .font(.title2)
                .fontWeight(.bold)

            Text("Start liking profiles to get matches!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Match Card View
struct MatchCardView: View {
    let user: UserModel

    var body: some View {
        VStack(spacing: 8) {
            // Photo
            Group {
                if let photoUrl = user.firstPhoto, let url = URL(string: photoUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable().scaledToFill()
                        default:
                            Color(.systemGray5)
                                .overlay(Image(systemName: "person.fill").foregroundColor(.secondary))
                        }
                    }
                } else {
                    Color(.systemGray5)
                        .overlay(Image(systemName: "person.fill").foregroundColor(.secondary).font(.title))
                }
            }
            .frame(width: 150, height: 150)
            .clipped()
            .cornerRadius(20)

            VStack(spacing: 2) {
                Text(user.displayName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Text(user.district)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
    }
}

struct MatchCardPlaceholder: View {
    var body: some View {
        VStack(spacing: 8) {
            Color(.systemGray5)
                .frame(width: 150, height: 150)
                .cornerRadius(20)
                .overlay(ProgressView())
            Text("Loading...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(8)
    }
}
