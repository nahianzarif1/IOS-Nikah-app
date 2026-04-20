// Views/Feed/HomeFeedView.swift

import SwiftUI

struct HomeFeedView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var feedVM = FeedViewModel()
    @State private var showFilters = false
    @State private var showMatchAlert = false


    var body: some View {
        NavigationStack {
            ZStack {
                Color.nikahBackground.ignoresSafeArea()

                if let currentUser = authVM.currentUser {
                    if !currentUser.isProfileReady {
                        incompleteProfileView
                    } else if feedVM.isLoading {
                        loadingView
                    } else if !feedVM.hasProfiles {
                        emptyFeedView
                    } else {
                        feedStack(currentUser: currentUser)
                    }
                }
            }
            .navigationTitle("Nikah")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showFilters = true
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.title3)
                            if !feedVM.filter.isDefault {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 4, y: -4)
                            }
                        }
                    }
                    .foregroundColor(.nikahGreen)
                }
            }
            .sheet(isPresented: $showFilters) {
                FilterView(filter: feedVM.filter) { newFilter in
                    if let user = authVM.currentUser {
                        feedVM.applyFilter(newFilter, currentUser: user)
                    }
                }
            }
            .alert("Interest Matched", isPresented: $feedVM.matchAlert) {
                Button("View Matches") {}
                Button("Keep Swiping", role: .cancel) {}
            } message: {
                Text("You and \(feedVM.matchedUserName) both expressed interest.")
            }
            .onAppear {
                if let user = authVM.currentUser {
                    feedVM.loadFeed(currentUser: user)
                }
            }
        }
    }

    // MARK: - Feed Stack
    private func feedStack(currentUser: UserModel) -> some View {
        ZStack {
            // Show next card behind
            if feedVM.currentIndex + 1 < feedVM.profiles.count {
                let nextUser = feedVM.profiles[feedVM.currentIndex + 1]
                ProfileCardView(user: nextUser, onLike: {}, onPass: {}, onShortlist: {})
                    .padding(.horizontal, 24)
                    .scaleEffect(0.95)
                    .offset(y: 12)
            }

            // Current card
            if let profile = feedVM.currentProfile {
                ProfileCardView(
                    user: profile,
                    onLike: {
                        feedVM.likeCurrentProfile(currentUser: currentUser)
                    },
                    onPass: {
                        feedVM.passCurrentProfile()
                    },
                    onShortlist: {
                        feedVM.toggleShortlistForCurrentProfile(currentUser: currentUser)
                    }
                )
                .overlay(alignment: .topLeading) {
                    if feedVM.isCurrentProfileShortlisted() {
                        Label("Shortlisted", systemImage: "star.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.nikahMaroon)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.nikahCream.opacity(0.95))
                            .clipShape(Capsule())
                            .padding(.top, 14)
                            .padding(.leading, 14)
                    }
                }
                .padding(.horizontal, 16)
                .id(feedVM.currentIndex)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.95)),
                    removal: .opacity
                ))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: feedVM.currentIndex)
        .padding(.vertical, 20)
    }

    // MARK: - Incomplete Profile View
    private var incompleteProfileView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.exclamationmark.fill")
                .font(.system(size: 72))
                .foregroundColor(.orange)

            Text("Complete Your Profile")
                .font(.title2)
                .fontWeight(.bold)

            Text("Please add your photo, district, age, and guardian contact to access the feed.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            NavigationLink {
                if let user = authVM.currentUser {
                    CreateProfileView(user: user)
                        .environmentObject(authVM)
                }
            } label: {
                Text("Complete Biodata")
                    .nikahButton()
                    .padding(.horizontal, 40)
            }
        }
        .padding()
    }

    // MARK: - Loading
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Finding profiles...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Empty Feed
    private var emptyFeedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3.sequence.fill")
                .font(.system(size: 72))
                .foregroundColor(.nikahGreen.opacity(0.5))

            Text("No profiles found")
                .font(.title2)
                .fontWeight(.bold)

            Text("Try removing some filters or check back later.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                if !feedVM.filter.isDefault {
                    feedVM.filter = FilterModel()
                }
                if let user = authVM.currentUser {
                    feedVM.loadFeed(currentUser: user)
                }
            } label: {
                Text("Refresh")
                    .nikahButton()
                    .padding(.horizontal, 60)
            }
        }
        .padding()
    }
}
