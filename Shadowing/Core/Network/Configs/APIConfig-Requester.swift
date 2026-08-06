import Foundation
import MGNetworkingKit

extension APIConfig {
    
        // MARK: - Requester
    
    static func requesterPublishedTasks(
        cursor: String? = nil,
        limit: Int? = nil,
        status: String? = nil,
        accessToken: String
    ) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.requesterPublishedTasksPath,
            method: .get,
            queryItems: Self.queryItems([
                ("cursor", cursor),
                ("limit", limit.map(String.init)),
                ("status", status)
            ]),
            headers: Self.requestHeaders(accessToken: accessToken)
        )
    }
    
    static func requesterCompletedTasks(
        cursor: String? = nil,
        limit: Int? = nil,
        accessToken: String
    ) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.requesterCompletedTasksPath,
            method: .get,
            queryItems: Self.queryItems([
                ("cursor", cursor),
                ("limit", limit.map(String.init))
            ]),
            headers: Self.requestHeaders(accessToken: accessToken)
        )
    }
    
    static func requesterUnratedTasks(
        cursor: String? = nil,
        limit: Int? = nil,
        accessToken: String
    ) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.requesterUnratedTasksPath,
            method: .get,
            queryItems: Self.queryItems([
                ("cursor", cursor),
                ("limit", limit.map(String.init))
            ]),
            headers: Self.requestHeaders(accessToken: accessToken)
        )
    }
    
    struct RequesterCreateTaskBody: Codable, Sendable {
        let title: String
        let description: String
        let budget: Double
        // Was `serviceType: String` (a task_services.name string) — the
        // backend column is now tasks.service_type_id, an FK to
        // task_services.id, so this sends the numeric id from the picker.
        let serviceTypeId: Int
        let address: String
        
        // Was `currency: String? = "EGP"` — hardcoded string the backend no
        // longer accepts (tasks.currency_id is a numeric FK now). Defaults
        // to 1 (EGP) to match the DB column default / task.schema.js default.
        var currencyId: Int? = 1
        var priorityId: Int? = nil
        var latitude: Double?
        var longitude: Double?
        var scheduledAt: Date?
        var preferredTimeOfDayId: Int?
    }
    
    static func requesterCreateTask(
        _ body: RequesterCreateTaskBody,
        accessToken: String
    ) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.requesterCreateTaskPath,
            method: .post,
            headers: Self.requestHeaders(accessToken: accessToken, contentType: "application/json"),
            body: body
        )
    }
    
    static func requesterDeleteTask(id: String, accessToken: String) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.requesterDeleteTaskPath(id: id),
            method: .delete,
            headers: Self.requestHeaders(accessToken: accessToken)
        )
    }
    
    static func requesterCancelTask(id: String, accessToken: String) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.requesterCancelTaskPath(id: id),
            method: .patch,
            headers: Self.requestHeaders(accessToken: accessToken)
        )
    }
    
    static func requesterPublishTask(id: String, accessToken: String) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.requesterPublishTaskPath(id: id),
            method: .patch,
            headers: Self.requestHeaders(accessToken: accessToken)
        )
    }
    
    static func requesterConfirmTask(id: String, accessToken: String) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.requesterConfirmTaskPath(id: id),
            method: .patch,
            headers: Self.requestHeaders(accessToken: accessToken)
        )
    }
    
    static func requesterApplicants(id: String, accessToken: String) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.requesterApplicantsPath(id: id),
            method: .get,
            headers: Self.requestHeaders(accessToken: accessToken)
        )
    }
    
    struct RequesterAssignTaskBody: Encodable, Sendable {
        let executorId: String
    }
    
    static func requesterAssignTask(
        id: String,
        body: RequesterAssignTaskBody,
        accessToken: String
    ) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.requesterAssignTaskPath(id: id),
            method: .patch,
            headers: Self.requestHeaders(accessToken: accessToken, contentType: "application/json"),
            body: body
        )
    }
    
    static func requesterDeclineApplicant(
        taskId: String,
        applicantId: String,
        accessToken: String
    ) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.requesterDeclineApplicantPath(taskId: taskId, applicantId: applicantId),
            method: .delete,
            headers: Self.requestHeaders(accessToken: accessToken)
        )
    }
    
    static func requesterRateExecutor(
        id: String,
        body: RatingBody,
        accessToken: String
    ) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.requesterRateExecutorPath(id: id),
            method: .post,
            headers: Self.requestHeaders(accessToken: accessToken, contentType: "application/json"),
            body: body
        )
    }
}
