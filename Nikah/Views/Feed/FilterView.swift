// Views/Feed/FilterView.swift

import SwiftUI

struct FilterView: View {
    @Environment(\.dismiss) var dismiss
    @State private var localFilter: FilterModel
    let onApply: (FilterModel) -> Void

    init(filter: FilterModel, onApply: @escaping (FilterModel) -> Void) {
        _localFilter = State(initialValue: filter)
        self.onApply = onApply
    }

    let bangladeshDistricts = [
        "Bagerhat", "Bandarban", "Barguna", "Barishal", "Bhola",
        "Bogura", "Brahmanbaria", "Chandpur", "Chapainawabganj", "Chattogram",
        "Chuadanga", "Cox's Bazar", "Cumilla", "Dhaka", "Dinajpur",
        "Faridpur", "Feni", "Gaibandha", "Gazipur", "Gopalganj",
        "Habiganj", "Jamalpur", "Jashore", "Jhalokathi", "Jhenaidah",
        "Joypurhat", "Khagrachhari", "Khulna", "Kishoreganj", "Kurigram",
        "Kushtia", "Lakshmipur", "Lalmonirhat", "Madaripur", "Magura",
        "Manikganj", "Meherpur", "Moulvibazar", "Munshiganj", "Mymensingh",
        "Naogaon", "Narail", "Narayanganj", "Narsingdi", "Natore",
        "Netrokona", "Nilphamari", "Noakhali", "Pabna", "Panchagarh",
        "Patuakhali", "Pirojpur", "Rajbari", "Rajshahi", "Rangamati",
        "Rangpur", "Satkhira", "Shariatpur", "Sherpur", "Sirajganj",
        "Sunamganj", "Sylhet", "Tangail", "Thakurgaon"
    ]

    var body: some View {
        NavigationStack {
            Form {
                // MARK: District
                Section(header: Text("District")) {
                    Picker("District", selection: $localFilter.district) {
                        Text("Any District").tag("")
                        ForEach(bangladeshDistricts, id: \.self) { d in
                            Text(d).tag(d)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                // MARK: Age Range
                Section(header: Text("Age Range: \(localFilter.minAge) – \(localFilter.maxAge)")) {
                    VStack(alignment: .leading) {
                        Text("Min Age: \(localFilter.minAge)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(
                            value: Binding(
                                get: { Double(localFilter.minAge) },
                                set: { localFilter.minAge = Int($0) }
                            ),
                            in: 18...Double(localFilter.maxAge),
                            step: 1
                        )
                        .tint(.nikahGreen)

                        Text("Max Age: \(localFilter.maxAge)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(
                            value: Binding(
                                get: { Double(localFilter.maxAge) },
                                set: { localFilter.maxAge = Int($0) }
                            ),
                            in: Double(localFilter.minAge)...60,
                            step: 1
                        )
                        .tint(.nikahGreen)
                    }
                }

                // MARK: Height Range
                Section(header: Text(String(format: "Height: %.1f – %.1f ft", localFilter.minHeight, localFilter.maxHeight))) {
                    VStack(alignment: .leading) {
                        Text(String(format: "Min Height: %.1f ft", localFilter.minHeight))
                            .font(.caption).foregroundColor(.secondary)
                        Slider(value: $localFilter.minHeight, in: 4.0...localFilter.maxHeight, step: 0.1)
                            .tint(.nikahGreen)
                        Text(String(format: "Max Height: %.1f ft", localFilter.maxHeight))
                            .font(.caption).foregroundColor(.secondary)
                        Slider(value: $localFilter.maxHeight, in: localFilter.minHeight...7.0, step: 0.1)
                            .tint(.nikahGreen)
                    }
                }

                // MARK: Marital Status
                Section(header: Text("Marital Status")) {
                    Picker("Marital Status", selection: $localFilter.maritalStatus) {
                        Text("Any").tag("")
                        Text("Unmarried").tag("unmarried")
                        Text("Divorced").tag("divorced")
                        Text("Widowed").tag("widowed")
                    }
                    .pickerStyle(.segmented)
                }

                // MARK: Religious Preference
                Section(header: Text("Religious Preference")) {
                    Toggle("Verified profiles only", isOn: $localFilter.onlyVerified)
                        .tint(.nikahGreen)

                    Picker("Madhhab", selection: $localFilter.madhhab) {
                        Text("Any Madhhab").tag("")
                        Text("Hanafi").tag("hanafi")
                        Text("Shafi'i").tag("shafii")
                        Text("Maliki").tag("maliki")
                        Text("Hanbali").tag("hanbali")
                        Text("Salafi").tag("salafi")
                        Text("Other").tag("other")
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Minimum Prayer/Day: \(localFilter.minPrayerPerDay)")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Slider(
                            value: Binding(
                                get: { Double(localFilter.minPrayerPerDay) },
                                set: { localFilter.minPrayerPerDay = Int($0) }
                            ),
                            in: 0...5,
                            step: 1
                        )
                        .tint(.nikahGreen)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Minimum Deen Level: \(localFilter.minDeenLevel)")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Slider(
                            value: Binding(
                                get: { Double(localFilter.minDeenLevel) },
                                set: { localFilter.minDeenLevel = Int($0) }
                            ),
                            in: 1...5,
                            step: 1
                        )
                        .tint(.nikahGreen)
                    }

                    Toggle("Require niqab in matches", isOn: $localFilter.requireNiqab)
                        .tint(.nikahGreen)
                }

                // MARK: Profession
                Section(header: Text("Profession")) {
                    TextField("Any profession", text: $localFilter.profession)
                        .autocorrectionDisabled()
                }

                // MARK: Education
                Section(header: Text("Education")) {
                    TextField("Any education", text: $localFilter.education)
                        .autocorrectionDisabled()
                }

                // MARK: Reset
                Section {
                    Button(role: .destructive) {
                        localFilter = FilterModel()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Reset All Filters")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Filter Profiles")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        onApply(localFilter)
                        dismiss()
                    }
                    .bold()
                    .foregroundColor(.nikahGreen)
                }
            }
        }
    }
}
