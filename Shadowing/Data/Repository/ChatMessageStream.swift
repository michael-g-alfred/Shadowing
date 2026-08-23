import Foundation
import Observation

    /// Lifecycle-safe wrapper around ``ChatRepository/observeMessages(taskId:currentUserId:)``.
    ///
    /// `ChatRepository`'s `AsyncStream`-based listeners only detach their
    /// underlying Firestore listener when the stream's continuation terminates
    /// — which happens when the consuming `Task` is cancelled, *not* simply
    /// when a SwiftUI view holding a reference to the stream disappears. If a
    /// view starts `for await x in stream { ... }` inside a `Task` and never
    /// explicitly cancels that `Task` on `.onDisappear`/`deinit`, the Firestore
    /// listener (and its read-quota usage) keeps running indefinitely.
    ///
    /// This class exists to make that lifecycle explicit and automatic: create
    /// one per screen (e.g. in a view's `.task { }` or a view model's `init`),
    /// and its `deinit` cancels the underlying listening `Task`, which in turn
    /// triggers `AsyncStream`'s `onTermination` and removes the Firestore
    /// listener.
@MainActor
@Observable
final class ChatMessageStream {
    
        /// The task's chat being observed.
    private let taskId: String
    
        /// The signed-in user's ID, used to flag which messages they sent.
    private let currentUserId: String
    
        /// The repository used to open the underlying Firestore listener.
    private let repository: ChatRepositoryProtocol
    
        /// The `Task` consuming the `AsyncStream`. Cancelling this is what
        /// causes `AsyncStream.onTermination` to fire and remove the listener.
        ///
        /// Marked `nonisolated(unsafe)` deliberately: `deinit` is always
        /// `nonisolated`, even on a `@MainActor` class, so it cannot touch a
        /// MainActor-isolated property directly. `Task.cancel()` itself is
        /// thread-safe, so reading/cancelling this from `deinit` is safe even
        /// though it bypasses actor isolation. All other access to this
        /// property happens on the main actor via `startListening()` /
        /// `stopListening()`.
    private nonisolated(unsafe) var listenerTask: Task<Void, Never>?
    
        /// The latest resolved messages, in chronological order.
    private(set) var messages: [ChatMessage] = []
    
        /// Creates a stream and immediately starts listening.
        ///
        /// - Parameters:
        ///   - taskId: The task whose chat to observe.
        ///   - currentUserId: The signed-in user's ID.
        ///   - repository: The chat repository to observe through.
    init(taskId: String, currentUserId: String, repository: ChatRepositoryProtocol) {
        self.taskId = taskId
        self.currentUserId = currentUserId
        self.repository = repository
        startListening()
    }
    
        /// Starts (or restarts) the underlying listener task.
    private func startListening() {
        listenerTask?.cancel()
        listenerTask = Task { [weak self, taskId, currentUserId, repository] in
            for await batch in repository.observeMessages(taskId: taskId, currentUserId: currentUserId) {
                guard !Task.isCancelled else { return }
                self?.messages = batch
            }
        }
    }
    
        /// Explicitly stops listening. Safe to call multiple times; also called
        /// automatically from `deinit`.
    func stopListening() {
        listenerTask?.cancel()
        listenerTask = nil
    }
    
    deinit {
        listenerTask?.cancel()
    }
}
