import SwiftUI

struct RequestListView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var requestVM = RequestViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if requestVM.isLoading {
                    ProgressView("Loading requests...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if requestVM.incomingRequests.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(requestVM.incomingRequests) { request in
                            if let user = requestVM.requestUsers[request.fromUserId] {
                                RequestRow(user: user) {
                                    requestVM.accept(request)
                                } onReject: {
                                    requestVM.reject(request)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Requests")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                if let uid = authVM.currentUser?.id {
                    requestVM.startListening(userId: uid)
                }
            }
            .onDisappear {
                requestVM.stopListening()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "envelope.open")
                .font(.system(size: 54))
                .foregroundColor(.secondary.opacity(0.5))

            Text("No Requests Yet")
                .font(.title3.bold())

            Text("When someone expresses interest, you can accept or decline from here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct RequestRow: View {
    let user: UserModel
    let onAccept: () -> Void
    let onReject: () -> Void

    var body: some View {
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
            .frame(width: 56, height: 56)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayName)
                    .font(.headline)
                Text("\(user.age), \(user.district)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button("Decline", role: .destructive, action: onReject)
                .font(.caption.bold())

            Button("Accept", action: onAccept)
                .font(.caption.bold())
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.nikahGreen)
                .clipShape(Capsule())
        }
        .padding(.vertical, 4)
    }
}
