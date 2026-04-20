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
                // Block app access until the user verifies their email.
                if authVM.isEmailVerified == false && authVM.shouldBypassEmailVerification == false {
                    EmailVerificationView()
                        .environmentObject(authVM)
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
                    // Loading user data
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
            } else {
                LoginView()
                    .environmentObject(authVM)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: authVM.isLoggedIn)
        .animation(.easeInOut(duration: 0.25), value: authVM.isEmailVerified)
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

