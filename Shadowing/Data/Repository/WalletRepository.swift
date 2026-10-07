import Foundation
import MGNetworkingKit

protocol WalletRepositoryProtocol {
    func getWallet() async throws -> WalletBalance
    func requestPayout(amount: Double, walletNumber: String) async throws -> PayoutReceipt
}

/// Reads the user's earnings wallet and submits withdrawal requests.
///
/// The balance is computed by the backend (there is no stored balance), so
/// this repository only mirrors what the server reports.
final class WalletRepository: WalletRepositoryProtocol {

    /// Networking layer used to perform REST requests.
    private let network: MGNetworkServiceProtocol

    /// Auth repository used to obtain a valid access token for each request.
    private let authRepository: AuthRepositoryProtocol

    init(
        network: MGNetworkServiceProtocol,
        authRepository: AuthRepositoryProtocol
    ) {
        self.network = network
        self.authRepository = authRepository
    }

    /// Obtains a valid access token, throwing if there is no active session.
    private func getValidToken() async throws -> String {
        guard let token = try await authRepository.validAccessToken() else {
            throw AuthError.noSession
        }
        return token
    }

    /// Fetches the current user's pending / available / withdrawn amounts.
    ///
    /// - Throws: A networking error, or ``AuthError/noSession``.
    func getWallet() async throws -> WalletBalance {
        DebugLogger.log("👛 🟢 WalletRepository -> getWallet - Started")
        defer { DebugLogger.log("👛 🏁 WalletRepository -> getWallet - Ended") }

        let token = try await getValidToken()
        let config = APIConfig.wallet(accessToken: token)
        let response: APIResponseDTO<WalletResponseDTO> = try await network.request(config)

        return WalletBalance(
            pendingEGP: response.data.pendingEGP,
            availableEGP: response.data.availableEGP,
            withdrawnEGP: response.data.withdrawnEGP
        )
    }

    /// Asks to withdraw part of the available balance to a mobile wallet.
    ///
    /// - Parameters:
    ///   - amount: Amount in EGP; must not exceed the available balance.
    ///   - walletNumber: An Egyptian mobile wallet number (e.g. `01012345678`).
    /// - Throws: A networking error (the server validates amount, number and
    ///   balance), or ``AuthError/noSession``.
    func requestPayout(amount: Double, walletNumber: String) async throws -> PayoutReceipt {
        DebugLogger.log("💸 🟢 WalletRepository -> requestPayout - Started")
        defer { DebugLogger.log("💸 🏁 WalletRepository -> requestPayout - Ended") }

        let token = try await getValidToken()
        let body = APIConfig.PayoutRequestBody(amount: amount, walletNumber: walletNumber)
        let config = APIConfig.requestPayout(body, accessToken: token)
        let response: APIResponseDTO<PayoutResponseDTO> = try await network.request(config)

        return PayoutReceipt(
            message: response.message,
            type: response.type,
            amountEGP: response.data.amountEGP,
            remainingEGP: response.data.remainingEGP
        )
    }
}
