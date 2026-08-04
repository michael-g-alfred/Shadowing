import Foundation
import MGNetworkingKit

final class LookupRepository: LookupRepositoryProtocol {

    private let network: MGNetworkServiceProtocol

    init(network: MGNetworkServiceProtocol) {
        self.network = network
        DebugLogger.log("🚀 LookupRepository initialized")
    }

    func fetchAllLookups() async throws -> AllLookupsDTO {
        DebugLogger.log("📚 Fetching all lookups...")

        let config = APIConfig.lookups()
        let response: APIResponseDTO<AllLookupsDTO> = try await network.request(config)

        DebugLogger.log("✅ Lookups fetched")
        return response.data
    }

    func fetchLookup<T: Codable>(_ type: LookupType, as: T.Type) async throws -> T {
        DebugLogger.log("📚 Fetching lookup: \(type.rawValue)")

        let config = APIConfig.lookups(type: type.rawValue)
        let response: APIResponseDTO<T> = try await network.request(config)

        DebugLogger.log("✅ Lookup fetched: \(type.rawValue)")
        return response.data
    }
}
