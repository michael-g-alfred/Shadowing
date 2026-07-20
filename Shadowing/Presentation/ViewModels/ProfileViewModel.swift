import SwiftUI
import PhotosUI

@MainActor
@Observable
final class ProfileViewModel {
    
    var isLoading = false
    var isUploadingAvatar = false
    var errorMessage: String?
    
    var user: UserModel?
    
        // MARK: - UI State
    var isIdExpanded = false
    var isNationalIDAppearance = false
    var selectedPhotoItem: PhotosPickerItem? {
        didSet {
            guard let selectedPhotoItem else { return }
            Task {
                await handlePhotoSelection(selectedPhotoItem)
            }
        }
    }
    var isRatingsPresented = false
    var isSettingsPresented = false
    
    private let authRepo: AuthRepositoryProtocol
    private let userRepo: UserRepositoryProtocol
    
    init(authRepo: AuthRepositoryProtocol, userRepo: UserRepositoryProtocol) {
        self.authRepo = authRepo
        self.userRepo = userRepo
    }
    
        // MARK: - Profile
    
    func loadProfile() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        guard let id = authRepo.currentUser?.id else {
            errorMessage = "No active session."
            return
        }
        
        do {
            user = try await userRepo.fetchUser(id: id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func signout() async -> Bool {
        isLoading = true
        defer { isLoading = false }
        do {
            try await authRepo.signOut()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
    
        // MARK: - Avatar
    
    private func handlePhotoSelection(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        await uploadAvatar(imageData: data)
    }
    
    func uploadAvatar(imageData: Data) async {
        guard let userId = user?.id else { return }
        errorMessage = nil
        isUploadingAvatar = true
        defer { isUploadingAvatar = false }
        
        do {
            let avatarUrl = try await userRepo.uploadAvatar(
                userId: userId,
                imageData: imageData,
                fileName: "avatar.jpg",
                mimeType: "image/jpeg"
            )
            if let currentUser = user {
                user = currentUser.withAvatarUrl(avatarUrl)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
        // MARK: - ID Display
    
    func toggleIdExpanded() {
        isIdExpanded.toggle()
    }
    
    func toggleNationalIDAppearance() {
        isNationalIDAppearance.toggle()
    }
    
    func displayedId(for id: String) -> String {
        guard !isIdExpanded else { return id }
        return "\(id.prefix(9))...."
    }
}
