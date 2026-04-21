// Views/Profile/EditProfileView.swift

import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var profileVM: ProfileViewModel
    @Environment(\.dismiss) var dismiss
    @State private var selectedPhotoItems: [PhotosPickerItem] = []

    init(user: UserModel) {
        _profileVM = StateObject(wrappedValue: ProfileViewModel(user: user))
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Photos Section
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(Array(profileVM.user.photos.enumerated()), id: \.offset) { index, url in
                                ZStack(alignment: .topTrailing) {
                                    AsyncImage(url: URL(string: url)) { phase in
                                        switch phase {
                                        case .success(let img): img.resizable().scaledToFill()
                                        default: Color(.systemGray5)
                                        }
                                    }
                                    .frame(width: 90, height: 90)
                                    .clipped()
                                    .cornerRadius(10)

                                    Button {
                                        profileVM.removePhoto(at: index)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                            .background(Color.white.clipShape(Circle()))
                                    }
                                    .offset(x: 4, y: -4)
                                }
                            }

                            if profileVM.user.photos.count < AppConstants.maxPhotos {
                                PhotosPicker(selection: $selectedPhotoItems, maxSelectionCount: 1, matching: .images) {
                                    VStack {
                                        Image(systemName: "plus")
                                            .font(.title2)
                                            .foregroundColor(.nikahGreen)
                                        Text("Add")
                                            .font(.caption)
                                            .foregroundColor(.nikahGreen)
                                    }
                                    .frame(width: 90, height: 90)
                                    .background(Color.nikahGreen.opacity(0.08))
                                    .cornerRadius(10)
                                }
                                .onChange(of: selectedPhotoItems) { _, items in
                                    if let item = items.first {
                                        item.loadTransferable(type: Data.self) { result in
                                            DispatchQueue.main.async {
                                                if case .success(let data) = result,
                                                   let data = data,
                                                   let image = UIImage(data: data) {
                                                    profileVM.uploadPhoto(image)
                                                }
                                                selectedPhotoItems = []
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }

                    if profileVM.isUploadingPhoto {
                        HStack {
                            ProgressView()
                            Text("Uploading...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: { Text("Photos") }

                // MARK: Personal
                Section(header: Text("Personal")) {
                    HStack {
                        Text("Name")
                        Spacer()
                        TextField("Display name", text: $profileVM.user.displayName)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Biodata ID")
                        Spacer()
                        TextField("Auto-generated", text: $profileVM.user.biodataId)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Bio")
                        Spacer()
                        TextField("Bio", text: $profileVM.user.bio)
                            .multilineTextAlignment(.trailing)
                    }
                    Picker("Marital Status", selection: $profileVM.user.maritalStatus) {
                        ForEach(["unmarried", "divorced", "widowed"], id: \.self) { s in
                            Text(s.capitalized).tag(s)
                        }
                    }
                    HStack {
                        Text("Height (ft)")
                        Spacer()
                        TextField("0.0", value: $profileVM.user.height, format: .number)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                    }
                    HStack {
                        Text("Weight (kg)")
                        Spacer()
                        TextField("0", value: $profileVM.user.weight, format: .number)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numberPad)
                    }
                }

                // MARK: Location
                Section(header: Text("Location")) {
                    HStack {
                        Text("Division")
                        Spacer()
                        TextField("Division", text: $profileVM.user.division)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("District")
                        Spacer()
                        TextField("District", text: $profileVM.user.district)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Upazila")
                        Spacer()
                        TextField("Upazila", text: $profileVM.user.upazila)
                            .multilineTextAlignment(.trailing)
                    }
                }

                // MARK: Profession
                Section(header: Text("Education & Profession")) {
                    HStack {
                        Text("Profession")
                        Spacer()
                        TextField("Profession", text: $profileVM.user.profession)
                            .multilineTextAlignment(.trailing)
                    }
                    Picker("Income Class", selection: $profileVM.user.incomeClass) {
                        Text("Not set").tag("")
                        Text("Lower").tag("lower")
                        Text("Middle").tag("middle")
                        Text("Upper Middle").tag("upper_middle")
                        Text("Upper").tag("upper")
                    }
                    Picker("Financial Status", selection: $profileVM.user.financialStatus) {
                        Text("Not set").tag("")
                        Text("Stable").tag("stable")
                        Text("Comfortable").tag("comfortable")
                        Text("Affluent").tag("affluent")
                        Text("Dependent").tag("dependent")
                    }
                    HStack {
                        Text("Education")
                        Spacer()
                        TextField("Education", text: $profileVM.user.education)
                            .multilineTextAlignment(.trailing)
                    }
                    Picker("Education Type", selection: $profileVM.user.educationType) {
                        Text("Not set").tag("")
                        Text("General").tag("general")
                        Text("Madrasa").tag("madrasa")
                        Text("Both").tag("both")
                    }
                    HStack {
                        Text("Institution")
                        Spacer()
                        TextField("Institution", text: $profileVM.user.institution)
                            .multilineTextAlignment(.trailing)
                    }
                }

                // MARK: Biodata
                Section(header: Text("Biodata")) {
                    Picker("Complexion", selection: $profileVM.user.complexion) {
                        Text("Not set").tag("")
                        Text("Fair").tag("fair")
                        Text("Medium").tag("medium")
                        Text("Wheatish").tag("wheatish")
                        Text("Dark").tag("dark")
                        Text("Other").tag("other")
                    }
                    Toggle("Orphan", isOn: $profileVM.user.isOrphan).tint(.nikahGreen)
                    Toggle("Revert Muslim", isOn: $profileVM.user.isRevertMuslim).tint(.nikahGreen)
                    Toggle("Disabled", isOn: $profileVM.user.isDisabled).tint(.nikahGreen)
                    Toggle("Open to second marriage", isOn: $profileVM.user.openToSecondMarriage).tint(.nikahGreen)
                }

                // MARK: Religious
                Section(header: Text("Religious")) {
                    Picker("Religion", selection: $profileVM.user.religion) {
                        Text("Islam").tag("Islam")
                        Text("Other").tag("Other")
                    }
                    Picker("Madhhab", selection: $profileVM.user.madhhab) {
                        Text("Not set").tag("")
                        Text("Hanafi").tag("hanafi")
                        Text("Shafi'i").tag("shafii")
                        Text("Maliki").tag("maliki")
                        Text("Hanbali").tag("hanbali")
                        Text("Salafi").tag("salafi")
                        Text("Other").tag("other")
                    }
                    HStack {
                        Text("Prayer Frequency")
                        Spacer()
                        TextField("Times/day", text: $profileVM.user.prayerFrequency)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numberPad)
                    }
                    Stepper("Deen Level: \(profileVM.user.deenLevel)/5", value: $profileVM.user.deenLevel, in: 1...5)
                    HStack {
                        Text("Guardian/Wali")
                        Spacer()
                        TextField("Name", text: $profileVM.user.guardianName)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Guardian Contact")
                        Spacer()
                        TextField("Phone", text: $profileVM.user.guardianContact)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.phonePad)
                    }
                    if profileVM.user.gender == "male" {
                        Toggle("Has Beard", isOn: $profileVM.user.beard).tint(.nikahGreen)
                    }
                    if profileVM.user.gender == "female" {
                        Toggle("Wears Hijab", isOn: $profileVM.user.hijab).tint(.nikahGreen)
                        Toggle("Wears Niqab", isOn: $profileVM.user.niqab).tint(.nikahGreen)
                    }
                }

                // MARK: Error/Success
                if let error = profileVM.errorMessage {
                    Section {
                        Text(error).foregroundColor(.red).font(.caption)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        profileVM.saveProfile {
                            authVM.refresh()
                            dismiss()
                        }
                    } label: {
                        if profileVM.isSaving {
                            ProgressView()
                        } else {
                            Text("Save").bold()
                        }
                    }
                    .disabled(profileVM.isSaving)
                    .foregroundColor(.nikahGreen)
                }
            }
        }
    }
}
