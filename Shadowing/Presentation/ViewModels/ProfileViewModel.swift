import SwiftUI
import CoreLocation

@MainActor
@Observable
final class ProfileViewModel {
    
    var isLoading = false
    var isUploadingAvatar = false
    var errorMessage: String?
    
    var user: UserModel?
    
    var currentLanguage: AppLanguage {
        languageManager.currentLanguage
    }
    
    private let authRepo: AuthRepositoryProtocol
    private let userRepo: UserRepositoryProtocol
    private let locationService: LocationService
    private let languageManager: LanguageManager
    
    init(authRepo: AuthRepositoryProtocol, userRepo: UserRepositoryProtocol, locationService: LocationService, languageManager: LanguageManager) {
        self.authRepo = authRepo
        self.userRepo = userRepo
        self.locationService = locationService
        self.languageManager = languageManager
    }
    
        // MARK: - Location
    
    var locationAuthorizationStatus: CLAuthorizationStatus {
        locationService.authorizationStatus
    }
    
    var locationStatusTitle: String {
        switch locationAuthorizationStatus {
            case .authorizedAlways: return "Always Allowed"
            case .authorizedWhenInUse: return "Allowed While Using App"
            case .denied: return "Denied"
            case .restricted: return "Restricted"
            case .notDetermined: return "Not Determined"
            @unknown default: return "Unknown"
        }
    }
    
    var locationStatusIcon: String {
        switch locationAuthorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse: return "location.fill"
            case .denied, .restricted: return "location.slash"
            case .notDetermined: return "location"
            @unknown default: return "location"
        }
    }
    
    var locationStatusTint: Color {
        switch locationAuthorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse: return .green
            case .denied, .restricted: return .red
            case .notDetermined: return .orange
            @unknown default: return .gray
        }
    }
    
    var needsLocationSettingsRedirect: Bool {
        locationAuthorizationStatus == .denied || locationAuthorizationStatus == .restricted
    }
    
    var needsLocationRequest: Bool {
        locationAuthorizationStatus == .notDetermined
    }
    
    func requestLocationAccess() {
        locationService.requestLocation()
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
    
    func setLanguage(_ language: AppLanguage) {
        languageManager.setLanguage(language)
    }
    
        // MARK: - Avatar
    
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
}
