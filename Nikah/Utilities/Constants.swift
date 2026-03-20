// Utilities/Constants.swift

import SwiftUI

struct AppColors {
    static let primary = Color("PrimaryGreen")
    static let secondary = Color("SecondaryGold")
    static let background = Color(.systemBackground)
    static let cardBackground = Color(.secondarySystemBackground)
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)

    // Fallback solid colors if asset not found
    static let green = Color(red: 0.13, green: 0.55, blue: 0.13)
    static let gold = Color(red: 0.85, green: 0.65, blue: 0.13)
}

struct AppFonts {
    static let titleLarge = Font.system(size: 28, weight: .bold, design: .rounded)
    static let titleMedium = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let body = Font.system(size: 16, weight: .regular, design: .default)
    static let caption = Font.system(size: 13, weight: .regular, design: .default)
}

struct AppConstants {
    static let appName = "Nikah"
    static let maxPhotos = 6
    static let minAge = 18
    static let maxAge = 60
    static let minHeight = 4.0
    static let maxHeight = 7.0
    static let cloudinaryCloudName = "dfihq1if7"
    static let cloudinaryUploadPreset = "nikah_profile"
}

struct CollectionNames {
    static let users = "users"
    static let matches = "matches"
    static let likes = "likes"
    static let reports = "reports"
    static let messages = "messages"
    static let admins = "admins"
}

struct UserDefaultsKeys {
    static let hasSeenOnboarding = "hasSeenOnboarding"
}
