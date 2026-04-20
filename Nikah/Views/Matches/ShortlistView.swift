import SwiftUI

struct ShortlistView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var shortlistVM = ShortlistViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if shortlistVM.isLoading {
                    ProgressView("Loading shortlist...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if shortlistVM.users.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(shortlistVM.users) { user in
                            NavigationLink {
                                ProfileDetailView(user: user)
                                    .environmentObject(authVM)
                            } label: {
                                HStack(spacing: 12) {
                                    Group {
                                        if let photoURL = user.firstPhoto, let url = URL(string: photoURL) {
                                            AsyncImage(url: url) { phase in
                                                if case .success(let image) = phase {
                                                    image.resizable().scaledToFill()
                                                } else {
                                                    Color(.systemGray4)
                                                }
                                            }
                                        } else {
                                            Color(.systemGray4)
                                        }
                                    }
                                    .frame(width: 54, height: 54)
                                    .clipShape(Circle())

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(user.displayName)
                                            .font(.headline)
                                        Text("\(user.age), \(user.district)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    if let myId = authVM.currentUser?.id,
                                       let targetId = user.id {
                                        shortlistVM.removeFromShortlist(currentUserId: myId, targetUserId: targetId)
                                    }
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Shortlist")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                if let uid = authVM.currentUser?.id {
                    shortlistVM.loadShortlistedUsers(currentUserId: uid)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "star.slash")
                .font(.system(size: 54))
                .foregroundColor(.secondary.opacity(0.5))

            Text("No Shortlisted Profiles")
                .font(.title3.bold())

            Text("Tap the star icon on profile cards to keep favorites here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
