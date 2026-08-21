import Foundation
import MGNetworkingKit

extension APIConfig {
    
        // MARK: - Payments
    
    /// Builds the request that initiates payment for a task.
    ///
    /// - Parameters:
    ///   - taskId: The identifier of the task being paid for.
    ///   - accessToken: The requesting user's bearer token.
    /// - Returns: A configured, authenticated `POST` request.
    static func initiatePayment(taskId: String, accessToken: String) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.payInitiatePath(id: taskId),
            method: .post,
            headers: Self.requestHeaders(accessToken: accessToken)
        )
    }
}
