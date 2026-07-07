import Foundation

enum AuthError: LocalizedError {
        // Authentication
    case invalidCredentials
    case emailAlreadyInUse
    case weakPassword
    case invalidEmail
    case userNotFound
    case accountDisabled
    case emailNotVerified
    case sessionExpired
    case unauthorized
    case noSession
    
        // Validation
    case missingFields
    case invalidInput(String)
    
        // Network
    case network
    case timeout
    case server(statusCode: Int, message: String)
    case decoding
    case unknown(Error?)
    
    var errorDescription: String? {
        switch self {
            case .invalidCredentials:
                return "Incorrect email or password."
                
            case .emailAlreadyInUse:
                return "This email is already registered."
                
            case .weakPassword:
                return "Your password is too weak."
                
            case .invalidEmail:
                return "Please enter a valid email address."
                
            case .userNotFound:
                return "No account found with this email."
                
            case .accountDisabled:
                return "This account has been disabled."
                
            case .emailNotVerified:
                return "Please verify your email before signing in."
                
            case .sessionExpired:
                return "Your session has expired. Please sign in again."
                
            case .unauthorized:
                return "You are not authorized to perform this action."
                
            case .noSession:
                return "You're not signed in."
                
            case .missingFields:
                return "Please fill in all required fields."
                
            case .invalidInput(let message):
                return message
                
            case .network:
                return "No internet connection."
                
            case .timeout:
                return "The request timed out. Please try again."
                
            case .server(_, let message):
                return message
                
            case .decoding:
                return "Couldn't read the server response."
                
            case .unknown(let error):
                return error?.localizedDescription ?? "An unknown error occurred."
        }
    }
}
