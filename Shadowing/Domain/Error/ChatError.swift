import Foundation

/// Errors that can occur during chat operations.
enum ChatError: LocalizedError {
    /// User is not a participant in the chat.
    case notAParticipant
    
    /// Firestore operation failed with underlying error.
    case firestoreError(underlying: Error)
    
    /// Permission denied by Firestore rules.
    case permissionDenied
    
    /// Chat document or messages not found.
    case chatNotFound
    
    /// Failed to resolve participant or task metadata.
    case resolutionFailed(reason: String)
    
    var errorDescription: String? {
        switch self {
        case .notAParticipant:
            return "You are not a participant in this chat."
        case .firestoreError(let underlying):
            return "Chat database error: \(underlying.localizedDescription)"
        case .permissionDenied:
            return "Permission denied. You may not have access to this chat."
        case .chatNotFound:
            return "This chat no longer exists."
        case .resolutionFailed(let reason):
            return "Failed to load chat details: \(reason)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .notAParticipant:
            return "This chat is only accessible to task participants."
        case .firestoreError:
            return "Please try again. If the problem persists, check your internet connection."
        case .permissionDenied:
            return "Contact support if you believe this is an error."
        case .chatNotFound:
            return "The task associated with this chat may have been deleted."
        case .resolutionFailed:
            return "Please try refreshing the conversation list."
        }
    }
}
