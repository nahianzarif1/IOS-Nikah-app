import Foundation
import FirebaseFirestore

struct MatchUserSnapshot: Codable, Equatable {
    var id: String
    var displayName: String
    var gender: String
    var age: Int
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
    var prayerFrequency: String
    var beard: Bool
    var hijab: Bool
    var height: Double
    var weight: Double
    var photos: [String]
    var isVerified: Bool
    var profileCompleted: Bool

    init(user: UserModel) {
        self.id = user.id ?? ""
        self.displayName = user.displayName
        self.gender = user.gender
        self.age = user.age
        self.bio = user.bio
        self.country = user.country
        self.division = user.division
        self.district = user.district
        self.upazila = user.upazila
        self.education = user.education
        self.institution = user.institution
        self.profession = user.profession
        self.maritalStatus = user.maritalStatus
        self.religion = user.religion
        self.prayerFrequency = user.prayerFrequency
        self.beard = user.beard
        self.hijab = user.hijab
        self.height = user.height
        self.weight = user.weight
        self.photos = user.photos
        self.isVerified = user.isVerified
        self.profileCompleted = user.profileCompleted
    }

    init?(id: String, data: [String: Any]) {
        self.id = id
        self.displayName = data["displayName"] as? String ?? ""
        self.gender = data["gender"] as? String ?? ""
        self.age = data["age"] as? Int ?? 0
        self.bio = data["bio"] as? String ?? ""
        self.country = data["country"] as? String ?? "Bangladesh"
        self.division = data["division"] as? String ?? ""
        self.district = data["district"] as? String ?? ""
        self.upazila = data["upazila"] as? String ?? ""
        self.education = data["education"] as? String ?? ""
        self.institution = data["institution"] as? String ?? ""
        self.profession = data["profession"] as? String ?? ""
        self.maritalStatus = data["maritalStatus"] as? String ?? "unmarried"
        self.religion = data["religion"] as? String ?? "Islam"
        self.prayerFrequency = data["prayerFrequency"] as? String ?? ""
        self.beard = data["beard"] as? Bool ?? false
        self.hijab = data["hijab"] as? Bool ?? false
        self.height = data["height"] as? Double ?? 0
        self.weight = data["weight"] as? Double ?? 0
        self.photos = data["photos"] as? [String] ?? []
        self.isVerified = data["isVerified"] as? Bool ?? false
        self.profileCompleted = data["profileCompleted"] as? Bool ?? false
    }

    func toFirestoreData() -> [String: Any] {
        [
            "displayName": displayName,
            "gender": gender,
            "age": age,
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
            "prayerFrequency": prayerFrequency,
            "beard": beard,
            "hijab": hijab,
            "height": height,
            "weight": weight,
            "photos": photos,
            "isVerified": isVerified,
            "profileCompleted": profileCompleted
        ]
    }

    func asUserModel() -> UserModel {
        UserModel(
            id: id,
            displayName: displayName,
            gender: gender,
            age: age,
            bio: bio,
            country: country,
            division: division,
            district: district,
            upazila: upazila,
            education: education,
            institution: institution,
            profession: profession,
            maritalStatus: maritalStatus,
            religion: religion,
            prayerFrequency: prayerFrequency,
            beard: beard,
            hijab: hijab,
            height: height,
            weight: weight,
            photos: photos,
            isVerified: isVerified,
            profileCompleted: profileCompleted
        )
    }
}

struct MatchModel: Identifiable, Codable {
    var id: String?
    var users: [String]
    var createdAt: Date
    var userSnapshots: [String: MatchUserSnapshot]

    enum CodingKeys: String, CodingKey {
        case users
        case createdAt
        case userSnapshots
    }

    init(
        id: String? = nil,
        users: [String] = [],
        createdAt: Date = Date(),
        userSnapshots: [String: MatchUserSnapshot] = [:]
    ) {
        self.id = id
        self.users = users
        self.createdAt = createdAt
        self.userSnapshots = userSnapshots
    }

    func otherUserId(currentUserId: String) -> String? {
        users.first(where: { $0 != currentUserId })
    }

    func otherUserSnapshot(currentUserId: String) -> MatchUserSnapshot? {
        guard let otherUserId = otherUserId(currentUserId: currentUserId) else { return nil }
        return userSnapshots[otherUserId]
    }

    func otherUser(currentUserId: String) -> UserModel? {
        otherUserSnapshot(currentUserId: currentUserId)?.asUserModel()
    }

    static func from(_ document: DocumentSnapshot) -> MatchModel? {
        guard let data = document.data() else { return nil }

        let rawSnapshots = data["userSnapshots"] as? [String: Any] ?? [:]
        let userSnapshots = rawSnapshots.reduce(into: [String: MatchUserSnapshot]()) { partial, item in
            let (userId, rawValue) = item
            guard let snapshotData = rawValue as? [String: Any],
                  let snapshot = MatchUserSnapshot(id: userId, data: snapshotData) else {
                return
            }
            partial[userId] = snapshot
        }

        return MatchModel(
            id: document.documentID,
            users: data["users"] as? [String] ?? [],
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            userSnapshots: userSnapshots
        )
    }

    func toFirestoreData() -> [String: Any] {
        let snapshotsData = userSnapshots.reduce(into: [String: Any]()) { partial, item in
            partial[item.key] = item.value.toFirestoreData()
        }

        return [
            "users": users,
            "createdAt": Timestamp(date: createdAt),
            "userSnapshots": snapshotsData
        ]
    }
}

struct LikeModel: Identifiable, Codable {
    var id: String?
    var fromUserId: String
    var toUserId: String
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case fromUserId
        case toUserId
        case createdAt
    }

    init(id: String? = nil, fromUserId: String = "", toUserId: String = "", createdAt: Date = Date()) {
        self.id = id
        self.fromUserId = fromUserId
        self.toUserId = toUserId
        self.createdAt = createdAt
    }

    static func from(_ document: DocumentSnapshot) -> LikeModel? {
        guard let data = document.data() else { return nil }
        return LikeModel(
            id: document.documentID,
            fromUserId: data["fromUserId"] as? String ?? "",
            toUserId: data["toUserId"] as? String ?? "",
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }

    func toFirestoreData() -> [String: Any] {
        [
            "fromUserId": fromUserId,
            "toUserId": toUserId,
            "createdAt": Timestamp(date: createdAt)
        ]
    }
}
