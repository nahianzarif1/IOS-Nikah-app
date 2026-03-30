import SwiftUI

struct EmailVerificationView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var localStatusMessage: String?

    private var loading: Bool {
        authVM.isSendingVerificationEmail
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Image(systemName: "mail.badge")
                    .font(.system(size: 64))
                    .foregroundColor(.nikahGreen)

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
                }

                if let err = authVM.emailVerificationErrorMessage {
                    Text(err)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
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
                    .nikahButton(color: Color(.systemGray5))
                    .disabled(loading)
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
            }
        }
    }
}

#Preview {
    EmailVerificationView()
        .environmentObject(AuthViewModel())
}

