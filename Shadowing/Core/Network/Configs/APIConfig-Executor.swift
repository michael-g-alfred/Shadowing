import Foundation
import MGNetworkingKit

extension APIConfig {
    
        // MARK: - Executor
    
    static func executorAvailableTasks(
        cursor: String? = nil,
        limit: Int? = nil,
        lat: Double? = nil,
        lng: Double? = nil,
        accessToken: String
    ) -> MGRequestConfig {
        let items: [(name: String, value: String?)] = [
            ("cursor", cursor),
            ("limit", limit.map { "\($0)" }),
            ("lat", lat.map { "\($0)" }),
            ("lng", lng.map { "\($0)" })
        ]
        return MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.executorAvailableTasksPath,
            method: .get,
            queryItems: Self.queryItems(items),
            headers: ["Authorization": "Bearer \(accessToken)"]
        )
    }
    
    static func executorAssignedTasks(
        cursor: String? = nil,
        limit: Int? = nil,
        accessToken: String
    ) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.executorAssignedTasksPath,
            method: .get,
            queryItems: Self.queryItems([
                ("cursor", cursor),
                ("limit", limit.map(String.init))
            ]),
            headers: ["Authorization": "Bearer \(accessToken)"]
        )
    }
    
    static func executorCompletedTasks(
        cursor: String? = nil,
        limit: Int? = nil,
        accessToken: String
    ) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.executorCompletedTasksPath,
            method: .get,
            queryItems: Self.queryItems([
                ("cursor", cursor),
                ("limit", limit.map(String.init))
            ]),
            headers: ["Authorization": "Bearer \(accessToken)"]
        )
    }
    
    struct ExecutorApplyTaskBody: Encodable, Sendable {
        var proposedBudget: Double? = nil
    }
    
    static func executorApplyTask(
        id: String,
        body: ExecutorApplyTaskBody = .init(),
        accessToken: String
    ) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.executorApplyTaskPath(id: id),
            method: .post,
            headers: [
                "Authorization": "Bearer \(accessToken)",
                "Content-Type": "application/json"
            ],
            body: body
        )
    }
    
    static func executorWithdrawTask(id: String, accessToken: String) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.executorWithdrawTaskPath(id: id),
            method: .delete,
            headers: ["Authorization": "Bearer \(accessToken)"]
        )
    }
    
    static func executorMarkDone(id: String, accessToken: String) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.executorMarkDonePath(id: id),
            method: .patch,
            headers: ["Authorization": "Bearer \(accessToken)"]
        )
    }
    
    static func executorRateRequester(
        id: String,
        body: RatingBody,
        accessToken: String
    ) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.executorRateRequesterPath(id: id),
            method: .post,
            headers: [
                "Authorization": "Bearer \(accessToken)",
                "Content-Type": "application/json"
            ],
            body: body
        )
    }
}
