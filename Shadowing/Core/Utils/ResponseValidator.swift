import Foundation

/// Validates that API responses indicate success before processing data.
enum ResponseValidator {
    /// Validates that a response code indicates success (2xx range).
    ///
    /// - Parameters:
    ///   - code: The response code from the API envelope.
    ///   - message: The message accompanying the response.
    /// - Throws: `APIError.serverError` if the code is not in the 2xx range.
    static func validateSuccessCode(_ code: Int, message: String) throws {
        guard (200..<300).contains(code) else {
            throw APIError.serverError(statusCode: code, message: message)
        }
    }
}

/// API-level errors that extend the backend response envelope.
enum APIError: LocalizedError {
    /// Server returned an error status code.
    case serverError(statusCode: Int, message: String)
    
    /// Network or decoding error.
    case networkError(underlying: Error)
    
    var errorDescription: String? {
        switch self {
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .serverError(let code, _):
            if (500..<600).contains(code) {
                return "The server is experiencing issues. Please try again later."
            } else if (400..<500).contains(code) {
                return "There was a problem with your request. Please try again."
            }
            return "An unexpected error occurred. Please try again."
        case .networkError:
            return "Please check your internet connection and try again."
        }
    }
}
