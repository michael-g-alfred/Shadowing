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
    
    /// Builds the request that onboards the current user as a payment sub-merchant.
    ///
    /// Safe to send repeatedly — the backend is idempotent once onboarding has
    /// already completed for this user.
    ///
    /// - Parameter accessToken: The requesting user's bearer token.
    /// - Returns: A configured, authenticated `POST` request.
    static func onboardExecutor(accessToken: String) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.payOnboardPath,
            method: .post,
            headers: Self.requestHeaders(accessToken: accessToken)
        )
    }
}
