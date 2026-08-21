import Foundation
import SwiftUI
import MGNetworkingKit

/// The app's single dependency-injection container.
///
/// `DIContainer` owns every service, repository, and shared view model used by the app, and
/// exposes a `make...()` factory method for each screen or sheet that constructs its view
/// wired to the appropriate view model. Services and repositories are built lazily so nothing
/// is instantiated until it's first needed, and shared view models (e.g. `requesterViewModel`)
/// are held as singletons so state persists correctly as the user navigates between screens
/// that share it.
///
/// A single instance is created in ``Shadowing`` and injected into the environment, where
/// `RootView` and its descendants read it via `@Environment(DIContainer.self)`.
@MainActor
@Observable
final class DIContainer {

    // MARK: - App State

    /// The top-level app state (setup, onboarding, auth, main, admin) that `RootView` switches
    /// on to decide what to display. Persisted across launches via `@AppStorage`.
    @ObservationIgnored
    @AppStorage("appState") var appState: AppState = .setup

    /// A UUID used as a SwiftUI `.id()` on the root view hierarchy to force a full rebuild
    /// (e.g. after sign-out) independent of any other identity-driving state.
    var rootID = UUID()

    /// Transitions to a new app state with an ease-in-out animation.
    func setAppState(_ newState: AppState) {
        withAnimation(.easeInOut) {
            appState = newState
        }
    }

    /// Forces the root view hierarchy to be torn down and rebuilt from scratch by assigning
    /// a new ``rootID``.
    func relaunchRoot() {
        rootID = UUID()
    }

    // MARK: - Core Services

    /// The underlying HTTP networking client used by all repositories.
    @ObservationIgnored
    private lazy var networkService: MGNetworkServiceProtocol = MGNetworkService()

    /// Secure on-device storage for auth tokens and other sensitive values.
    @ObservationIgnored
    private lazy var keychainService: KeychainService = .shared

    /// Provides the user's current location, used for task discovery and posting.
    @ObservationIgnored
    lazy var locationService: LocationServiceProtocol = LocationService()

    /// Handles requesting push notification authorization and registering for remote
    /// notifications.
    @ObservationIgnored
    private(set) lazy var notificationService: NotificationServiceProtocol = NotificationService()

    /// Manages the app's active language and layout direction.
    @ObservationIgnored
    lazy var languageManager: LanguageManager = .shared

    /// Manages the app's active color scheme / appearance mode.
    @ObservationIgnored
    lazy var appearanceManager: AppearanceManager = .shared


    // MARK: - Repositories

    /// Handles sign-up, sign-in, session restoration, and the current user's auth state.
    @ObservationIgnored
    private(set) lazy var authRepository: AuthRepositoryProtocol = AuthRepository(
        network: networkService, keychainService: keychainService
    )

    /// Reads and updates user profile data.
    @ObservationIgnored
    private(set) lazy var userRepository: UserRepositoryProtocol = UserRepository(
        network: networkService, authRepository: authRepository
    )

    /// Reads and updates tasks (published, available, assigned, and completed).
    @ObservationIgnored
    private(set) lazy var taskRepository: TaskRepositoryProtocol = TaskRepository(
        network: networkService, authRepository: authRepository
    )

    /// Handles conversation and message data for in-app chat.
    @ObservationIgnored
    private(set) lazy var chatRepository: ChatRepositoryProtocol = ChatRepository(
        userRepo: userRepository,
        taskRepo: taskRepository,
        notificationRepo: notificationRepository
    )

    /// Provides localized lookup data (e.g. task categories) used throughout the app.
    @ObservationIgnored
    private(set) lazy var lookupRepository: LookupRepositoryProtocol = LookupRepository(
        network: networkService
    )

    /// Reads and updates in-app notifications.
    @ObservationIgnored
    private(set) lazy var notificationRepository: NotificationRepositoryProtocol = NotificationRepository()


    // MARK: - Shared ViewModels

    /// Holds localized lookup data and reloads it whenever the active language changes.
    @ObservationIgnored
    lazy var lookupStore = LookupStore(lookupRepo: lookupRepository, languageManager: languageManager)

    /// Drives the sign-up / sign-in flow.
    @ObservationIgnored
    lazy var authViewModel = AuthViewModel(authRepo: authRepository, lookupStore: lookupStore)

    /// Drives all requester-side task screens (published, completed, applicants, ratings).
    /// Shared across every requester view so task lists and pending-rating state stay
    /// consistent as the user navigates.
    @ObservationIgnored
    lazy var requesterViewModel = RequesterViewModel(
        authRepo: authRepository,
        userRepo: userRepository,
        taskRepo: taskRepository,
        chatRepo: chatRepository,
        notificationRepo: notificationRepository,
    )

    /// Drives all executor-side task screens (available, assigned, completed, ratings).
    /// Shared across every executor view for the same reason as ``requesterViewModel``.
    @ObservationIgnored
    lazy var executorViewModel = ExecutorViewModel(
        authRepo: authRepository,
        taskRepo: taskRepository,
        chatRepo: chatRepository,
        notificationRepo: notificationRepository
    )

    /// Drives the conversation list and individual chat screens.
    @ObservationIgnored
    lazy var chatViewModel = ChatViewModel(
        authRepo: authRepository,
        userRepo: userRepository,
        chatRepo: chatRepository
    )

    /// Drives the notification list and unread badge state.
    @ObservationIgnored
    lazy var notificationViewModel = NotificationViewModel(
        notificationRepo: notificationRepository,
        notificationService: notificationService,
        authRepo: authRepository
    )

    /// Drives the settings screen and the first-launch setup flow (language, appearance).
    @ObservationIgnored
    lazy var settingsViewModel = SettingsViewModel(
        locationService: locationService,
        languageManager: languageManager,
        appearanceManager: appearanceManager
    )

    // MARK: - Root

    /// The app's top-level view, responsible for routing between ``appState`` cases.
    func makeRootView() -> RootView {
        RootView()
    }

    // MARK: - Onboarding

    /// The first-launch onboarding screen shown before authentication.
    func makeOnboardingView() -> OnboardingView {
        OnboardingView(vm: makeOnboardingViewModel())
    }

    /// Creates a fresh view model for the onboarding screen.
    func makeOnboardingViewModel() -> OnboardingViewModel {
        OnboardingViewModel()
    }

    // MARK: - Setup Flow

    /// The first-launch setup flow (language and appearance selection), shown before
    /// onboarding. Transitions to onboarding and relaunches the root view when finished.
    func makeSetupFlowView() -> SetupFlowView {
        SetupFlowView(vm: settingsViewModel) { [weak self] in
            self?.setAppState(.onboarding)
            self?.relaunchRoot()
        }
    }

    /// The language-selection step of the setup flow.
    func makeLanguageSetupView() -> LanguageSetupView {
        LanguageSetupView(vm: settingsViewModel)
    }

    /// The appearance-mode-selection step of the setup flow.
    func makeModeSetupView() -> ModeSetupView {
        ModeSetupView(vm: settingsViewModel)
    }

    /// The final confirmation step of the setup flow.
    ///
    /// - Parameter onFinished: Called when the user completes this step.
    func makeDoneSetupView(onFinished: @escaping () -> Void) -> DoneSetupView {
        DoneSetupView(vm: settingsViewModel, onFinished: onFinished)
    }

    // MARK: - Auth

    /// The sign-in screen.
    ///
    /// - Parameter screen: A binding to the currently displayed auth screen, allowing this
    ///   view to switch to sign-up.
    func makeSigninView(screen: Binding<AuthScreen>) -> SignInView {
        SignInView(screen: screen, vm: authViewModel)
    }

    /// The sign-up screen.
    ///
    /// - Parameter screen: A binding to the currently displayed auth screen, allowing this
    ///   view to switch to sign-in.
    func makeSignupView(screen: Binding<AuthScreen>) -> SignUpView {
        SignUpView(screen: screen, vm: authViewModel)
    }

    // MARK: - Main

    /// The main tab container shown once the user is authenticated.
    func makeMainView() -> MainView {
        MainView(vm: makeMainViewModel())
    }

    /// Creates a fresh view model for the main tab container.
    func makeMainViewModel() -> MainViewModel {
        MainViewModel()
    }

    // MARK: - Home

    /// The home tab's landing screen.
    func makeHomeView() -> HomeView {
        HomeView(vm: makeHomeViewModel())
    }

    /// Creates a fresh view model for the home screen.
    func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel()
    }

    // MARK: - Requester

    /// The requester tab, showing the user's published and completed tasks.
    func makeRequesterView() -> RequesterView {
        RequesterView(vm: requesterViewModel)
    }

    /// Returns the shared ``requesterViewModel``.
    func makeRequesterViewModel() -> RequesterViewModel {
        requesterViewModel
    }

    // MARK: - Executor

    /// The executor tab, showing available, assigned, and completed tasks.
    func makeExecutorView() -> ExecutorView {
        ExecutorView(vm: executorViewModel)
    }

    /// Returns the shared ``executorViewModel``.
    func makeExecutorViewModel() -> ExecutorViewModel {
        executorViewModel
    }

    // MARK: - Profile

    /// The current user's profile screen.
    func makeProfileView() -> ProfileView {
        ProfileView(vm: makeProfileViewModel())
    }

    /// Creates a fresh view model for the profile screen.
    func makeProfileViewModel() -> ProfileViewModel {
        ProfileViewModel(
            authRepo: authRepository,
            userRepo: userRepository
        )
    }

    // MARK: - EditProfileSheet

    /// The sheet for editing a user's profile.
    ///
    /// - Parameters:
    ///   - user: The user being edited.
    ///   - vm: The profile view model to persist changes through.
    func makeEditProfileSheet(user: UserModel, vm: ProfileViewModel) -> EditProfileSheet {
        EditProfileSheet(user: user, vm: vm, lookupStore: lookupStore)
    }

    // MARK: - SettingsSheet

    /// The app settings sheet.
    func makeSettingsSheet() -> SettingsSheet {
        SettingsSheet(vm: makeSettingsViewModel())
    }

    /// Returns the shared ``settingsViewModel``.
    func makeSettingsViewModel() -> SettingsViewModel {
        settingsViewModel
    }

    // MARK: - Map

    /// The map screen showing nearby tasks, with task detail lookup wired for pin taps.
    func makeMapView() -> MapView {
        MapView(
            vm: makeMapViewModel(),
            makeTaskDetails: { [weak self] taskId in
                guard let self else { return AnyView(EmptyView()) }
                return AnyView(self.makeTaskDetailsView(taskId: taskId))
            }
        )
    }

    /// Creates a fresh view model for the map screen.
    func makeMapViewModel() -> MapViewModel {
        MapViewModel(taskRepo: taskRepository)
    }

    // MARK: - Notifications

    /// The in-app notification list screen.
    func makeNotificationView() -> NotificationView {
        NotificationView(vm: notificationViewModel)
    }

    // MARK: - Chat

    /// The conversation list screen.
    func makeChatView() -> ChatView {
        ChatView(vm: chatViewModel)
    }

    /// Returns the shared ``chatViewModel``.
    func makeChatViewModel() -> ChatViewModel {
        chatViewModel
    }

    /// The detail screen for an existing conversation.
    ///
    /// - Parameter conversation: The conversation to display.
    func makeConversationDetailView(conversation: Conversation) -> ConversationDetailView {
        ConversationDetailView(conversation: conversation, vm: chatViewModel)
    }

    /// A chat detail screen resolved directly from a task ID, loading or creating the
    /// associated conversation as needed.
    ///
    /// - Parameter taskId: The task whose chat should be displayed.
    func makeDirectChatDetailView(taskId: String) -> some View {
        DirectChatLoaderView(taskId: taskId, vm: chatViewModel)
    }

    // MARK: - AddTask Sheet

    /// The sheet for posting a new task. Reloads the requester's published tasks on success.
    func makeAddTaskSheet() -> AddTaskSheet {
        AddTaskSheet(vm: makeAddTaskViewModel())
    }

    /// Creates a fresh view model for the add-task sheet.
    func makeAddTaskViewModel() -> AddTaskSheetViewModel {
        AddTaskSheetViewModel(
            authRepo: authRepository,
            taskRepo: taskRepository,
            userRepo: userRepository,
            notificationRepo : notificationRepository,
            locationService: locationService,
            lookupStore: lookupStore,
            onTaskAdded: { [weak requesterViewModel = requesterViewModel] in
                await requesterViewModel?.loadPublishedTasks()
            }
        )
    }

    // MARK: - Applicants Sheet

    /// The sheet listing applicants for a requester's task.
    func makeApplicantsSheet() -> ApplicantsSheet {
        ApplicantsSheet(vm: makeRequesterViewModel())
    }

    // MARK: - Rating Sheet

    /// The mandatory rating sheet shown after a task completes.
    ///
    /// - Parameters:
    ///   - taskId: The completed task being rated.
    ///   - taskTitle: The task's title, shown for context.
    ///   - target: The user being rated.
    func makeRatingSheet(taskId: String, taskTitle: String, target: RatingTarget) -> some View {
        RatingSheet(vm: makeRatingViewModel(taskId: taskId, taskTitle: taskTitle, target: target))
    }

    /// Creates a fresh view model for the rating sheet.
    ///
    /// - Parameters:
    ///   - taskId: The completed task being rated.
    ///   - taskTitle: The task's title, shown for context.
    ///   - target: The user being rated.
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

    /// The screen listing all ratings a given user has received.
    ///
    /// - Parameters:
    ///   - userId: The user whose ratings should be displayed.
    ///   - userName: The user's display name, shown as the screen title.
    func makeRatingsView(userId: String, userName: String) -> RatingsView {
        RatingsView(vm: makeRatingsViewModel(userId: userId, userName: userName))
    }

    /// Creates a fresh view model for the ratings list screen.
    ///
    /// - Parameters:
    ///   - userId: The user whose ratings should be loaded.
    ///   - userName: The user's display name.
    func makeRatingsViewModel(userId: String, userName: String) -> RatingsViewModel {
        RatingsViewModel(userId: userId, userName: userName, userRepo: userRepository)
    }

    // MARK: - Admin

    /// The admin dashboard, shown when the current user is an admin.
    func makeAdminDashboardView() -> AdminDashboardView {
        AdminDashboardView()
    }

    // MARK: - Task Details

    /// The detail screen for a single task.
    ///
    /// - Parameter taskId: The task to display.
    func makeTaskDetailsView(taskId: String) -> TaskDetailsView {
        TaskDetailsView(taskId: taskId, vm: makeTaskDetailsViewModel(taskId: taskId))
    }

    /// Creates a fresh view model for the task details screen, wired to both the requester
    /// and executor view models so it can reflect either role's available actions.
    ///
    /// - Parameter taskId: The task to load.
    func makeTaskDetailsViewModel(taskId: String) -> TaskDetailsViewModel {
        TaskDetailsViewModel(
            taskId: taskId,
            taskRepo: taskRepository,
            requesterVM: requesterViewModel,
            executorVM: executorViewModel,
            authRepo: authRepository
        )
    }

    // MARK: - User

    /// The public profile screen for another user.
    ///
    /// - Parameter userId: The user to display.
    func makeUserView(userId: String) -> UserView {
        UserView(vm: makeUserViewModel(userId: userId))
    }

    /// Creates a fresh view model for another user's public profile screen.
    ///
    /// - Parameter userId: The user to load.
    func makeUserViewModel(userId: String) -> UserViewModel {
        UserViewModel(userId: userId, userRepo: userRepository)
    }

}
