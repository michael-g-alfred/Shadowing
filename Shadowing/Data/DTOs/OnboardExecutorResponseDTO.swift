import Foundation

/// Response payload for `POST /pay/onboard`.
///
/// NOTE: I couldn't see wherever `PaymentResponseDTO` (used by
/// `startPayment`) already lives in the project — this file wasn't part of
/// what was uploaded — so this is a standalone drop-in. Move it next to
/// `PaymentResponseDTO` and delete this file once it's in place; there's
/// nothing else in here that depends on its physical location.
struct OnboardExecutorResponseDTO: Codable {
    /// The Paymob sub-merchant ID now on file for this user.
    let subMerchantId: String
    /// `true` if the user already had a `subMerchantId` before this call
    /// (the backend didn't contact Paymob again in that case).
    let alreadyOnboarded: Bool
}
