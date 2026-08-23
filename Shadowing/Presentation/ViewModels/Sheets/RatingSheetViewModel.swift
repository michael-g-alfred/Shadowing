import Foundation
import Observation
import MGNetworkingKit

enum RatingTarget {
    case executor(userId: String, displayName: String)
    case requester(userId: String, displayName: String)
    
    var personTitle: LocalizedStringResource {
        switch self {
            case .executor(_, let displayName):
                return "\(displayName)"
            case .requester(_, let displayName):
                return "\(displayName)"
        }
    }
    
    var userId: String {
        switch self {
            case .executor(let userId, _): return userId
            case .requester(let userId, _): return userId
        }
    }
}

@MainActor
@Observable
final class RatingSheetViewModel {
    
    let taskId: String
    let taskTitle: String
    let target: RatingTarget
    
    var rating: Int = 0
    var comment: String = ""
    private(set) var isSubmitting = false
    var errorMessage: String?
    private(set) var didSubmit = false
    
    private let taskRepo: TaskRepositoryProtocol
    private let notificationRepo: NotificationRepositoryProtocol
    private let authRepo: AuthRepositoryProtocol
    
    init(
        taskId: String,
        taskTitle: String,
        target: RatingTarget,
        taskRepo: TaskRepositoryProtocol,
        notificationRepo: NotificationRepositoryProtocol,
        authRepo: AuthRepositoryProtocol
    ) {
        self.taskId = taskId
        self.taskTitle = taskTitle
        self.target = target
        self.taskRepo = taskRepo
        self.notificationRepo = notificationRepo
        self.authRepo = authRepo
    }
    
    private var trimmedComment: String {
        comment.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var canSubmit: Bool {
        (1...5).contains(rating) && trimmedComment.count >= 3 && !isSubmitting
    }
    
    func selectRating(_ value: Int) {
        guard (1...5).contains(value) else { return }
        rating = value
        errorMessage = nil
    }
    
    @MainActor
    func submit() async {
        guard (1...5).contains(rating) else {
            errorMessage = "Please select a rating from 1 to 5 before continuing."
            return
        }
        guard trimmedComment.count >= 3 else {
            errorMessage = "Please write a short comment (at least 3 characters)."
            return
        }
        
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }
        
        do {
            let result: (message: String, type: String)
            switch target {
                case .executor:
                    result = try await taskRepo.rateExecutor(taskId: taskId, rating: rating, comment: trimmedComment)
                case .requester:
                    result = try await taskRepo.rateRequester(taskId: taskId, rating: rating, comment: trimmedComment)
            }
            didSubmit = true
            AlertCenter.shared.show(responseType: result.type, message: result.message)
            await notifyTargetOfRating()
        } catch {
            DebugLogger.log("⚠️ Rating submit failed — taskId: \(taskId), target: \(target), error: \(error)")

            if case let .serverError(statusCode, data) = error as? MGNetworkingKit.NetworkError, let data {
                let bodyString = String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
                DebugLogger.log("⚠️ Server said (status \(statusCode)): \(bodyString)")
            }

            AlertCenter.shared.showError(error.localizedDescription)
        }
    }
    
        // MARK: - Notifications
        /// Fire-and-forget: a failed notification send should never block or
        /// roll back the rating that was just submitted, so failures are swallowed.
    
    private func notifyTargetOfRating() async {
        let raterName = authRepo.currentUser?.displayName ?? "Someone"
        try? await notificationRepo.send(
            to: target.userId,
            type: .ratingReceived,
            subjectText: "New rating",
            messageText: "\(raterName) rated you \(rating) star\(rating == 1 ? "" : "s") for \"\(taskTitle)\"",
            taskId: taskId
        )
    }
}
