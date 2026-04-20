// Models/User.swift

import Foundation
import FirebaseFirestore

struct UserModel: Identifiable, Codable, Equatable {
    var id: String?
    var displayName: String
    var email: String
    var gender: String
    var age: Int
    var dateOfBirth: Date
    var bio: String
    var country: String
    var division: String
    var district: String
    var upazila: String
    var education: String
    var institution: String
    var profession: String
    var maritalStatus: String
    var religion: String
    var madhhab: String
    var deenLevel: Int
    var prayerFrequency: String
    var guardianName: String
    var guardianContact: String
    var beard: Bool
    var hijab: Bool
    var niqab: Bool
    var height: Double
    var weight: Double
    var photos: [String]          // Array of Cloudinary URLs
    var isVerified: Bool
    var profileCompleted: Bool
    var createdAt: Date
    var lastActive: Date
    var blockedUsers: [String]

    // id is excluded from Codable — set manually from documentID
    enum CodingKeys: String, CodingKey {
        case displayName
        case email
        case gender
        case age
        case dateOfBirth
        case bio
        case country
        case division
        case district
        case upazila
        case education
        case institution
        case profession
        case maritalStatus
        case religion
        case madhhab
        case deenLevel
        case prayerFrequency
        case guardianName
        case guardianContact
        case beard
        case hijab
        case niqab
        case height
        case weight
        case photos
        case isVerified
        case profileCompleted
        case createdAt
        case lastActive
        case blockedUsers
    }

    init(
        id: String? = nil,
        displayName: String = "",
        email: String = "",
        gender: String = "",
        age: Int = 0,
        dateOfBirth: Date = Date(),
        bio: String = "",
        country: String = "Bangladesh",
        division: String = "",
        district: String = "",
        upazila: String = "",
        education: String = "",
        institution: String = "",
        profession: String = "",
        maritalStatus: String = "unmarried",
        religion: String = "Islam",
        madhhab: String = "",
        deenLevel: Int = 1,
        prayerFrequency: String = "",
        guardianName: String = "",
        guardianContact: String = "",
        beard: Bool = false,
        hijab: Bool = false,
        niqab: Bool = false,
        height: Double = 0,
        weight: Double = 0,
        photos: [String] = [],
        isVerified: Bool = false,
        profileCompleted: Bool = false,
        createdAt: Date = Date(),
        lastActive: Date = Date(),
        blockedUsers: [String] = []
    ) {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.gender = gender
        self.age = age
        self.dateOfBirth = dateOfBirth
        self.bio = bio
        self.country = country
        self.division = division
        self.district = district
        self.upazila = upazila
        self.education = education
        self.institution = institution
        self.profession = profession
        self.maritalStatus = maritalStatus
        self.religion = religion
        self.madhhab = madhhab
        self.deenLevel = deenLevel
        self.prayerFrequency = prayerFrequency
        self.guardianName = guardianName
        self.guardianContact = guardianContact
        self.beard = beard
        self.hijab = hijab
        self.niqab = niqab
        self.height = height
        self.weight = weight
        self.photos = photos
        self.isVerified = isVerified
        self.profileCompleted = profileCompleted
        self.createdAt = createdAt
        self.lastActive = lastActive
        self.blockedUsers = blockedUsers
    }

    var firstPhoto: String? {
        photos.first
    }

    var isProfileReady: Bool {
        !photos.isEmpty && !district.isEmpty && age > 0 && !guardianContact.isEmpty
    }

    static func == (lhs: UserModel, rhs: UserModel) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - Firestore helpers

    /// Build a UserModel from a Firestore DocumentSnapshot
    static func from(_ document: DocumentSnapshot) -> UserModel? {
        guard let data = document.data() else { return nil }
        return UserModel.fromData(data, id: document.documentID)
    }

    static func fromData(_ data: [String: Any], id: String) -> UserModel {
        func date(_ key: String) -> Date {
            (data[key] as? Timestamp)?.dateValue() ?? Date()
        }
        return UserModel(
            id: id,
            displayName: data["displayName"] as? String ?? "",
            email: data["email"] as? String ?? "",
            gender: data["gender"] as? String ?? "",
            age: data["age"] as? Int ?? 0,
            dateOfBirth: date("dateOfBirth"),
            bio: data["bio"] as? String ?? "",
            country: data["country"] as? String ?? "Bangladesh",
            division: data["division"] as? String ?? "",
            district: data["district"] as? String ?? "",
            upazila: data["upazila"] as? String ?? "",
            education: data["education"] as? String ?? "",
            institution: data["institution"] as? String ?? "",
            profession: data["profession"] as? String ?? "",
            maritalStatus: data["maritalStatus"] as? String ?? "unmarried",
            religion: data["religion"] as? String ?? "Islam",
            madhhab: data["madhhab"] as? String ?? "",
            deenLevel: data["deenLevel"] as? Int ?? 1,
            prayerFrequency: data["prayerFrequency"] as? String ?? "",
            guardianName: data["guardianName"] as? String ?? "",
            guardianContact: data["guardianContact"] as? String ?? "",
            beard: data["beard"] as? Bool ?? false,
            hijab: data["hijab"] as? Bool ?? false,
            niqab: data["niqab"] as? Bool ?? false,
            height: data["height"] as? Double ?? 0,
            weight: data["weight"] as? Double ?? 0,
            photos: data["photos"] as? [String] ?? [],
            isVerified: data["isVerified"] as? Bool ?? false,
            profileCompleted: data["profileCompleted"] as? Bool ?? false,
            createdAt: date("createdAt"),
            lastActive: date("lastActive"),
            blockedUsers: data["blockedUsers"] as? [String] ?? []
        )
    }

    /// Convert to a plain [String: Any] dictionary for Firestore writes
    func toFirestoreData() -> [String: Any] {
        return [
            "displayName": displayName,
            "email": email,
            "gender": gender,
            "age": age,
            "dateOfBirth": Timestamp(date: dateOfBirth),
            "bio": bio,
            "country": country,
            "division": division,
            "district": district,
            "upazila": upazila,
            "education": education,
            "institution": institution,
            "profession": profession,
            "maritalStatus": maritalStatus,
            "religion": religion,
            "madhhab": madhhab,
            "deenLevel": deenLevel,
            "prayerFrequency": prayerFrequency,
            "guardianName": guardianName,
            "guardianContact": guardianContact,
            "beard": beard,
            "hijab": hijab,
            "niqab": niqab,
            "height": height,
            "weight": weight,
            "photos": photos,
            "isVerified": isVerified,
            "profileCompleted": profileCompleted,
            "createdAt": Timestamp(date: createdAt),
            "lastActive": Timestamp(date: lastActive),
            "blockedUsers": blockedUsers
        ]
    }
}

