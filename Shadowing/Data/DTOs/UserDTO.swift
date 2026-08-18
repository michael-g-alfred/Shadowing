import Foundation

struct UserResponseDTO: Codable {
    let user: UserDTO
}

struct UserDTO: Codable {
    let id: String
    let email: String
    let displayName: String
    let nationalId: String?
    let avatarUrl: String?
    let bio: String?
    let role: String?
    let rating: Double?
    let totalRatings: Int?
    let completedTasks: Int?
    let accountStatus: String?
    let suspendedUntil: Date?
    let countryId: Int?
    let governorateId: Int?
    let phoneCountryId: Int?
    let phoneNumber: String?
    let specialties: [SpecialtyModel]?
    let createdAt: Date?
}

extension UserDTO {
    func toDomain() -> UserModel {
        UserModel(
            id: id,
            email: email,
            displayName: displayName,
            nationalId: nationalId,
            avatarUrl: avatarUrl,
            bio: bio,
            role: role ?? "user",
            rating: rating ?? 0,
            totalRatings: totalRatings ?? 0,
            completedTasks: completedTasks ?? 0,
            accountStatus: accountStatus ?? "active",
            suspendedUntil: suspendedUntil,
            countryId: countryId,
            governorateId: governorateId,
            phoneCountryId: phoneCountryId,
            phoneNumber: phoneNumber,
            specialties: specialties ?? [],
            createdAt: createdAt
        )
    }
}

struct AvatarUploadResponseDTO: Codable {
    let avatarUrl: String
}
