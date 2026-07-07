import Foundation
import Observation

enum RatingTarget {
    case executor
    case requester
    
    var title: LocalizedStringResource {
        switch self {
            case .executor:  return "Rate the Executor"
            case .requester: return "Rate the Requester"
        }
    }
}

@MainActor
@Observable
final class RatingViewModel {
    
    let taskId: String
    let target: RatingTarget
    
    var rating: Int = 0
    var comment: String = ""
    private(set) var isSubmitting = false
    var errorMessage: String?
    private(set) var didSubmit = false
    
    private let taskRepo: TaskRepositoryProtocol
    
    init(taskId: String, target: RatingTarget, taskRepo: TaskRepositoryProtocol) {
        self.taskId = taskId
        self.target = target
        self.taskRepo = taskRepo
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
            switch target {
                case .executor:
                    try await taskRepo.rateExecutor(taskId: taskId, rating: rating, comment: trimmedComment)
                case .requester:
                    try await taskRepo.rateRequester(taskId: taskId, rating: rating, comment: trimmedComment)
            }
            didSubmit = true
        } catch {
            errorMessage = "Couldn't submit your rating. Please try again."
        }
    }
}
