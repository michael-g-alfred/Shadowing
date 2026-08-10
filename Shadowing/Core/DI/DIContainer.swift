import Foundation
import SwiftUI
import MGNetworkingKit

@MainActor
@Observable
final class DIContainer {
    
        // MARK: - App State
    @ObservationIgnored
    @AppStorage("appState") var appState: AppState = .setup
    
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
    
    @ObservationIgnored
    lazy var appearanceManager: AppearanceManager = .shared
    
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
    private(set) lazy var chatRepository: ChatRepositoryProtocol = ChatRepository(
        userRepo: userRepository,
        taskRepo: taskRepository
    )
    
    @ObservationIgnored
    private(set) lazy var lookupRepository: LookupRepositoryProtocol = LookupRepository(
        network: networkService
    )
    
    @ObservationIgnored
    private(set) lazy var notificationRepository: NotificationRepositoryProtocol = NotificationRepository()
    
    @ObservationIgnored
    private(set) lazy var notificationService: NotificationServiceProtocol = NotificationService()
    
        // MARK: - Shared ViewModels
    
    @ObservationIgnored
    lazy var lookupStore = LookupStore(lookupRepo: lookupRepository, languageManager: languageManager)
    
    @ObservationIgnored
    lazy var authViewModel = AuthViewModel(authRepo: authRepository, lookupStore: lookupStore)
    
    @ObservationIgnored
    lazy var requesterViewModel = RequesterViewModel(
        taskRepo: taskRepository,
        chatRepo: chatRepository,
        userRepo: userRepository,
        notificationRepo: notificationRepository,
        authRepo: authRepository
    )
    
    @ObservationIgnored
    lazy var executorViewModel = ExecutorViewModel(
        taskRepo: taskRepository,
        chatRepo: chatRepository,
        notificationRepo: notificationRepository,
        authRepo: authRepository
    )
    
    @ObservationIgnored
    lazy var chatViewModel = ChatViewModel(
        authRepo: authRepository,
        userRepo: userRepository,
        chatRepo: chatRepository
    )
    
    @ObservationIgnored
    lazy var notificationViewModel = NotificationViewModel(
        notificationRepo: notificationRepository,
        notificationService: notificationService,
        authRepo: authRepository
    )
    
    @ObservationIgnored
    lazy var settingsViewModel = SettingsViewModel(
        locationService: locationService,
        languageManager: languageManager,
        appearanceManager: appearanceManager
    )
    
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
    
        // MARK: - Setup Flow
    
    func makeSetupFlowView() -> SetupFlowView {
        SetupFlowView(vm: settingsViewModel) { [weak self] in
            self?.setAppState(.onboarding)
            self?.relaunchRoot()
        }
    }
    
    func makeLanguageSetupView() -> LanguageSetupView {
        LanguageSetupView(vm: settingsViewModel)
    }
    
    func makeModeSetupView() -> ModeSetupView {
        ModeSetupView(vm: settingsViewModel)
    }
    
    func makeDoneSetupView(onFinished: @escaping () -> Void) -> DoneSetupView {
        DoneSetupView(vm: settingsViewModel, onFinished: onFinished)
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
        settingsViewModel
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
    
        // MARK: - Notifications
    
    func makeNotificationView() -> NotificationView {
        NotificationView(vm: notificationViewModel)
    }
    
        // MARK: - Chat
    
    func makeChatView() -> ChatView {
        ChatView(vm: chatViewModel)
    }
    
    func makeChatViewModel() -> ChatViewModel {
        chatViewModel
    }
    
    func makeConversationDetailView(conversation: Conversation) -> ConversationDetailView {
        ConversationDetailView(conversation: conversation, vm: chatViewModel)
    }
    
    func makeDirectChatDetailView(taskId: String) -> some View {
        DirectChatLoaderView(taskId: taskId, vm: chatViewModel)
    }
    
        // MARK: - Add Task Sheet
    
    func makeAddTaskSheet() -> AddTaskSheet {
        AddTaskSheet(vm: makeAddTaskViewModel())
    }
    
    func makeAddTaskViewModel() -> AddTaskSheetViewModel {
        AddTaskSheetViewModel(
            taskRepo: taskRepository,
            userRepo: userRepository,
            locationService: locationService,
            lookupStore: lookupStore,
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
    
    func makeRatingSheet(taskId: String, taskTitle: String, target: RatingTarget) -> some View {
        RatingSheet(vm: makeRatingViewModel(taskId: taskId, taskTitle: taskTitle, target: target))
    }
    
    func makeRatingViewModel(taskId: String, taskTitle: String, target: RatingTarget) -> RatingSheetViewModel {
        RatingSheetViewModel(
            taskId: taskId,
            taskTitle: taskTitle,
            target: target,
            taskRepo: taskRepository,
            notificationRepo: notificationRepository,
            authRepo: authRepository
        )
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
    
        // MARK: - User
    
    func makeUserView(userId: String) -> UserView {
        UserView(vm: makeUserViewModel(userId: userId))
    }
    
    func makeUserViewModel(userId: String) -> UserViewModel {
        UserViewModel(userId: userId, userRepo: userRepository)
    }
    
}
