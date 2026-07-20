import Foundation
import SwiftUI
import MGNetworkingKit

@MainActor
@Observable
final class DIContainer {
    
        // MARK: - App State
    @ObservationIgnored
    @AppStorage("appState") var appState: AppState = .onboarding
    
    var rootID = UUID()
    
    func setAppState(_ newState: AppState) {
        withAnimation(.easeInOut) {
            appState = newState
        }
    }
    
    func relaunchRoot() {
        rootID = UUID()
    }
    
        // MARK: - Core Services
    
    @ObservationIgnored
    private lazy var networkService: MGNetworkServiceProtocol = MGNetworkService()
    
    @ObservationIgnored
    private lazy var keychainService: KeychainService = KeychainService.shared
    
    @ObservationIgnored
    lazy var locationService: LocationService = CLLocationServiceImpl()
    
    @ObservationIgnored
    lazy var languageManager: LanguageManager = .shared
    
        // MARK: - Language
    
    func setLanguage(_ language: AppLanguage) {
        languageManager.setLanguage(language)
    }
    
        // MARK: - Repositories
    
    @ObservationIgnored
    private(set) lazy var authRepository: AuthRepositoryProtocol = AuthRepository(
        network: networkService, keychainService: keychainService
    )
    
    @ObservationIgnored
    private(set) lazy var userRepository: UserRepositoryProtocol = UserRepository(
        network: networkService, authRepository: authRepository
    )
    
    @ObservationIgnored
    private(set) lazy var taskRepository: TaskRepositoryProtocol = TaskRepository(
        network: networkService, authRepository: authRepository
    )
    
    @ObservationIgnored
    private(set) lazy var lookupRepository: LookupRepository = LookupRepository(
        network: networkService, authRepository: authRepository
    )
    
    
        // MARK: - Shared ViewModels
    
    @ObservationIgnored
    lazy var authViewModel = AuthViewModel(authRepo: authRepository)
    
    @ObservationIgnored
    lazy var requesterViewModel = RequesterViewModel(taskRepo: taskRepository)
    
    @ObservationIgnored
    lazy var executorViewModel = ExecutorViewModel(taskRepo: taskRepository)
    
        // MARK: - Root
    
    func makeRootView() -> RootView {
        RootView()
    }
    
        // MARK: - Onboarding
    
    func makeOnboardingView() -> OnboardingView {
        OnboardingView(vm: makeOnboardingViewModel())
    }
    
    func makeOnboardingViewModel() -> OnboardingViewModel {
        OnboardingViewModel()
    }
    
        // MARK: - Auth
    
    func makeSigninView(screen: Binding<AuthScreen>) -> SignInView {
        SignInView(screen: screen, vm: authViewModel)
    }
    
    func makeSignupView(screen: Binding<AuthScreen>) -> SignUpView {
        SignUpView(screen: screen, vm: authViewModel)
    }
    
        // MARK: - Main
    
    func makeMainView() -> MainView {
        MainView(vm: makeMainViewModel())
    }
    
    func makeMainViewModel() -> MainViewModel {
        MainViewModel()
    }
    
        // MARK: - Home
    
    func makeHomeView() -> HomeView {
        HomeView(vm: makeHomeViewModel())
    }
    
    func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel()
    }
    
        // MARK: - Requester
    
    func makeRequesterView() -> RequesterView {
        RequesterView(vm: requesterViewModel)
    }
    
    func makeRequesterViewModel() -> RequesterViewModel {
        requesterViewModel
    }
    
        // MARK: - Executor
    
    func makeExecutorView() -> ExecutorView {
        ExecutorView(vm: executorViewModel)
    }
    
    func makeExecutorViewModel() -> ExecutorViewModel {
        executorViewModel
    }
    
        // MARK: - Profile
    
    func makeProfileView() -> ProfileView {
        ProfileView(vm: makeProfileViewModel())
    }
    
    func makeProfileViewModel() -> ProfileViewModel {
        ProfileViewModel(
            authRepo: authRepository,
            userRepo: userRepository
        )
    }
    
        // MARK: - Settings
    
    func makeSettingsView() -> SettingsSheet {
        SettingsSheet(vm: makeSettingsViewModel())
    }
    
    func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(
            locationService: locationService,
            languageManager: languageManager
        )
    }
    
        // MARK: - Map
    
    func makeMapView() -> MapView {
        MapView(
            vm: makeMapViewModel(),
            makeTaskDetails: { [weak self] taskId in
                guard let self else { return AnyView(EmptyView()) }
                return AnyView(self.makeTaskDetailsView(taskId: taskId))
            }
        )
    }
    
    func makeMapViewModel() -> MapViewModel {
        MapViewModel(taskRepo: taskRepository)
    }
    
        // MARK: - Add Task Sheet
    
    func makeAddTaskSheet() -> AddTaskSheet {
        AddTaskSheet(vm: makeAddTaskViewModel())
    }
    
    func makeAddTaskViewModel() -> AddTaskVM {
        AddTaskVM(
            taskRepo: taskRepository,
            lookupRepo: lookupRepository,
            locationService: locationService,
            onTaskAdded: { [weak requesterViewModel = requesterViewModel] in
                await requesterViewModel?.loadPublishedTasks()
            }
        )
    }
    
        // MARK: - Applicants Sheet
    
    func makeApplicantsSheet() -> ApplicantsSheet {
        ApplicantsSheet(vm: makeRequesterViewModel())
    }
    
        // MARK: - Rating Sheet
    
    func makeRatingSheet(taskId: String, target: RatingTarget) -> some View {
        RatingSheet(vm: makeRatingViewModel(taskId: taskId, target: target))
    }
    
    func makeRatingViewModel(taskId: String, target: RatingTarget) -> RatingViewModel {
        RatingViewModel(taskId: taskId, target: target, taskRepo: taskRepository)
    }
    
        // MARK: - Ratings
    
    func makeRatingsView(userId: String, userName: String) -> RatingsView {
        RatingsView(vm: makeRatingsViewModel(userId: userId, userName: userName))
    }
    
    func makeRatingsViewModel(userId: String, userName: String) -> RatingsViewModel {
        RatingsViewModel(userId: userId, userName: userName, userRepo: userRepository)
    }
    
        // MARK: - Admin
    
    func makeAdminDashboardView() -> AdminDashboardView {
        AdminDashboardView()
    }
    
        // MARK: - Task Details
    
    func makeTaskDetailsView(taskId: String) -> TaskDetailsView {
        TaskDetailsView(taskId: taskId, vm: makeTaskDetailsViewModel(taskId: taskId))
    }
    
    func makeTaskDetailsViewModel(taskId: String) -> TaskDetailsViewModel {
        TaskDetailsViewModel(taskId: taskId, taskRepo: taskRepository)
    }
    
        // MARK: - Chat
    
}
