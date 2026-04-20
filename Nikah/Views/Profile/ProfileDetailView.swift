// Views/Profile/ProfileDetailView.swift

import SwiftUI

struct ProfileDetailView: View {
    let user: UserModel
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showReportSheet = false
    @State private var showBlockConfirm = false
    @State private var reportReason = ""
    @State private var selectedPhotoIndex = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // MARK: Photo Gallery
                photoGallery

                // MARK: Header Info
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(user.displayName)
                            .font(.system(size: 26, weight: .bold))
                        Text(", \(user.age)")
                            .font(.system(size: 22, weight: .light))
                        Spacer()
                        if user.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.blue)
                        }
                    }

                    Label("\(user.district), \(user.division)", systemImage: "mappin.circle.fill")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Label(user.profession, systemImage: "briefcase.fill")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                // MARK: Detail Sections
                VStack(spacing: 12) {
                    if !user.bio.isEmpty {
                        DetailCard(title: "About Me", icon: "person.fill") {
                            Text(user.bio)
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                    }

                    DetailCard(title: "Personal Details", icon: "list.bullet.rectangle") {
                        InfoRow(label: "Marital Status", value: user.maritalStatus.capitalized)
                        InfoRow(label: "Height", value: user.height.heightFormatted)
                        InfoRow(label: "Weight", value: "\(Int(user.weight)) kg")
                        InfoRow(label: "Date of Birth", value: user.dateOfBirth.formattedShort)
                    }

                    DetailCard(title: "Location", icon: "location.fill") {
                        InfoRow(label: "Country", value: user.country)
                        InfoRow(label: "Division", value: user.division)
                        InfoRow(label: "District", value: user.district)
                        InfoRow(label: "Upazila", value: user.upazila)
                    }

                    DetailCard(title: "Education & Profession", icon: "graduationcap.fill") {
                        InfoRow(label: "Profession", value: user.profession)
                        InfoRow(label: "Education", value: user.education)
                        InfoRow(label: "Institution", value: user.institution)
                    }

                    DetailCard(title: "Religious", icon: "moon.stars.fill") {
                        InfoRow(label: "Religion", value: user.religion)
                        InfoRow(label: "Prayer/Day", value: user.prayerFrequency)
                        if user.gender == "male" {
                            InfoRow(label: "Beard", value: user.beard ? "Yes" : "No")
                        }
                        if user.gender == "female" {
                            InfoRow(label: "Hijab", value: user.hijab ? "Yes" : "No")
                        }
                    }

                    DetailCard(title: "Guardian/Wali", icon: "person.2.fill") {
                        InfoRow(label: "Name", value: user.guardianName)
                        InfoRow(label: "Contact", value: user.guardianContact)
                    }

                    // MARK: Safety Actions
                    VStack(spacing: 8) {
                        Button {
                            showReportSheet = true
                        } label: {
                            Label("Report User", systemImage: "flag.fill")
                                .foregroundColor(.orange)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange.opacity(0.08))
                                .cornerRadius(12)
                        }

                        Button {
                            showBlockConfirm = true
                        } label: {
                            Label("Block User", systemImage: "person.slash.fill")
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.08))
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
        // MARK: Report Sheet
        .sheet(isPresented: $showReportSheet) {
            ReportSheet(reportReason: $reportReason) {
                guard let myId = authVM.currentUser?.id else { return }
                UserService.shared.reportUser(
                    reportedUserId: user.id ?? "",
                    reportedBy: myId,
                    reason: reportReason
                ) { _ in
                    showReportSheet = false
                    reportReason = ""
                }
            }
        }
        // MARK: Block Confirm
        .confirmationDialog("Block \(user.displayName)?", isPresented: $showBlockConfirm, titleVisibility: .visible) {
            Button("Block", role: .destructive) {
                guard let myId = authVM.currentUser?.id else { return }
                UserService.shared.blockUser(currentUserId: myId, blockedUserId: user.id ?? "") { _ in
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You won't see \(user.displayName)'s profile anymore.")
        }
    }

    // MARK: - Photo Gallery
    private var photoGallery: some View {
        Group {
            if user.photos.isEmpty {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(height: 380)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.secondary)
                    )
            } else {
                TabView(selection: $selectedPhotoIndex) {
                    ForEach(Array(user.photos.enumerated()), id: \.offset) { index, url in
                        AsyncImage(url: URL(string: url)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            case .failure:
                                Color(.systemGray5)
                                    .overlay(Image(systemName: "photo").foregroundColor(.secondary))
                            default:
                                Color(.systemGray6)
                                    .overlay(ProgressView())
                            }
                        }
                        .frame(height: 380)
                        .clipped()
                        .tag(index)
                    }
                }
                .frame(height: 380)
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
            }
        }
    }
}

// MARK: - Detail Card
struct DetailCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.nikahGreen)
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value.isEmpty ? "—" : value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Report Sheet
struct ReportSheet: View {
    @Binding var reportReason: String
    @Environment(\.dismiss) var dismiss
    let onSubmit: () -> Void

    let reasons = ["Fake profile", "Inappropriate content", "Harassment", "Spam", "Other"]
    @State private var selectedReason = ""
    @State private var customReason = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Reason")) {
                    ForEach(reasons, id: \.self) { reason in
                        Button {
                            selectedReason = reason
                        } label: {
                            HStack {
                                Text(reason).foregroundColor(.primary)
                                Spacer()
                                if selectedReason == reason {
                                    Image(systemName: "checkmark").foregroundColor(.nikahGreen)
                                }
                            }
                        }
                    }
                }
                if selectedReason == "Other" {
                    Section(header: Text("Details")) {
                        TextField("Describe the issue...", text: $customReason)
                    }
                }
            }
            .navigationTitle("Report User")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        reportReason = selectedReason == "Other" ? customReason : selectedReason
                        onSubmit()
                    }
                    .disabled(selectedReason.isEmpty)
                    .foregroundColor(.nikahGreen)
                }
            }
        }
    }
}
