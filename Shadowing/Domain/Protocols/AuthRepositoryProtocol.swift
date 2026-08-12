import Foundation

protocol AuthRepositoryProtocol: AnyObject {
    var isAuthenticated: Bool { get }
    var isAdmin: Bool { get }
    var currentUser: UserModel? { get }
    var accessToken: String? { get }
    
    func signIn(email: String, password: String) async throws
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
    ) async throws
    
    func signOut() async throws
    
    func loadCurrentUser() async throws
    
    func validAccessToken() async throws -> String?
}
