import Foundation
import MGNetworkingKit

extension APIConfig {
    
        // MARK: - Payments
    
    static func initiatePayment(taskId: String, accessToken: String) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.payInitiatePath(id: taskId),
            method: .post,
            headers: Self.requestHeaders(accessToken: accessToken)
        )
    }
}

