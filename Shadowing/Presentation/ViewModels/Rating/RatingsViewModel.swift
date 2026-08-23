import Foundation

@MainActor
@Observable
final class RatingsViewModel {
    
    let userId: String
    let userName: String
    
    var ratings: [RatingModel] = []
    var isLoading = false
    var isLoadingMore = false
    var errorMessage: String?
    var selectedRaterId: String?
    
    private var cursor: String?
    private var hasMore = true
    
    private let userRepo: UserRepositoryProtocol
    
    init(userId: String, userName: String, userRepo: UserRepositoryProtocol) {
        self.userId = userId
        self.userName = userName
        self.userRepo = userRepo
    }
    
    func loadRatings() async {
        isLoading = true
        errorMessage = nil
        cursor = nil
        hasMore = true
        defer { isLoading = false }
        
        do {
            let result = try await userRepo.fetchUserRatings(userId: userId, cursor: nil, limit: nil)
            ratings = result.ratings
            hasMore = result.hasMore
            cursor = result.cursor
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func loadMoreIfNeeded(current rating: RatingModel) async {
        
        guard shouldLoadMore(
            hasMore: hasMore,
            isLoadingMore: isLoadingMore
        ) else { return }
        
        isLoadingMore = true
        defer { isLoadingMore = false }
        
        do {
            let result = try await userRepo.fetchUserRatings(userId: userId, cursor: cursor, limit: nil)
            ratings.append(contentsOf: result.ratings)
            hasMore = result.hasMore
            cursor = result.cursor
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func didTapRater(of rating: RatingModel) {
        selectedRaterId = rating.rater.id
    }
    
        // MARK: - Helpers
    
        /// Triggers when the visible row is within the last 5 items of the current list.
    private func shouldLoadMore(hasMore: Bool, isLoadingMore: Bool) -> Bool {
        return hasMore && !isLoadingMore
    }
}
