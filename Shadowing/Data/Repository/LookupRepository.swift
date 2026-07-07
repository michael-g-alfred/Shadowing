import Foundation
import MGNetworkingKit

final class LookupRepository: LookupRepositoryProtocol {
    
    private let network: MGNetworkServiceProtocol
    private let authRepository: AuthRepositoryProtocol
    
    init(
        network: MGNetworkServiceProtocol,
        authRepository: AuthRepositoryProtocol
    ) {
        self.network = network
        self.authRepository = authRepository
        
        DebugLogger.log("🚀 TaskRepository initialized")
    }
    
    private func getValidToken() async throws -> String {
        DebugLogger.log("🔑 Getting valid access token...")
        
        guard let token = try await authRepository.validAccessToken() else {
            DebugLogger.log("❌ No valid session found")
            throw AuthError.noSession
        }
        
        DebugLogger.log("✅ Access token acquired")
        return token
    }
    
//    func getTaskPriorities() async throws -> [TaskPriorityDTO] {
//        let token = try await getValidToken()
//        let config = APIConfig.lookups(type: "priorities", accessToken: token)
//        let response: APIResponseDTO<TaskPriorityDTO> = try await network.request(config)
//        return [response.data]
//    }
}
