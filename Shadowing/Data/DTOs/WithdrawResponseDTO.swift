import Foundation

struct WithdrawResponseDTO: Codable {
    let suspended: Bool
    let warning: String?
}

struct WithdrawResult {
    /// The top-level response message — always meaningful ("Withdrawn
    /// successfully!" or, when the 3rd strike lands, the suspension notice).
    let message: String
    /// The top-level response type ("success" | "warning").
    let type: String
    let suspended: Bool
    /// Set only on the 2nd-to-last strike — a heads-up nudge distinct from
    /// `message`. When present, prefer showing this over `message`.
    let warning: String?
}
