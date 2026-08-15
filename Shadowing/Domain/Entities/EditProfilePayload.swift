import Foundation

struct EditProfilePayload: Encodable {
    var displayName: String?
    var bio: String?
    var countryId: Int?
    var governorateId: Int?
    var phoneCountryId: Int?
    var phoneNumber: String?
    var specialtyIds: [Int]?

    enum CodingKeys: String, CodingKey {
        case displayName, bio, countryId, governorateId, phoneCountryId, phoneNumber, specialtyIds
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(displayName, forKey: .displayName)
        try container.encodeIfPresent(bio, forKey: .bio)
        try container.encodeIfPresent(countryId, forKey: .countryId)
        try container.encodeIfPresent(governorateId, forKey: .governorateId)
        try container.encodeIfPresent(phoneCountryId, forKey: .phoneCountryId)
        try container.encodeIfPresent(phoneNumber, forKey: .phoneNumber)
        try container.encodeIfPresent(specialtyIds, forKey: .specialtyIds)
    }
}
