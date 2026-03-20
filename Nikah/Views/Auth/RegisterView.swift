// Views/Auth/RegisterView.swift

import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var selectedGender: String = ""
    @FocusState private var focusedField: Field?

    enum Field { case email, password, confirmPassword }

    private var isFormValid: Bool {
        !email.isEmpty && email.isValidEmail &&
        password.count >= 6 &&
        password == confirmPassword &&
        !selectedGender.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "person.badge.plus.fill")
                        .font(.system(size: 52))
                        .foregroundColor(.nikahGreen)
                        .padding(.top, 24)
                    Text("Create Account")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    Text("Join Nikah to find your life partner")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 32)

                VStack(spacing: 20) {
                    // Gender Selection (LOCKED after registration)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("I am a")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            Text("⚠️ Cannot change later")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                        HStack(spacing: 12) {
                            GenderButton(
                                title: "Male",
                                icon: "person.fill",
                                isSelected: selectedGender == "male"
                            ) { selectedGender = "male" }

                            GenderButton(
                                title: "Female",
                                icon: "person.fill",
                                isSelected: selectedGender == "female"
                            ) { selectedGender = "female" }
                        }
                    }

                    // Email
                    NikahTextField(
                        icon: "envelope.fill",
                        placeholder: "Email address",
                        text: $email,
                        focusedField: $focusedField,
                        fieldCase: .email
                    )
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                    // Password
                    NikahSecureField(
                        icon: "lock.fill",
                        placeholder: "Password (min 6 characters)",
                        text: $password,
                        focusedField: $focusedField,
                        fieldCase: .password
                    )

                    // Confirm Password
                    NikahSecureField(
                        icon: "lock.rotation",
                        placeholder: "Confirm password",
                        text: $confirmPassword,
                        focusedField: $focusedField,
                        fieldCase: .confirmPassword
                    )

                    // Password mismatch warning
                    if !confirmPassword.isEmpty && password != confirmPassword {
                        Label("Passwords do not match", systemImage: "exclamationmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Error
                    if let error = authVM.errorMessage {
                        Label(error, systemImage: "exclamationmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Register Button
                    Button(action: register) {
                        if authVM.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Create Account")
                        }
                    }
                    .nikahButton()
                    .disabled(!isFormValid || authVM.isLoading)
                    .opacity(!isFormValid ? 0.6 : 1.0)

                    // Back to login
                    Button("Already have an account? Sign In") {
                        dismiss()
                    }
                    .font(.footnote)
                    .foregroundColor(.nikahGreen)
                    .padding(.top, 4)
                }
                .padding(24)
                .cardStyle()
                .padding(.horizontal, 20)

                Spacer(minLength: 40)
            }
        }
        .background(Color.nikahBackground.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onTapGesture { hideKeyboard() }
    }

    private func register() {
        authVM.register(email: email, password: password, gender: selectedGender)
    }
}

// MARK: - Helper Subviews

struct GenderButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .foregroundColor(isSelected ? .white : .nikahGreen)
            .background(isSelected ? Color.nikahGreen : Color.nikahGreen.opacity(0.08))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.nikahGreen, lineWidth: isSelected ? 0 : 1))
        }
    }
}

struct NikahTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var focusedField: FocusState<RegisterView.Field?>.Binding
    let fieldCase: RegisterView.Field

    var body: some View {
        HStack {
            Image(systemName: icon).foregroundColor(.secondary).frame(width: 20)
            TextField(placeholder, text: $text)
                .focused(focusedField, equals: fieldCase)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(focusedField.wrappedValue == fieldCase ? Color.nikahGreen : Color(.systemGray4), lineWidth: 1))
    }
}

struct NikahSecureField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var focusedField: FocusState<RegisterView.Field?>.Binding
    let fieldCase: RegisterView.Field

    var body: some View {
        HStack {
            Image(systemName: icon).foregroundColor(.secondary).frame(width: 20)
            SecureField(placeholder, text: $text)
                .focused(focusedField, equals: fieldCase)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(focusedField.wrappedValue == fieldCase ? Color.nikahGreen : Color(.systemGray4), lineWidth: 1))
    }
}

#Preview {
    NavigationStack {
        RegisterView().environmentObject(AuthViewModel())
    }
}
