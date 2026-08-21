import Foundation

/// The set of fields that can be updated on a user's profile.
///
/// Every property is optional so only the fields the user actually changed
/// are included in the encoded JSON — a `nil` field is omitted entirely
/// rather than sent as `null`, letting the server apply a true partial update.
///
/// - Note: Conforms to `Sendable` so it can be wrapped in `MGAnyEncodable`
///   and passed directly as a `.json` request body.
nonisolated struct EditProfilePayload: Encodable, Sendable {
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

    /// Encodes only the fields that are non-`nil`, omitting the rest from the
    /// resulting JSON so the request represents a true partial update.
    ///
    /// - Parameter encoder: The encoder to write data to.
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
