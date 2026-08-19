import Foundation
import MGNetworkingKit

/// Fetches static reference/lookup data used to populate pickers throughout
/// the app (countries, governorates, specialties, currencies, priorities, etc.).
///
/// This is the simplest repository in the app: no caching, no auth
/// requirement, and only two methods.
final class LookupRepository: LookupRepositoryProtocol {

    /// Networking layer used to perform REST requests.
    private let network: MGNetworkServiceProtocol

    /// Creates a lookup repository.
    ///
    /// - Parameter network: Networking service used to perform REST requests.
    init(network: MGNetworkServiceProtocol) {
        self.network = network
    }

    /// Fetches every lookup table in a single request.
    ///
    /// - Returns: An ``AllLookupsDTO`` containing all lookup collections.
    /// - Throws: A networking error if the request fails.
    func fetchAllLookups() async throws -> AllLookupsDTO {
        let config = APIConfig.lookups()
        let response: APIResponseDTO<AllLookupsDTO> = try await network.request(config)
        return response.data
    }

    /// Fetches a single lookup collection, generically typed to the caller's
    /// expected DTO.
    ///
    /// - Parameters:
    ///   - type: Which lookup collection to fetch (e.g. `.countries`).
    ///   - as: The `Codable` type to decode the response into. The caller is
    ///     responsible for passing a type that matches `type`.
    /// - Returns: The decoded lookup data of type `T`.
    /// - Throws: A networking or decoding error if the request fails.
    func fetchLookup<T: Codable & Sendable>(_ type: LookupType, as: T.Type) async throws -> T {
        let config = APIConfig.lookups(type: type.rawValue)
        let response: APIResponseDTO<T> = try await network.request(config)
        return response.data
    }
}
