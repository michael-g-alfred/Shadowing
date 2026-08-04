import SwiftUI

@MainActor
@Observable
final class UserViewModel {
    
    var isLoading = false
    var errorMessage: String?
    
    var user: UserSummaryModel?
    
        // MARK: - UI State
    var isRatingsPresented = false
    
    private let userId: String
    private let userRepo: UserRepositoryProtocol
    
    init(userId: String, userRepo: UserRepositoryProtocol) {
        self.userId = userId
        self.userRepo = userRepo
    }
    
        // MARK: - Profile
    
    func loadUser() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            user = try await userRepo.fetchUserSummary(id: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
