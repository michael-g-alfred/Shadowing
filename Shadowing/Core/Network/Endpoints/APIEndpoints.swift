import Foundation

enum APIEndpoints {
    
        // MARK: - Base URL
    static let baseURL = "http://localhost:9000/mg/shadowing"
    
        // MARK: - Routes
    static let authRoute = "/auth"
    static let userRoute = "/users"
    static let taskRoute = ""
    static let lookupRoute = ""
    
        // MARK: - Public
    static let healthCheckPath = "/health-check"
    
        // MARK: - Auth
    static let signupPath = authRoute + "/signup"
    static let signinPath = authRoute + "/signin"
    static let signoutPath = authRoute + "/signout"
    static let refreshPath = authRoute + "/refresh"
    
        // MARK: - Users
    static let userCountPath = userRoute + "/count"
    static func userPath(id: String) -> String {
        return userRoute + "/\(id)"
    }
    static func userRatingsPath(id: String) -> String {
        return userRoute + "/\(id)/ratings"
    }
    static func userAvatarPath(id: String) -> String {
        return userRoute + "/\(id)/avatar"
    }
    
        // MARK: - Shared Tasks
    static func taskDetailsPath(id: String) -> String {
        return taskRoute + "/tasks/\(id)"
    }
    static let allTasksPath = taskRoute + "/tasks"
    static let mapTasksPath = taskRoute + "/tasks/map"
    
        // MARK: - Requester
    static let requesterPublishedTasksPath = taskRoute + "/req/published"
    static let requesterCompletedTasksPath = taskRoute + "/req/completed"
    static let requesterCreateTaskPath = taskRoute + "/req/create"
    static func requesterDeleteTaskPath(id: String) -> String {
        return taskRoute + "/req/delete/\(id)"
    }
    static func requesterCancelTaskPath(id: String) -> String {
        return taskRoute + "/req/\(id)/cancel"
    }
    static func requesterPublishTaskPath(id: String) -> String {
        return taskRoute + "/req/\(id)/publish"
    }
    static func requesterConfirmTaskPath(id: String) -> String {
        return taskRoute + "/req/\(id)/confirm"
    }
    static func requesterApplicantsPath(id: String) -> String {
        return taskRoute + "/req/\(id)/applicants"
    }
    static func requesterAssignTaskPath(id: String) -> String {
        return taskRoute + "/req/\(id)/assign"
    }
    static func requesterDeclineApplicantPath(
        taskId: String,
        applicantId: String
    ) -> String {
        return taskRoute + "/req/\(taskId)/decline/\(applicantId)"
    }
    static func requesterRateExecutorPath(id: String) -> String {
        return taskRoute + "/req/\(id)/rate"
    }
    
        // MARK: - Executor
    static let executorAvailableTasksPath = taskRoute + "/exe/available"
    static let executorAssignedTasksPath = taskRoute + "/exe/assigned"
    static let executorCompletedTasksPath = taskRoute + "/exe/completed"
    static func executorApplyTaskPath(id: String) -> String {
        return taskRoute + "/exe/\(id)/apply"
    }
    static func executorWithdrawTaskPath(id: String) -> String {
        return taskRoute + "/exe/\(id)/withdraw"
    }
    static func executorMarkDonePath(id: String) -> String {
        return taskRoute + "/exe/\(id)/done"
    }
    static func executorRateRequesterPath(id: String) -> String {
        return taskRoute + "/exe/\(id)/rate"
    }
    
        // MARK: - Admin
    
        // MARK: - Lookups
    static let lookupPath = lookupRoute + "/lookups"
    static func lookupTypePath(type: String) -> String {
        return lookupRoute + "/lookups/\(type)"
    }
        // MARK: - Payments
    static let payRoute = "/pay"
    static func payInitiatePath(id: String) -> String {
        return payRoute + "/\(id)/initiate"
    }
}
