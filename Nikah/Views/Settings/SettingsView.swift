// Views/Settings/SettingsView.swift

import SwiftUI
import Combine

struct SettingsView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var showEditProfile = false
    @State private var showDeleteConfirm = false
    @State private var showLogoutConfirm = false
    @State private var showPrivacy = false

    var body: some View {
        NavigationStack {
            List {
                // MARK: Profile Section
                if let user = authVM.currentUser {
                    Section {
                        HStack(spacing: 14) {
                            Group {
                                if let url = user.firstPhoto.flatMap({ URL(string: $0) }) {
                                    AsyncImage(url: url) { phase in
                                        if case .success(let img) = phase {
                                            img.resizable().scaledToFill()
                                        } else {
                                            Color(.systemGray4)
                                        }
                                    }
                                } else {
                                    Color(.systemGray4)
                                        .overlay(Image(systemName: "person.fill").foregroundColor(.secondary))
                                }
                            }
                            .frame(width: 64, height: 64)
                            .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.displayName.isEmpty ? "Your Name" : user.displayName)
                                    .font(.system(size: 18, weight: .semibold))
                                Text(user.profession.isEmpty ? "Add profession" : user.profession)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                if user.isVerified {
                                    Label("Verified", systemImage: "checkmark.seal.fill")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }

                // MARK: Account
                Section(header: Text("Account")) {
                    Button {
                        showEditProfile = true
                    } label: {
                        Label("Edit Profile", systemImage: "person.crop.circle.fill.badge.plus")
                            .foregroundColor(.primary)
                    }

                    Button {
                        showPrivacy = true
                    } label: {
                        Label("Privacy & Safety", systemImage: "lock.shield.fill")
                            .foregroundColor(.primary)
                    }
                }

                // MARK: App
                Section(header: Text("App")) {
                    HStack {
                        Label("Version", systemImage: "info.circle.fill")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Label("Gender", systemImage: "person.2.fill")
                        Spacer()
                        Text(authVM.currentUser?.gender.capitalized ?? "—")
                            .foregroundColor(.secondary)
                    }
                }

                // MARK: Danger Zone
                Section(header: Text("Account Actions")) {
                    Button {
                        showLogoutConfirm = true
                    } label: {
                        Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right.fill")
                            .foregroundColor(.orange)
                    }

                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete Account", systemImage: "trash.fill")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            // Edit Profile Sheet
            .sheet(isPresented: $showEditProfile) {
                if let user = authVM.currentUser {
                    EditProfileView(user: user)
                        .environmentObject(authVM)
                }
            }
            // Privacy Sheet
            .sheet(isPresented: $showPrivacy) {
                PrivacyView()
            }
            // Logout Confirm
            .confirmationDialog("Log Out", isPresented: $showLogoutConfirm, titleVisibility: .visible) {
                Button("Log Out", role: .destructive) {
                    authVM.logout()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to log out?")
            }
            // Delete Confirm
            .confirmationDialog("Delete Account", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Delete Account", role: .destructive) {
                    authVM.deleteAccount()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete your account and all your data. This cannot be undone.")
            }
            // Loading overlay
            .overlay {
                if authVM.isLoading {
                    ZStack {
                        Color.black.opacity(0.3).ignoresSafeArea()
                        ProgressView("Please wait...")
                            .padding(24)
                            .background(Color(.systemBackground))
                            .cornerRadius(16)
                    }
                }
            }
        }
    }
}

// MARK: - Privacy View
struct PrivacyView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("What We Never Show")) {
                    Label("Phone number", systemImage: "phone.slash.fill")
                    Label("Email address", systemImage: "envelope.slash.fill")
                    Label("Exact home address", systemImage: "house.slash.fill")
                }

                Section(header: Text("Safety Features")) {
                    Label("Block users from profile", systemImage: "person.slash.fill")
                    Label("Report inappropriate profiles", systemImage: "flag.fill")
                    Label("All reports reviewed by admins", systemImage: "shield.lefthalf.filled")
                }

                Section(header: Text("Your Data")) {
                    Label("Direct chat is disabled in guardian-only mode", systemImage: "lock.fill")
                    Label("Your profile is only shown to opposite gender", systemImage: "eye.fill")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Privacy & Safety")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.nikahGreen)
                }
            }
        }
    }
}
