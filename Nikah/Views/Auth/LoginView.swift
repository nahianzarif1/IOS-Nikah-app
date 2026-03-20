// Views/Auth/LoginView.swift

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showRegister = false
    @FocusState private var focusedField: Field?

    enum Field { case email, password }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // MARK: Header
                    VStack(spacing: 8) {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.nikahGreen)
                            .padding(.top, 60)

                        Text("Nikah")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundColor(.nikahGreen)

                        Text("Find your life partner")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 44)

                    // MARK: Form Card
                    VStack(spacing: 16) {
                        // Email Field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.secondary)
                                    .frame(width: 20)
                                TextField("Enter your email", text: $email)
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.emailAddress)
                                    .autocorrectionDisabled()
                                    .focused($focusedField, equals: .email)
                                    .submitLabel(.next)
                                    .onSubmit { focusedField = .password }
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(focusedField == .email ? Color.nikahGreen : Color(.systemGray4), lineWidth: 1))
                        }

                        // Password Field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Password")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.secondary)
                                    .frame(width: 20)
                                SecureField("Enter your password", text: $password)
                                    .focused($focusedField, equals: .password)
                                    .submitLabel(.done)
                                    .onSubmit { login() }
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(focusedField == .password ? Color.nikahGreen : Color(.systemGray4), lineWidth: 1))
                        }

                        // Error Message
                        if let error = authVM.errorMessage {
                            Label(error, systemImage: "exclamationmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 4)
                        }

                        // Login Button
                        Button(action: login) {
                            if authVM.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Sign In")
                            }
                        }
                        .nikahButton()
                        .disabled(authVM.isLoading || email.isEmpty || password.isEmpty)
                        .opacity((email.isEmpty || password.isEmpty) ? 0.6 : 1.0)
                        .padding(.top, 4)

                        // Divider
                        HStack {
                            Rectangle().frame(height: 1).foregroundColor(.secondary.opacity(0.3))
                            Text("or").font(.caption).foregroundColor(.secondary)
                            Rectangle().frame(height: 1).foregroundColor(.secondary.opacity(0.3))
                        }
                        .padding(.vertical, 4)

                        // Register Button
                        Button {
                            showRegister = true
                        } label: {
                            Text("Create New Account")
                        }
                        .nikahButton(color: Color(.systemGray5))
                        .foregroundColor(.primary)
                    }
                    .padding(24)
                    .cardStyle()
                    .padding(.horizontal, 20)

                    Spacer(minLength: 40)
                }
            }
            .background(Color.nikahBackground.ignoresSafeArea())
            .navigationDestination(isPresented: $showRegister) {
                RegisterView()
                    .environmentObject(authVM)
            }
            .onTapGesture { hideKeyboard() }
        }
    }

    private func login() {
        guard email.isValidEmail else {
            authVM.errorMessage = "Please enter a valid email address."
            return
        }
        guard password.count >= 6 else {
            authVM.errorMessage = "Password must be at least 6 characters."
            return
        }
        authVM.login(email: email, password: password)
    }
}

#Preview {
    LoginView().environmentObject(AuthViewModel())
}
