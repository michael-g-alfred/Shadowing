import Foundation

/// Errors that can occur during payment operations.
enum PaymentError: LocalizedError {
    /// Payment provider returned an invalid or malformed URL.
    case invalidPaymentURL(received: String)
    
    /// Payment initialization failed on the backend.
    case initiationFailed(message: String)
    
    /// Payment provider is temporarily unavailable.
    case providerUnavailable
    
    var errorDescription: String? {
        switch self {
        case .invalidPaymentURL(let url):
            return "Payment provider returned an invalid URL: \(url)"
        case .initiationFailed(let message):
            return "Could not initialize payment: \(message)"
        case .providerUnavailable:
            return "Payment provider is temporarily unavailable."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidPaymentURL:
            return "Please contact support with this error code."
        case .initiationFailed:
            return "Please try again or use a different payment method."
        case .providerUnavailable:
            return "Please try again in a few moments."
        }
    }
}
