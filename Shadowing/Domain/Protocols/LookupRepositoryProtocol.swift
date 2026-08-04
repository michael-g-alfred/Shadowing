import Foundation

protocol LookupRepositoryProtocol {
    func fetchAllLookups() async throws -> AllLookupsDTO
    func fetchLookup<T: Codable>(_ type: LookupType, as: T.Type) async throws -> T
}
