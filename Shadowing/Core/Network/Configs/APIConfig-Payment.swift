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
    
    /// Builds the request that re-checks a task's payment with the payment provider.
    ///
    /// - Parameters:
    ///   - taskId: The identifier of the task whose payment is checked.
    ///   - accessToken: The requesting user's bearer token.
    /// - Returns: A configured, authenticated `POST` request.
    static func verifyPayment(taskId: String, accessToken: String) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.payVerifyPath(id: taskId),
            method: .post,
            headers: Self.requestHeaders(accessToken: accessToken)
        )
    }
    
    /// Builds the request that refunds a paid task while its escrow is still held.
    ///
    /// - Parameters:
    ///   - taskId: The identifier of the task to refund.
    ///   - accessToken: The requesting user's bearer token.
    /// - Returns: A configured, authenticated `POST` request.
    static func refundPayment(taskId: String, accessToken: String) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.payRefundPath(id: taskId),
            method: .post,
            headers: Self.requestHeaders(accessToken: accessToken)
        )
    }
    
    /// Builds the request that fetches the current user's earnings wallet.
    ///
    /// - Parameter accessToken: The requesting user's bearer token.
    /// - Returns: A configured, authenticated `GET` request.
    static func wallet(accessToken: String) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.payWalletPath,
            method: .get,
            headers: Self.requestHeaders(accessToken: accessToken)
        )
    }
    
    /// The request body for a withdrawal request.
    nonisolated struct PayoutRequestBody: Encodable, Sendable {
        let amount: Double
        let walletNumber: String
    }
    
    /// Builds the request that asks to withdraw part of the available balance.
    ///
    /// - Parameters:
    ///   - body: The amount and the mobile wallet number to send it to.
    ///   - accessToken: The requesting user's bearer token.
    /// - Returns: A configured, authenticated `POST` request.
    static func requestPayout(
        _ body: PayoutRequestBody,
        accessToken: String
    ) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.payPayoutsPath,
            method: .post,
            headers: Self.requestHeaders(accessToken: accessToken, contentType: "application/json"),
            body: .json(MGAnyEncodable(body))
        )
    }
}
