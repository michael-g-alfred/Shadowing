import Foundation
import MGNetworkingKit

final class LookupRepository: LookupRepositoryProtocol {
    
    private let network: MGNetworkServiceProtocol
    
    init(network: MGNetworkServiceProtocol) {
        self.network = network
    }
    
    func fetchAllLookups() async throws -> AllLookupsDTO {
        let config = APIConfig.lookups()
        let response: APIResponseDTO<AllLookupsDTO> = try await network.request(config)
        return response.data
    }
    
    func fetchLookup<T: Codable>(_ type: LookupType, as: T.Type) async throws -> T {
        let config = APIConfig.lookups(type: type.rawValue)
        let response: APIResponseDTO<T> = try await network.request(config)
        return response.data
    }
}
