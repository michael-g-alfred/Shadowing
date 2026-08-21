import Foundation

    /// A centralized catalog of the backend's API paths, built by combining a small set of
    /// route prefixes with path segments and route parameters.
    ///
    /// All paths are relative; combine them with ``baseURL`` to form a full request URL.
enum APIEndpoints {
    
        // MARK: - Base URL
    
        /// The backend's base URL, read from the `BaseURL` key in the app's `Info.plist`.
        ///
        /// Crashes at first access if the key is missing, since the app cannot make any network
        /// request without it.
    static let baseURL: String = {
        guard let url = Bundle.main.object(
            forInfoDictionaryKey: "BaseURL"
        ) as? String else {
            fatalError("BaseURL not found in Info.plist")
        }
        return url
    }()
    
        // MARK: - Routes
    
        /// Prefix for all authentication endpoints.
    static let authRoute = "/auth"
        /// Prefix for all user endpoints.
    static let userRoute = "/users"
        /// Prefix for all task endpoints. Empty because task paths already begin with their own
        /// `/tasks`, `/req`, or `/exe` segment.
    static let taskRoute = ""
        /// Prefix for all lookup endpoints. Empty because lookup paths already begin with
        /// `/lookups`.
    static let lookupRoute = ""
    
        // MARK: - Public
    
        /// Unauthenticated endpoint used to verify the backend is reachable.
    static let healthCheckPath = "/health-check"
    
        // MARK: - Auth
    
        /// Creates a new account.
    static let signupPath = authRoute + "/signup"
        /// Authenticates an existing account.
    static let signinPath = authRoute + "/signin"
        /// Invalidates the current session.
    static let signoutPath = authRoute + "/signout"
        /// Exchanges a refresh token for a new access token.
    static let refreshPath = authRoute + "/refresh"
    
        // MARK: - Users
    
        /// Returns the total number of registered users.
    static let userCountPath = userRoute + "/count"
    
        /// The full profile for a given user.
        ///
        /// - Parameter id: The user's ID.
    static func userPath(id: String) -> String {
        return userRoute + "/\(id)"
    }
    
        /// A lightweight summary of a given user, used where the full profile isn't needed.
        ///
        /// - Parameter id: The user's ID.
    static func userSummaryPath(id: String) -> String {
        return userRoute + "/\(id)/summary"
    }
    
        /// The ratings a given user has received.
        ///
        /// - Parameter id: The user's ID.
    static func userRatingsPath(id: String) -> String {
        return userRoute + "/\(id)/ratings"
    }
    
        /// Uploads or fetches a given user's avatar image.
        ///
        /// - Parameter id: The user's ID.
    static func userAvatarPath(id: String) -> String {
        return userRoute + "/\(id)/avatar"
    }
    
        /// Users offering a given service specialty.
        ///
        /// - Parameter serviceId: The specialty's lookup ID.
    static func usersBySpecialtyPath(serviceId: Int) -> String {
        return userRoute + "/by-specialty/\(serviceId)"
    }
    
        // MARK: - Shared Tasks
    
        /// The full details of a given task, regardless of the caller's role.
        ///
        /// - Parameter id: The task's ID.
    static func taskDetailsPath(id: String) -> String {
        return taskRoute + "/tasks/\(id)"
    }
        /// All tasks, unfiltered by role.
    static let allTasksPath = taskRoute + "/tasks"
        /// Tasks within a bounding box, for map display.
    static let mapTasksPath = taskRoute + "/tasks/map"
    
        // MARK: - Requester
    
        /// Tasks the current user has published as a requester.
    static let requesterPublishedTasksPath = taskRoute + "/req/published"
        /// Tasks the current user has completed as a requester.
    static let requesterCompletedTasksPath = taskRoute + "/req/completed"
        /// Completed requester tasks still awaiting a rating from the current user.
    static let requesterUnratedTasksPath = taskRoute + "/req/unrated"
        /// Creates a new task as a requester.
    static let requesterCreateTaskPath = taskRoute + "/req/create"
    
        /// Deletes a requester's task.
        ///
        /// - Parameter id: The task's ID.
    static func requesterDeleteTaskPath(id: String) -> String {
        return taskRoute + "/req/delete/\(id)"
    }
    
        /// Cancels a requester's task.
        ///
        /// - Parameter id: The task's ID.
    static func requesterCancelTaskPath(id: String) -> String {
        return taskRoute + "/req/\(id)/cancel"
    }
    
        /// Publishes a draft task, making it visible to executors.
        ///
        /// - Parameter id: The task's ID.
    static func requesterPublishTaskPath(id: String) -> String {
        return taskRoute + "/req/\(id)/publish"
    }
    
        /// Confirms completion of a task from the requester's side.
        ///
        /// - Parameter id: The task's ID.
    static func requesterConfirmTaskPath(id: String) -> String {
        return taskRoute + "/req/\(id)/confirm"
    }
    
        /// The list of executors who have applied to a task.
        ///
        /// - Parameter id: The task's ID.
    static func requesterApplicantsPath(id: String) -> String {
        return taskRoute + "/req/\(id)/applicants"
    }
    
        /// Assigns a task to one of its applicants.
        ///
        /// - Parameter id: The task's ID.
    static func requesterAssignTaskPath(id: String) -> String {
        return taskRoute + "/req/\(id)/assign"
    }
    
        /// Declines a specific applicant on a task.
        ///
        /// - Parameters:
        ///   - taskId: The task's ID.
        ///   - applicantId: The ID of the applicant to decline.
    static func requesterDeclineApplicantPath(
        taskId: String,
        applicantId: String
    ) -> String {
        return taskRoute + "/req/\(taskId)/decline/\(applicantId)"
    }
    
        /// Submits the requester's rating of the executor for a completed task.
        ///
        /// - Parameter id: The task's ID.
    static func requesterRateExecutorPath(id: String) -> String {
        return taskRoute + "/req/\(id)/rate"
    }
    
        // MARK: - Executor
    
        /// Tasks currently open for the current user to apply to as an executor.
    static let executorAvailableTasksPath = taskRoute + "/exe/available"
        /// Tasks currently assigned to the current user as an executor.
    static let executorAssignedTasksPath = taskRoute + "/exe/assigned"
        /// Tasks the current user has completed as an executor.
    static let executorCompletedTasksPath = taskRoute + "/exe/completed"
        /// Completed executor tasks still awaiting a rating from the current user.
    static let executorUnratedTasksPath = taskRoute + "/exe/unrated"
    
        /// Applies to an available task as an executor.
        ///
        /// - Parameter id: The task's ID.
    static func executorApplyTaskPath(id: String) -> String {
        return taskRoute + "/exe/\(id)/apply"
    }
    
        /// Withdraws from an assigned task as an executor.
        ///
        /// - Parameter id: The task's ID.
    static func executorWithdrawTaskPath(id: String) -> String {
        return taskRoute + "/exe/\(id)/withdraw"
    }
    
        /// Marks an assigned task as done from the executor's side.
        ///
        /// - Parameter id: The task's ID.
    static func executorMarkDonePath(id: String) -> String {
        return taskRoute + "/exe/\(id)/done"
    }
    
        /// Toggles a task as a favorite for the current executor.
        ///
        /// - Parameter id: The task's ID.
    static func executorFavoriteTaskPath(id: String) -> String {
        return taskRoute + "/exe/\(id)/favorite"
    }
    
        /// Submits the executor's rating of the requester for a completed task.
        ///
        /// - Parameter id: The task's ID.
    static func executorRateRequesterPath(id: String) -> String {
        return taskRoute + "/exe/\(id)/rate"
    }
    
        // MARK: - Admin
    
        // MARK: - Lookups
    
        /// All lookup data, across every type.
    static let lookupPath = lookupRoute + "/lookups"
    
        /// Lookup data for a single type (e.g. task categories).
        ///
        /// - Parameter type: The lookup type's identifier.
    static func lookupTypePath(type: String) -> String {
        return lookupRoute + "/lookups/\(type)"
    }
    
        // MARK: - Payments
    
        /// Prefix for all payment endpoints.
    static let payRoute = "/pay"
    
        /// Initiates a payment for a given task.
        ///
        /// - Parameter id: The task's ID.
    static func payInitiatePath(id: String) -> String {
        return payRoute + "/\(id)/initiate"
    }
}
