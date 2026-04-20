// ViewModels/AuthViewModel.swift

import Foundation
import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var currentUser: UserModel?
    @Published var isLoggedIn: Bool = false
    @Published var isEmailVerified: Bool? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isSendingVerificationEmail: Bool = false
    @Published var emailVerificationErrorMessage: String?
    @Published var shouldBypassEmailVerification: Bool = false

    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private var verificationTimeoutTask: Task<Void, Never>?
    private let legacyBypassCutoff: Date = Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 31)) ?? .distantPast

    init() {
        authStateHandle = FirebaseManager.shared.auth.addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                if let user = user {
                    self?.isLoggedIn = true
                    self?.isEmailVerified = user.isEmailVerified
                    self?.fetchCurrentUser(uid: user.uid)
                } else {
                    self?.isLoggedIn = false
                    self?.currentUser = nil
                    self?.isEmailVerified = nil
                    self?.shouldBypassEmailVerification = false
                }
            }
        }
    }

    deinit {
        if let handle = authStateHandle {
            FirebaseManager.shared.auth.removeStateDidChangeListener(handle)
        }
    }

    // MARK: - Login
    func login(email: String, password: String) {
        isLoading = true
        errorMessage = nil
        AuthService.shared.login(email: email, password: password) { [weak self] result in
            Task { @MainActor in
                guard let self = self else { return }
                self.isLoading = false
                switch result {
                case .success(let uid):
                    self.isEmailVerified = FirebaseManager.shared.auth.currentUser?.isEmailVerified
                    self.fetchCurrentUser(uid: uid)
                case .failure(let error):
                    self.errorMessage = Self.friendlyError(error)
                    print("❌ Login error: \(error)")
                }
            }
        }
    }

    // MARK: - Register
    func register(email: String, password: String, gender: String) {
        isLoading = true
        errorMessage = nil
        AuthService.shared.register(email: email, password: password, gender: gender) { [weak self] result in
            Task { @MainActor in
                guard let self = self else { return }
                self.isLoading = false
                switch result {
                case .success(let user):
                    self.currentUser = user
                    self.isLoggedIn = true
                    self.isEmailVerified = FirebaseManager.shared.auth.currentUser?.isEmailVerified
                case .failure(let error):
                    // Map Firebase "internal error" to a human-readable message
                    let msg = Self.friendlyError(error)
                    self.errorMessage = msg
                    print("❌ Register error: \(error)")
                }
            }
        }
    }

    // MARK: - Email Verification
    func sendVerificationEmail() {
        isSendingVerificationEmail = true
        emailVerificationErrorMessage = nil
        startVerificationTimeout()
        AuthService.shared.sendEmailVerification { [weak self] error in
            Task { @MainActor in
                guard let self else { return }
                self.isSendingVerificationEmail = false
                self.verificationTimeoutTask?.cancel()
                if let error = error {
                    self.emailVerificationErrorMessage = error.localizedDescription
                }
            }
        }
    }

    func refreshEmailVerificationStatus() {
        guard let user = FirebaseManager.shared.auth.currentUser else {
            isEmailVerified = false
            return
        }
        isSendingVerificationEmail = true
        emailVerificationErrorMessage = nil
        startVerificationTimeout()
        user.reload { [weak self] error in
            Task { @MainActor in
                guard let self else { return }
                self.isSendingVerificationEmail = false
                self.verificationTimeoutTask?.cancel()
                if let error = error {
                    self.emailVerificationErrorMessage = error.localizedDescription
                    return
                }
                self.isEmailVerified = FirebaseManager.shared.auth.currentUser?.isEmailVerified
                if self.isEmailVerified == true {
                    self.emailVerificationErrorMessage = nil
                    self.markEmailVerifiedIfNeeded()
                } else {
                    self.emailVerificationErrorMessage = "Not verified yet. Please open the email link and try again."
                }
            }
        }
    }

    private func startVerificationTimeout() {
        verificationTimeoutTask?.cancel()
        verificationTimeoutTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 20_000_000_000)
            await MainActor.run {
                guard let self else { return }
                if self.isSendingVerificationEmail {
                    self.isSendingVerificationEmail = false
                    self.emailVerificationErrorMessage = "Verification timed out. Please try again."
                }
            }
        }
    }

    /// Converts Firebase error codes into user-friendly messages
    private static func friendlyError(_ error: Error) -> String {
        let nsError = error as NSError
        // Firebase Auth error codes
        switch nsError.code {
        case 17005: return "This email is already registered. Try logging in."
        case 17007: return "Email address is invalid."
        case 17026: return "Password must be at least 6 characters."
        case 17999, 17010: return "Registration is currently unavailable. Please go to Firebase Console → Authentication → Sign-in method → Enable Email/Password."
        default:
            // Strip verbose Firebase internal description
            let raw = error.localizedDescription
            if raw.lowercased().contains("internal error") {
                return "Sign-up failed. Make sure Email/Password sign-in is enabled in Firebase Console → Authentication → Sign-in method."
            }
            return raw
        }
    }

    // MARK: - Logout
    func logout() {
        do {
            try AuthService.shared.logout()
            currentUser = nil
            isLoggedIn = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Delete Account
    func deleteAccount() {
        isLoading = true
        AuthService.shared.deleteAccount { [weak self] result in
            Task { @MainActor in
                self?.isLoading = false
                switch result {
                case .success:
                    self?.currentUser = nil
                    self?.isLoggedIn = false
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Fetch Current User
    func fetchCurrentUser(uid: String) {
        UserService.shared.fetchUser(uid: uid) { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let user):
                    UserService.shared.migrateLegacyUserIfNeeded(user) { migratedResult in
                        Task { @MainActor in
                            switch migratedResult {
                            case .success(let migratedUser):
                                self?.currentUser = migratedUser
                                self?.updateBypassStatus(for: migratedUser)
                                self?.markEmailVerifiedIfNeeded()
                            case .failure(let migrationError):
                                self?.currentUser = user
                                self?.updateBypassStatus(for: user)
                                self?.markEmailVerifiedIfNeeded()
                                self?.errorMessage = migrationError.localizedDescription
                            }
                        }
                    }
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func updateBypassStatus(for user: UserModel) {
        // Legacy users created before cutoff or users manually marked verified can bypass email verification.
        let legacyUser = user.createdAt < legacyBypassCutoff
        shouldBypassEmailVerification = legacyUser || user.isVerified
    }

    private func markEmailVerifiedIfNeeded() {
        guard isEmailVerified == true, var user = currentUser else { return }
        guard user.isVerified == false else { return }
        user.isVerified = true
        currentUser = user
        UserService.shared.updateUser(user) { _ in }
        updateBypassStatus(for: user)
    }

    // MARK: - Refresh
    func refresh() {
        guard let uid = AuthService.shared.currentUserId else { return }
        fetchCurrentUser(uid: uid)
    }
}
