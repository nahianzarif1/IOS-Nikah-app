// Models/Filter.swift

import Foundation

struct FilterModel: Codable {
    var biodataId: String
    var country: String
    var district: String
    var minAge: Int
    var maxAge: Int
    var profession: String
    var education: String
    var educationType: String
    var maritalStatus: String
    var financialStatus: String
    var minHeight: Double
    var maxHeight: Double
    var onlyVerified: Bool
    var minPrayerPerDay: Int
    var madhhab: String
    var minDeenLevel: Int
    var requireNiqab: Bool

    init(
        biodataId: String = "",
        country: String = "",
        district: String = "",
        minAge: Int = 18,
        maxAge: Int = 60,
        profession: String = "",
        education: String = "",
        educationType: String = "",
        maritalStatus: String = "",
        financialStatus: String = "",
        minHeight: Double = 4.0,
        maxHeight: Double = 7.0,
        onlyVerified: Bool = false,
        minPrayerPerDay: Int = 0,
        madhhab: String = "",
        minDeenLevel: Int = 1,
        requireNiqab: Bool = false
    ) {
        self.biodataId = biodataId
        self.country = country
        self.district = district
        self.minAge = minAge
        self.maxAge = maxAge
        self.profession = profession
        self.education = education
        self.educationType = educationType
        self.maritalStatus = maritalStatus
        self.financialStatus = financialStatus
        self.minHeight = minHeight
        self.maxHeight = maxHeight
        self.onlyVerified = onlyVerified
        self.minPrayerPerDay = minPrayerPerDay
        self.madhhab = madhhab
        self.minDeenLevel = minDeenLevel
        self.requireNiqab = requireNiqab
    }

    var isDefault: Bool {
        biodataId.isEmpty &&
        country.isEmpty &&
        district.isEmpty &&
        minAge == 18 &&
        maxAge == 60 &&
        profession.isEmpty &&
        education.isEmpty &&
        educationType.isEmpty &&
        maritalStatus.isEmpty &&
        financialStatus.isEmpty &&
        minHeight == 4.0 &&
        maxHeight == 7.0 &&
        !onlyVerified &&
        minPrayerPerDay == 0 &&
        madhhab.isEmpty &&
        minDeenLevel == 1 &&
        !requireNiqab
    }
}

struct ReportModel: Identifiable, Codable {
    var id: String?
    var reportedUserId: String
    var reportedBy: String
    var reason: String
    var createdAt: Date

    init(
        id: String? = nil,
        reportedUserId: String = "",
        reportedBy: String = "",
        reason: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.reportedUserId = reportedUserId
        self.reportedBy = reportedBy
        self.reason = reason
        self.createdAt = createdAt
    }
}
