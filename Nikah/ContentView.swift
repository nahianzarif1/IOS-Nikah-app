//
//  ContentView.swift
//  Nikah
//
//  Created by Nahian Zarif on 9/3/26.
//

import SwiftUI
import Firebase
import FirebaseFirestore

// MARK: - Root View (Auth Gate)
struct RootView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        Group {
            if authVM.isLoggedIn {
                if authVM.isLoading && authVM.currentUser == nil {
                    sessionLoadingView
                } else if let user = authVM.currentUser {
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
                    sessionRecoveryView
                }
            } else {
                LoginView()
                    .environmentObject(authVM)
            }
        }
    }

    private var sessionLoadingView: some View {
        VStack(spacing: 16) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 60))
                .foregroundColor(.nikahGreen)
            Text("Nikah")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.nikahGreen)
            ProgressView()
                .padding(.top, 8)
        }
    }

    private var sessionRecoveryView: some View {
        VStack(spacing: 16) {
            Image(systemName: "icloud.slash")
                .font(.system(size: 54))
                .foregroundColor(.orange)

            Text("We couldn't load your account")
                .font(.title3)
                .fontWeight(.semibold)

            Text(authVM.errorMessage ?? "Please try again.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button("Try Again") {
                authVM.refresh()
            }
            .nikahButton()
            .padding(.horizontal, 32)

            Button("Sign Out") {
                authVM.logout()
            }
            .foregroundColor(.nikahGreen)
        }
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

            MatchListView()
                .environmentObject(authVM)
                .tabItem {
                    Label("Matches", systemImage: "star.fill")
                }

            ChatListView()
                .environmentObject(authVM)
                .tabItem {
                    Label("Messages", systemImage: "bubble.left.and.bubble.right.fill")
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

// MARK: - Legacy ContentView (kept for compatibility)
struct ContentView: View {
    var body: some View {
        RootView()
    }
}


#Preview {
    ContentView().environmentObject(AuthViewModel())
}
