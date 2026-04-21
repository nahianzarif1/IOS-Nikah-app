//
//  ContentView.swift
//  Nikah
//
//  Created by Nahian Zarif on 9/3/26.
//

import SwiftUI
import Combine
import Firebase
import FirebaseFirestore

// MARK: - Root View (Auth Gate)
struct RootView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        Group {
            if authVM.isLoggedIn {
                if let user = authVM.currentUser {
                    if user.profileCompleted {
                        MainTabView()
                            .environmentObject(authVM)
                    } else {
                        NavigationStack {
                            CreateProfileView(user: user)
                                .environmentObject(authVM)
                        }
                    }
                } else {
                    // Loading user data
                    VStack(spacing: 16) {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.nikahGreen)
                        Text("Nikah")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.nikahGreen)
                        if let err = authVM.errorMessage, !err.isEmpty {
                            Text("Could not load your profile")
                                .font(.headline)
                            Text(err)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)

                            HStack(spacing: 12) {
                                Button("Retry") {
                                    authVM.refresh()
                                }
                                .nikahButton(color: .nikahGreen)

                                Button("Log out") {
                                    authVM.logout()
                                }
                                .nikahButton(color: Color(.systemGray5), textColor: .nikahGreen)
                            }
                            .padding(.horizontal, 24)
                        } else {
                            ProgressView()
                                .padding(.top, 8)
                        }
                    }
                }
            } else {
                LoginView()
                    .environmentObject(authVM)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: authVM.isLoggedIn)
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        TabView {
            HomeFeedView()
                .environmentObject(authVM)
                .tabItem {
                    Label("Discover", systemImage: "heart.circle.fill")
                }

            RequestListView()
                .environmentObject(authVM)
                .tabItem {
                    Label("Requests", systemImage: "envelope.fill")
                }

            MatchListView()
                .environmentObject(authVM)
                .tabItem {
                    Label("Matches", systemImage: "star.fill")
                }

            ShortlistView()
                .environmentObject(authVM)
                .tabItem {
                    Label("Shortlist", systemImage: "star.circle.fill")
                }

            ChatListView()
                .environmentObject(authVM)
                .tabItem {
                    Label("Messages", systemImage: "bubble.left.and.bubble.right.fill")
                }

            CommunityHubView()
                .environmentObject(authVM)
                .tabItem {
                    Label("Community", systemImage: "person.3.fill")
                }

            SettingsView()
                .environmentObject(authVM)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(.nikahGreen)
    }
}

struct CommunityPostModel: Identifiable {
    let id: String
    let authorName: String
    let body: String
    let createdAt: Date

    static func fromDocument(_ document: DocumentSnapshot) -> CommunityPostModel? {
        guard let data = document.data() else { return nil }
        return CommunityPostModel(
            id: document.documentID,
            authorName: data["authorName"] as? String ?? "Member",
            body: data["body"] as? String ?? "",
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
}

@MainActor
final class CommunityHubViewModel: ObservableObject {
    @Published var posts: [CommunityPostModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var newPostText = ""
    @Published var supportMessage = ""
    @Published var successStoriesCount = 0
    @Published var usersCount = 0
    @Published var matchesCount = 0
    @Published var maleUsersCount = 0
    @Published var femaleUsersCount = 0

    private let manager = FirebaseManager.shared

    func loadAll() {
        loadCommunityPosts()
        loadSuccessStats()
    }

    func loadCommunityPosts() {
        isLoading = true
        manager.communityPostsCollection
            .order(by: "createdAt", descending: true)
            .limit(to: 40)
            .getDocuments { [weak self] snapshot, error in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.isLoading = false
                    if let error {
                        self.errorMessage = error.localizedDescription
                        return
                    }
                    self.posts = snapshot?.documents.compactMap(CommunityPostModel.fromDocument) ?? []
                }
            }
    }

    func createPost(authorName: String) {
        let body = newPostText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else { return }

        manager.communityPostsCollection.addDocument(data: [
            "authorName": authorName,
            "body": body,
            "createdAt": Timestamp(date: Date())
        ]) { [weak self] error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                self.newPostText = ""
                self.loadCommunityPosts()
            }
        }
    }

    func submitSupportTicket(userId: String) {
        let message = supportMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }

        manager.supportTicketsCollection.addDocument(data: [
            "userId": userId,
            "message": message,
            "status": "open",
            "createdAt": Timestamp(date: Date())
        ]) { [weak self] error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                self.supportMessage = ""
            }
        }
    }

    private func loadSuccessStats() {
        manager.successStoriesCollection.getDocuments { [weak self] snapshot, _ in
            Task { @MainActor [weak self] in
                self?.successStoriesCount = snapshot?.documents.count ?? 0
            }
        }

        manager.usersCollection.getDocuments { [weak self] snapshot, _ in
            Task { @MainActor [weak self] in
                self?.usersCount = snapshot?.documents.count ?? 0
            }
        }

        manager.usersCollection.whereField("gender", isEqualTo: "male").getDocuments { [weak self] snapshot, _ in
            Task { @MainActor [weak self] in
                self?.maleUsersCount = snapshot?.documents.count ?? 0
            }
        }

        manager.usersCollection.whereField("gender", isEqualTo: "female").getDocuments { [weak self] snapshot, _ in
            Task { @MainActor [weak self] in
                self?.femaleUsersCount = snapshot?.documents.count ?? 0
            }
        }

        manager.matchesCollection.getDocuments { [weak self] snapshot, _ in
            Task { @MainActor [weak self] in
                self?.matchesCount = snapshot?.documents.count ?? 0
            }
        }
    }
}

struct CommunityHubView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = CommunityHubViewModel()
    @State private var selectedSection = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Picker("Hub", selection: $selectedSection) {
                    Text("Community").tag(0)
                    Text("Support").tag(1)
                    Text("Success").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if selectedSection == 0 {
                    communitySection
                } else if selectedSection == 1 {
                    supportSection
                } else {
                    successSection
                }
            }
            .navigationTitle("Community Hub")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Error", isPresented: Binding(
                get: { vm.errorMessage != nil },
                set: { if !$0 { vm.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(vm.errorMessage ?? "Unknown error")
            }
            .onAppear {
                vm.loadAll()
            }
        }
    }

    private var communitySection: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                TextField("Share a community note...", text: $vm.newPostText, axis: .vertical)
                    .lineLimit(1...3)
                    .padding(10)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)

                Button("Post") {
                    vm.createPost(authorName: authVM.currentUser?.displayName.isEmpty == false ? authVM.currentUser?.displayName ?? "Member" : "Member")
                }
                .buttonStyle(.borderedProminent)
                .tint(.nikahGreen)
            }
            .padding(.horizontal)

            if vm.isLoading {
                Spacer()
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Loading community posts...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else if vm.posts.isEmpty {
                emptyCommunityState
            } else {
                List(vm.posts) { post in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(post.authorName)
                            .font(.headline)
                        Text(post.body)
                            .font(.subheadline)
                        Text(post.createdAt.timeAgoDisplay)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.plain)
            }
        }
    }

    private var emptyCommunityState: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.3.sequence.fill")
                .font(.system(size: 44))
                .foregroundColor(.secondary.opacity(0.5))
            Text("No community posts yet")
                .font(.headline)
            Text("Be the first to share a helpful note or ask a marriage-related question.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 24)
    }

    private var supportSection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Support Team")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("Report any issue and our team will review your ticket.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                TextEditor(text: $vm.supportMessage)
                    .frame(height: 140)
                    .padding(8)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)

                Button {
                    if let myId = authVM.currentUser?.id {
                        vm.submitSupportTicket(userId: myId)
                    }
                } label: {
                    Text("Submit Ticket")
                        .nikahButton()
                }

                Text("We usually respond to tickets through app updates and backend review.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }

    private var successSection: some View {
        ScrollView {
            VStack(spacing: 12) {
                StatCard(title: "Success Stories", value: "\(vm.successStoriesCount)", subtitle: "Verified outcomes shared")
                StatCard(title: "Total Members", value: "\(vm.usersCount)", subtitle: "Biodata profiles available")
                StatCard(title: "Male Profiles", value: "\(vm.maleUsersCount)", subtitle: "Available for matchmaking")
                StatCard(title: "Female Profiles", value: "\(vm.femaleUsersCount)", subtitle: "Available for matchmaking")
                StatCard(title: "Accepted Matches", value: "\(vm.matchesCount)", subtitle: "Families connected")

                VStack(alignment: .leading, spacing: 10) {
                    Text("Trust Snapshot")
                        .font(.headline)
                    Text("This dashboard is meant to show the platform's marriage success activity at a glance.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(14)
            }
            .padding()
        }
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.nikahMaroon)
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.nikahCream)
        .cornerRadius(14)
    }
}

// MARK: - Legacy ContentView (kept for compatibility)
struct ContentView: View {
    var body: some View {
        RootView()

        
    }
}

#Preview {
    ContentView().environmentObject(AuthViewModel())
}

