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
    
        // MARK: - Avatar Source Selection
        /// Shows the "Photo Library / Take Photo" confirmation dialog.
    var isPhotoSourceDialogPresented = false
        /// Drives presentation of the camera sheet.
    var isCameraPresented = false
        /// Drives presentation of the PhotosPicker (library) sheet.
    var isLibraryPickerPresented = false
        /// Drives presentation of the Files app document picker (choose from
        /// iCloud Drive, On My iPhone/Mac, or other file providers).
    var isFilePickerPresented = false
    
        // MARK: - Suspension Countdown
    var suspensionCountdownText: String?
    private nonisolated(unsafe) var countdownTimer: Timer?
    
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
            updateSuspensionCountdown()
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
    
        /// Called by CameraPicker's completion closure with the captured JPEG data.
    func handleCameraCapture(_ data: Data) {
        Task {
            await uploadAvatar(imageData: data)
        }
    }
    
        /// Called by FilePicker's completion closure with the picked image's data.
    func handleFilePicked(_ data: Data) {
        Task {
            await uploadAvatar(imageData: data)
        }
    }
    
    func handleFilePickerError(_ message: String) {
        AlertCenter.shared.showError(message)
    }
    
    func uploadAvatar(imageData: Data) async {
        guard let userId = user?.id else { return }
        errorMessage = nil
        isUploadingAvatar = true
        defer { isUploadingAvatar = false }
        
        guard let compressedData = Self.compressedJPEGData(from: imageData) else {
            AlertCenter.shared.showError("Couldn't process the selected image.")
            return
        }
        
        do {
            let result = try await userRepo.uploadAvatar(
                userId: userId,
                imageData: compressedData,
                fileName: "avatar.jpg",
                mimeType: "image/jpeg"
            )
            if let currentUser = user {
                user = currentUser.withAvatarUrl(result.avatarUrl)
            }
            AlertCenter.shared.show(responseType: result.type, message: result.message)
        } catch {
            AlertCenter.shared.showError(error.localizedDescription)
        }
    }
    
        /// Resizes the image so its longest side is at most `maxDimension`,
        /// then re-encodes it as JPEG at `quality`. Applied uniformly to
        /// avatars coming from the camera, photo library, or Files picker —
        /// so a raw multi-MB photo from any source never gets uploaded as-is.
    private static func compressedJPEGData(
        from data: Data,
        maxDimension: CGFloat = 1024,
        quality: CGFloat = 0.7
    ) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        
        let originalSize = image.size
        let longestSide = max(originalSize.width, originalSize.height)
        let scale = longestSide > maxDimension ? maxDimension / longestSide : 1
        let targetSize = CGSize(width: originalSize.width * scale, height: originalSize.height * scale)
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        
        return resizedImage.jpegData(compressionQuality: quality)
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
    
        // MARK: - Suspension Countdown
    
        /// Starts (or restarts) a 1-minute repeating timer that refreshes
        /// `suspensionCountdownText` while the account is suspended. Stops
        /// itself automatically once the suspension has expired.
    private func updateSuspensionCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        
        guard let user, user.isSuspended, let until = user.suspendedUntil else {
            suspensionCountdownText = nil
            return
        }
        
        refreshCountdownText(until: until)
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshCountdownText(until: until)
            }
        }
    }
    
    private func refreshCountdownText(until: Date) {
        let remaining = until.timeIntervalSinceNow
        
        guard remaining > 0 else {
            suspensionCountdownText = nil
            countdownTimer?.invalidate()
            countdownTimer = nil
                // Suspension expired locally — reload so the server-confirmed
                // "active" status (lazily reactivated on the next fetch) shows up.
            Task { await loadProfile() }
            return
        }
        
        let days = Int(remaining) / 86400
        let hours = (Int(remaining) % 86400) / 3600
        
        if days > 0 {
            suspensionCountdownText = "\(days)d \(hours)h remaining"
        } else {
            let minutes = (Int(remaining) % 3600) / 60
            suspensionCountdownText = "\(hours)h \(minutes)m remaining"
        }
    }
    
    deinit {
        countdownTimer?.invalidate()
    }
}
