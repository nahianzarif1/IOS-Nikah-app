import SwiftUI

struct EmailVerificationView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var localStatusMessage: String?
    @State private var animateIcon = false

    private var loading: Bool {
        authVM.isSendingVerificationEmail
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Image(systemName: "mail.badge")
                    .font(.system(size: 64))
                    .foregroundColor(.nikahGreen)
                    .scaleEffect(animateIcon ? 1.02 : 0.98)
                    .opacity(animateIcon ? 1.0 : 0.85)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: animateIcon)

                Text("Verify your email")
                    .font(.system(size: 26, weight: .bold, design: .rounded))

                Text("We sent a verification link to your inbox. Please verify your email to continue.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

        if let msg = localStatusMessage {
                    Text(msg)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
            .transition(.opacity)
                }

        if let err = authVM.emailVerificationErrorMessage {
                    Text(err)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
            .transition(.opacity)
                }

                Spacer(minLength: 0)

                VStack(spacing: 12) {
                    Button {
                        authVM.refreshEmailVerificationStatus()
                        localStatusMessage = "Checking verification status..."
                    } label: {
                        if loading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("I have verified")
                        }
                    }
                    .nikahButton()
                    .disabled(loading)

                    Button {
                        authVM.sendVerificationEmail()
                        localStatusMessage = "Resent verification email."
                    } label: {
                        Text("Resend email")
                    }
                    .nikahButton(color: Color(.systemGray5), textColor: .nikahGreen)
                    .disabled(loading)

                    Button {
                        authVM.logout()
                    } label: {
                        Text("Back to Login")
                    }
                    .nikahButton(color: Color(.systemGray6), textColor: .nikahGreen)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.nikahBackground.ignoresSafeArea())
            .navigationTitle("Email Verification")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                authVM.refreshEmailVerificationStatus()
                animateIcon = true
            }
            .onChange(of: authVM.isEmailVerified) { _, newValue in
                if newValue == true {
                    localStatusMessage = "Email verified! Loading..."
                }
            }
            .task {
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 20_000_000_000)
                    await MainActor.run {
                        authVM.refreshEmailVerificationStatus()
                        localStatusMessage = "Checking verification status..."
                    }
                }
            }
        }
    }
}

#Preview {
    EmailVerificationView()
        .environmentObject(AuthViewModel())
}

