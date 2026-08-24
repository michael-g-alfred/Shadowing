import Foundation
import Observation
import MGNetworkingKit
import FirebaseAuth

/// Owns authentication state and session persistence for the app.
///
/// `AuthRepository` is the single source of truth for whether a user is
/// signed in, who they are, and what their current access token is. Every
/// other authenticated repository (`UserRepository`, `TaskRepository`, ...)
/// calls through ``validAccessToken()`` to obtain a fresh token before
/// making a request.
///
/// - Token strategy: the access token lives only in memory (``accessToken``);
///   the refresh token lives in the Keychain (`keychainService.refreshToken`);
///   the current user is cached to disk (`UserDefaults`) so profile info
///   survives an app relaunch without a network round trip.
@MainActor
@Observable
final class AuthRepository: AuthRepositoryProtocol {

    /// Whether a user is currently signed in.
    ///
    /// - Returns: `true` if ``currentUser`` is non-`nil`.
    var isAuthenticated: Bool { currentUser != nil }

    /// Whether the signed-in user has administrator privileges.
    ///
    /// - Returns: `false` if there is no signed-in user.
    var isAdmin: Bool { currentUser?.isAdmin ?? false }

    /// The current in-memory access token, if any.
    ///
    /// This is never persisted to disk; it is re-derived from the refresh
    /// token (via ``validAccessToken()``) on each app launch.
    private(set) var accessToken: String?

    /// The currently signed-in user, or `nil` if signed out.
    private(set) var currentUser: UserModel?

    /// Networking layer used for all REST calls.
    private let network: MGNetworkServiceProtocol

    /// Wrapper around Keychain storage for the refresh token.
    private let keychainService: KeychainService

    /// Creates an auth repository.
    ///
    /// - Parameters:
    ///   - network: Networking service used to perform REST requests.
    ///   - keychainService: Secure storage for the refresh token.
    init(
        network: MGNetworkServiceProtocol,
        keychainService: KeychainService
    ) {
        self.network = network
        self.keychainService = keychainService
    }

    // MARK: - Authentication

    /// Signs in with email and password.
    ///
    /// On success, persists the returned access token, refresh token, and
    /// user to memory/Keychain/disk respectively.
    ///
    /// - Parameters:
    ///   - email: The account email address.
    ///   - password: The account password.
    /// - Throws: A networking or server error if authentication fails.
    func signIn(email: String, password: String) async throws {
        let body = APIConfig.SigninBody(
            email: email,
            password: password
        )

        let config = APIConfig.signin(body)
        let response: APIResponseDTO<AuthResponse> = try await network.request(config)

        persist(response.data)
        await bridgeFirebaseAuth(response.data.firebaseToken)
    }

    /// Creates a new account and signs in.
    ///
    /// On success, persists the returned access token, refresh token, and
    /// user just like ``signIn(email:password:)``.
    ///
    /// - Parameters:
    ///   - email: The new account's email address.
    ///   - password: The new account's password.
    ///   - displayName: The user's display name.
    ///   - nationalId: The user's national ID number.
    ///   - countryId: Lookup ID of the user's country.
    ///   - governorateId: Lookup ID of the user's governorate.
    ///   - phoneCountryId: Lookup ID of the phone number's country code.
    ///   - phoneNumber: The user's phone number.
    ///   - bio: A short user biography.
    ///   - specialtyIds: Lookup IDs of the user's specialties.
    /// - Throws: A networking or server error if sign-up fails.
    func signUp(
        email: String,
        password: String,
        displayName: String,
        nationalId: String,
        countryId: Int,
        governorateId: Int,
        phoneCountryId: Int,
        phoneNumber: String,
        bio: String,
        specialtyIds: [Int]
    ) async throws {
        let body = APIConfig.SignupBody(
            email: email,
            password: password,
            displayName: displayName,
            nationalId: nationalId,
            phoneCountryId: phoneCountryId,
            phoneNumber: phoneNumber,
            countryId: countryId,
            governorateId: governorateId,
            bio: bio,
            specialtyIds: specialtyIds
        )

        let config = APIConfig.signup(body)
        let response: APIResponseDTO<AuthResponse> = try await network.request(config)

        persist(response.data)
        await bridgeFirebaseAuth(response.data.firebaseToken)
    }

    /// Signs the current user out.
    ///
    /// Best-effort revokes the refresh token server-side (failures are
    /// swallowed via `try?` so the user is never left "stuck" signed in
    /// locally), then always clears local session state.
    ///
    /// - Throws: Does not rethrow the server-side revoke failure; only
    ///   local-state errors would propagate, and there currently are none.
    func signOut() async throws {
        guard let refresh = keychainService.refreshToken else {
            clearSession()
            signOutFirebase()
            return
        }

        let body = APIConfig.RefreshTokenBody(refreshToken: refresh)
        let config = APIConfig.signout(body)

        try? await network.requestWithoutResponse(config)
        clearSession()
        signOutFirebase()

        // Decoupled signal so other repositories (e.g. UserRepository's
        // summary cache) can invalidate any per-session cached data without
        // AuthRepository needing a direct reference to them.
        NotificationCenter.default.post(name: .authDidSignOut, object: nil)
    }

    // MARK: - Current User

    /// Loads the previously signed-in user from disk, if any.
    ///
    /// Call this once at app launch to rehydrate ``currentUser`` without a
    /// network call. If no cached user exists, or decoding fails,
    /// ``currentUser`` is set to `nil`.
    ///
    /// - Throws: Never throws in the current implementation; decode
    ///   failures are handled internally via `try?`.
    func loadCurrentUser() async throws {
        guard
            let data = UserDefaults.standard.data(forKey: DefaultsKey.user),
            let user = try? JSONDecoder().decode(UserModel.self, from: data)
        else {
            currentUser = nil
            return
        }

        currentUser = user
    }

    // MARK: - Token

    /// Returns a valid access token, refreshing it if necessary.
    ///
    /// If an access token is already cached in memory, it is returned
    /// immediately. Otherwise, if a refresh token exists, this silently
    /// performs a token refresh and returns the new access token.
    ///
    /// - Returns: A valid access token, or `nil` if there is no session at all.
    /// - Throws: An error if the refresh request itself fails.
    func validAccessToken() async throws -> String? {
        if let accessToken {
            return accessToken
        }

        guard keychainService.refreshToken != nil else {
            return nil
        }

        try await refreshTokenIfNeeded()
        return accessToken
    }

    /// Performs a token refresh using the stored refresh token.
    ///
    /// Updates ``accessToken`` and ``currentUser`` on success, and persists
    /// the refreshed user to disk. Clears the session and throws if there is
    /// no refresh token available.
    ///
    /// - Throws: ``AuthError/server(statusCode:message:)`` if no refresh
    ///   token is available, or a networking error if the refresh request fails.
    private func refreshTokenIfNeeded() async throws {
        guard let refresh = keychainService.refreshToken else {
            clearSession()
            throw AuthError.server(
                statusCode: 401,
                message: "No refresh token"
            )
        }

        let body = APIConfig.RefreshTokenBody(
            refreshToken: refresh
        )

        let config = APIConfig.refresh(body)
        let response: APIResponseDTO<RefreshResponse> = try await network.request(config)

        accessToken = response.data.accessToken
        currentUser = response.data.user

        saveUserToDisk(response.data.user)

        // Re-establish the Firebase session on token refresh (e.g. after an
        // app relaunch where Firebase's own persisted session was lost).
        await bridgeFirebaseAuth(response.data.firebaseToken)
    }

    // MARK: - Firebase Auth Bridge

    /// Signs into Firebase Auth using a backend-minted custom token, bridging
    /// our Node/Postgres session into a Firebase identity so Firestore rules
    /// can authorize chat/notification access by `request.auth.uid`.
    ///
    /// Best-effort: a failure here never blocks the app's own (backend) session
    /// — it only means Firestore-backed features stay unavailable until the
    /// next successful bridge.
    ///
    /// - Parameter token: The custom token from the auth response, or `nil` if
    ///   the backend didn't send one.
    private func bridgeFirebaseAuth(_ token: String?) async {
        guard let token else { return }
        do {
            try await Auth.auth().signIn(withCustomToken: token)
        } catch {
            DebugLogger.log("⚠️ Firebase custom-token sign-in failed: \(error)")
        }
    }

    /// Signs out of Firebase Auth. Best-effort; failures are logged only.
    private func signOutFirebase() {
        do {
            try Auth.auth().signOut()
        } catch {
            DebugLogger.log("⚠️ Firebase sign-out failed: \(error)")
        }
    }

    // MARK: - Persistence

    /// Persists a fresh authentication response to memory, Keychain, and disk.
    ///
    /// - Parameter response: The decoded sign-in/sign-up response containing
    ///   the access token, refresh token, and user.
    private func persist(_ response: AuthResponse) {
        accessToken = response.accessToken
        keychainService.refreshToken = response.refreshToken
        currentUser = response.user

        saveUserToDisk(response.user)
    }

    /// Clears all local session state: in-memory token, Keychain refresh
    /// token, current user, and the cached user on disk.
    private func clearSession() {
        accessToken = nil
        keychainService.clear()
        currentUser = nil

        UserDefaults.standard.removeObject(
            forKey: DefaultsKey.user
        )
    }

    /// Encodes and writes a user to `UserDefaults` for offline rehydration.
    ///
    /// Silently no-ops if `user` is `nil` or encoding fails.
    ///
    /// - Parameter user: The user to persist, or `nil` to skip.
    private func saveUserToDisk(_ user: UserModel?) {
        guard let user else { return }

        do {
            let data = try JSONEncoder().encode(user)

            UserDefaults.standard.set(
                data,
                forKey: DefaultsKey.user
            )
        } catch {}
    }
}

/// `UserDefaults` keys used by ``AuthRepository``.
private enum DefaultsKey {
    /// Key under which the JSON-encoded ``UserModel`` is cached.
    static let user = "saved_user"
}

extension Notification.Name {
    /// Posted after ``AuthRepository/signOut()`` completes and local session
    /// state has been cleared. Other repositories observe this to invalidate
    /// their own per-session caches (see `UserRepository.summaryCache`).
    static let authDidSignOut = Notification.Name("AuthRepository.authDidSignOut")
}
