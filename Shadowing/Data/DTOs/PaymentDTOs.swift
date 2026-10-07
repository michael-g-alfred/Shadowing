import Foundation

// MARK: - Response DTOs (data payloads of the /pay endpoints)

/// `data` of `POST /pay/:id/verify`.
struct VerifyPaymentResponseDTO: Codable {
    let status: String
    let escrowStatus: String
}

/// `data` of `POST /pay/:id/refund`.
struct RefundResponseDTO: Codable {
    let amountEGP: Double?
}

/// `data` of `GET /pay/wallet`.
struct WalletResponseDTO: Codable {
    let pendingEGP: Double
    let availableEGP: Double
    let withdrawnEGP: Double
}

/// `data` of `POST /pay/payouts`.
struct PayoutResponseDTO: Codable {
    let payoutId: String
    let status: String
    let amountEGP: Double
    let remainingEGP: Double
}

// MARK: - Domain models

/// A task's state right after the server re-checked its payment with Paymob.
struct PaymentVerification {
    let status: String
    let escrowStatus: String
}

/// The current user's earnings, in EGP.
struct WalletBalance {
    /// Share of tasks whose money is still held (not confirmed yet).
    let pendingEGP: Double
    /// Share of confirmed tasks, minus withdrawals already requested.
    let availableEGP: Double
    /// Total already requested for withdrawal (pending or paid).
    let withdrawnEGP: Double
}

/// The server's answer to a withdrawal request.
struct PayoutReceipt {
    let message: String
    let type: String
    let amountEGP: Double
    let remainingEGP: Double
}
