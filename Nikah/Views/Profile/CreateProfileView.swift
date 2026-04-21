// Views/Profile/CreateProfileView.swift

import SwiftUI
import PhotosUI

struct CreateProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var profileVM: ProfileViewModel
    @State private var currentStep: Int = 0
    @State private var selectedPhotoItems: [PhotosPickerItem] = []

    let steps = ["Personal", "Location", "Profession", "Biodata", "Religious", "Photos"]

    init(user: UserModel) {
        _profileVM = StateObject(wrappedValue: ProfileViewModel(user: user))
    }



    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: Step Indicator
                StepIndicatorView(steps: steps, currentStep: currentStep)
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                ScrollView {
                    VStack(spacing: 20) {
                        switch currentStep {
                        case 0: personalSection
                        case 1: locationSection
                        case 2: professionSection
                        case 3: biodataSection
                        case 4: religiousSection
                        case 5: photosSection
                        default: EmptyView()
                        }
                    }
                    .padding()
                }

                // MARK: Navigation Buttons
                HStack(spacing: 12) {
                    if currentStep > 0 {
                        Button("Back") { withAnimation { currentStep -= 1 } }
                            .nikahButton(color: Color(.systemGray4))
                            .foregroundColor(.primary)
                    }

                    if currentStep < steps.count - 1 {
                        Button("Next") {
                            withAnimation { currentStep += 1 }
                        }
                        .nikahButton()
                    } else {
                        Button {
                            if profileVM.isUploadingPhoto {
                                profileVM.errorMessage = "Please wait until photo upload finishes."
                                return
                            }

                            profileVM.saveProfile(markCompleted: true) {
                                // Immediately switch root flow to Home after successful onboarding save.
                                var updatedUser = profileVM.user
                                updatedUser.profileCompleted = true
                                profileVM.user = updatedUser
                                authVM.currentUser = updatedUser

                                // Do not block navigation with a success alert on onboarding completion.
                                profileVM.successMessage = nil

                                // Refresh backend state in background without blocking navigation.
                                Task { @MainActor in
                                    authVM.refresh()
                                }
                            }
                        } label: {
                            if profileVM.isSaving {
                                ProgressView().tint(.white)
                            } else {
                                Text("Save Profile")
                            }
                        }
                        .nikahButton()
                        .disabled(profileVM.isSaving || profileVM.isUploadingPhoto)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("Create Profile")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Error", isPresented: .constant(profileVM.errorMessage != nil), actions: {
                Button("OK") { profileVM.errorMessage = nil }
            }, message: {
                Text(profileVM.errorMessage ?? "")
            })
        }
        .onTapGesture { hideKeyboard() }
    }

    // MARK: - Step 1: Personal
    private var personalSection: some View {
        VStack(spacing: 16) {
            SectionCard(title: "Personal Details") {
                FormTextField(label: "Display Name", placeholder: "Your name", text: $profileVM.user.displayName)
                FormTextField(label: "Biodata ID", placeholder: "Auto-generated if left blank", text: Binding(
                    get: { profileVM.user.biodataId },
                    set: { profileVM.user.biodataId = $0 }
                ))
                FormTextField(label: "Bio", placeholder: "Tell about yourself...", text: $profileVM.user.bio, isMultiline: true)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Date of Birth")
                        .font(.caption).fontWeight(.semibold).foregroundColor(.secondary)
                    DatePicker("", selection: $profileVM.user.dateOfBirth, in: ...Date(), displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .onChange(of: profileVM.user.dateOfBirth) { profileVM.updateAgeFromDOB() }
                    Text("Age: \(profileVM.user.age)")
                        .font(.caption).foregroundColor(.secondary)
                }

                FormPickerField(label: "Marital Status", selection: $profileVM.user.maritalStatus, options: ["unmarried", "divorced", "widowed"])
                FormTextField(label: "Height (ft)", placeholder: "e.g. 5.8", text: Binding(
                    get: { profileVM.user.height == 0 ? "" : String(profileVM.user.height) },
                    set: { profileVM.user.height = Double($0) ?? 0 }
                ))
                .keyboardType(.decimalPad)
                FormTextField(label: "Weight (kg)", placeholder: "e.g. 65", text: Binding(
                    get: { profileVM.user.weight == 0 ? "" : String(Int(profileVM.user.weight)) },
                    set: { profileVM.user.weight = Double($0) ?? 0 }
                ))
                .keyboardType(.numberPad)
            }
        }
    }

    // MARK: - Step 2: Location
    private var locationSection: some View {
        SectionCard(title: "Location") {
            FormPickerField(label: "Country", selection: $profileVM.user.country, options: ["Bangladesh", "India", "Pakistan", "UK", "USA", "Canada", "Australia", "Other"])
            FormTextField(label: "Division", placeholder: "e.g. Dhaka", text: $profileVM.user.division)
            FormTextField(label: "District", placeholder: "e.g. Bogura", text: $profileVM.user.district)
            FormTextField(label: "Upazila", placeholder: "e.g. Shahjahanpur", text: $profileVM.user.upazila)
        }
    }

    // MARK: - Step 3: Profession
    private var professionSection: some View {
        SectionCard(title: "Education & Profession") {
            FormTextField(label: "Profession", placeholder: "e.g. Student, Engineer", text: $profileVM.user.profession)
            FormPickerField(label: "Income Class", selection: $profileVM.user.incomeClass, options: ["lower", "middle", "upper_middle", "upper"])
            FormPickerField(label: "Financial Status", selection: $profileVM.user.financialStatus, options: ["stable", "comfortable", "affluent", "dependent"])
            FormTextField(label: "Education", placeholder: "e.g. BSc in CSE", text: $profileVM.user.education)
            FormPickerField(label: "Education Type", selection: $profileVM.user.educationType, options: ["general", "madrasa", "both"])
            FormTextField(label: "Institution", placeholder: "e.g. KUET", text: $profileVM.user.institution)
        }
    }

    // MARK: - Step 4: Biodata Details
    private var biodataSection: some View {
        SectionCard(title: "Biodata Details") {
            FormPickerField(label: "Complexion", selection: $profileVM.user.complexion, options: ["fair", "medium", "wheatish", "dark", "other"])
            Toggle("Orphan", isOn: $profileVM.user.isOrphan)
                .tint(.nikahGreen)
            Toggle("Revert Muslim", isOn: $profileVM.user.isRevertMuslim)
                .tint(.nikahGreen)
            Toggle("Disabled", isOn: $profileVM.user.isDisabled)
                .tint(.nikahGreen)
            Toggle("Open to second marriage", isOn: $profileVM.user.openToSecondMarriage)
                .tint(.nikahGreen)
        }
    }

    // MARK: - Step 4: Religious
    private var religiousSection: some View {
        SectionCard(title: "Religious Information") {
            FormPickerField(label: "Religion", selection: $profileVM.user.religion, options: ["Islam", "Other"])
            FormPickerField(label: "Madhhab", selection: $profileVM.user.madhhab, options: ["hanafi", "shafii", "maliki", "hanbali", "salafi", "other"])
            FormTextField(label: "Prayer Frequency (per day)", placeholder: "e.g. 5", text: $profileVM.user.prayerFrequency)
                .keyboardType(.numberPad)
            VStack(alignment: .leading, spacing: 8) {
                Text("Deen Level: \(profileVM.user.deenLevel)/5")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                Slider(value: Binding(
                    get: { Double(profileVM.user.deenLevel) },
                    set: { profileVM.user.deenLevel = Int($0) }
                ), in: 1...5, step: 1)
                .tint(.nikahGreen)
            }
            FormTextField(label: "Guardian/Wali Name", placeholder: "e.g. Father/Brother/Guardian", text: $profileVM.user.guardianName)
            FormTextField(label: "Guardian Contact", placeholder: "Phone number", text: $profileVM.user.guardianContact)
                .keyboardType(.phonePad)

            if profileVM.user.gender == "male" {
                Toggle(isOn: $profileVM.user.beard) {
                    Label("Has beard", systemImage: "person.fill")
                        .font(.subheadline)
                }
                .tint(.nikahGreen)
            }
            if profileVM.user.gender == "female" {
                Toggle(isOn: $profileVM.user.hijab) {
                    Label("Wears hijab", systemImage: "person.fill")
                        .font(.subheadline)
                }
                .tint(.nikahGreen)

                Toggle(isOn: $profileVM.user.niqab) {
                    Label("Wears niqab", systemImage: "person.fill")
                        .font(.subheadline)
                }
                .tint(.nikahGreen)
            }
        }
    }

    // MARK: - Step 5: Photos
    private var photosSection: some View {
        VStack(spacing: 16) {
            SectionCard(title: "Profile Photos") {
                Text("Add up to \(AppConstants.maxPhotos) photos. First photo is your main profile photo.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Photo Grid
                if !profileVM.user.photos.isEmpty {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(Array(profileVM.user.photos.enumerated()), id: \.offset) { index, url in
                            ZStack(alignment: .topTrailing) {
                                AsyncImage(url: URL(string: url)) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image.resizable().scaledToFill()
                                    default:
                                        Color(.systemGray5)
                                    }
                                }
                                .frame(width: 100, height: 100)
                                .clipped()
                                .cornerRadius(10)

                                Button {
                                    profileVM.removePhoto(at: index)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                        .background(Color.white.clipShape(Circle()))
                                }
                                .offset(x: 6, y: -6)
                            }
                        }
                    }
                }

                if profileVM.isUploadingPhoto {
                    HStack {
                        ProgressView()
                        Text("Uploading photo...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if profileVM.user.photos.count < AppConstants.maxPhotos {
                    PhotosPicker(
                        selection: $selectedPhotoItems,
                        maxSelectionCount: AppConstants.maxPhotos - profileVM.user.photos.count,
                        matching: .images
                    ) {
                        Label("Add Photos", systemImage: "photo.badge.plus")
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.nikahGreen.opacity(0.1))
                            .foregroundColor(.nikahGreen)
                            .cornerRadius(10)
                    }
                    .onChange(of: selectedPhotoItems) { _, items in
                        uploadSelectedPhotos(items)
                    }
                }
            }
        }
    }

    private func uploadSelectedPhotos(_ items: [PhotosPickerItem]) {
        for item in items {
            item.loadTransferable(type: Data.self) { result in
                DispatchQueue.main.async {
                    if case .success(let data) = result, let data = data,
                       let image = UIImage(data: data) {
                        profileVM.uploadPhoto(image)
                    }
                }
            }
        }
        selectedPhotoItems = []
    }
}

// MARK: - Reusable Form Components

struct SectionCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.headline)
                .foregroundColor(.nikahGreen)
            content
        }
        .padding(16)
        .cardStyle()
    }
}

struct FormTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var isMultiline: Bool = false
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            if isMultiline {
                TextEditor(text: $text)
                    .frame(height: 80)
                    .padding(8)
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.systemGray4), lineWidth: 1))
            } else {
                TextField(placeholder, text: $text)
                    .padding(10)
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.systemGray4), lineWidth: 1))
            }
        }
    }
}

struct FormPickerField: View {
    let label: String
    @Binding var selection: String
    let options: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            Picker(label, selection: $selection) {
                Text("Select").tag("")
                ForEach(options, id: \.self) { option in
                    Text(option.capitalized).tag(option)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.systemGray4), lineWidth: 1))
        }
    }
}

struct StepIndicatorView: View {
    let steps: [String]
    let currentStep: Int

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(index <= currentStep ? Color.nikahGreen : Color(.systemGray4))
                            .frame(width: 28, height: 28)
                        if index < currentStep {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Text("\(index + 1)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    Text(step)
                        .font(.system(size: 9))
                        .foregroundColor(index <= currentStep ? .nikahGreen : .secondary)
                        .lineLimit(1)
                }
                if index < steps.count - 1 {
                    Rectangle()
                        .fill(index < currentStep ? Color.nikahGreen : Color(.systemGray4))
                        .frame(height: 2)
                        .padding(.bottom, 16)
                }
            }
        }
    }
}
