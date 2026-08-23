import Foundation

/// A snapshot of a task's position within a list, captured before an optimistic
/// mutation so the change can be rolled back if the backing request fails.
typealias TaskListSnapshot = (index: Int, task: TaskModel)

/// Shared optimistic-update helpers for task lists.
///
/// Both `RequesterViewModel` and `ExecutorViewModel` perform the same
/// "mutate locally, roll back on failure" dance against their task arrays.
/// These helpers centralize that logic so the two view models don't each
/// reimplement (and independently drift on) the index/rollback bookkeeping.
extension Array where Element == TaskModel {

    /// Removes the task with the given id, returning a snapshot for rollback.
    mutating func removeTask(id: String) -> TaskListSnapshot? {
        guard let index = firstIndex(where: { $0.id == id }) else { return nil }
        return (index, remove(at: index))
    }

    /// Applies `update` to the task with the given id, returning a snapshot of
    /// its previous value for rollback.
    mutating func updateTask(id: String, _ update: (inout TaskModel) -> Void) -> TaskListSnapshot? {
        guard let index = firstIndex(where: { $0.id == id }) else { return nil }
        let previous = self[index]
        update(&self[index])
        return (index, previous)
    }

    /// Re-inserts a previously removed task at its original position (clamped
    /// to the current bounds).
    mutating func rollbackRemoval(_ snapshot: TaskListSnapshot?) {
        guard let snapshot else { return }
        insert(snapshot.task, at: Swift.min(snapshot.index, count))
    }

    /// Restores a task to its pre-update value, re-inserting it if it has since
    /// been removed from the list.
    mutating func rollbackUpdate(_ snapshot: TaskListSnapshot?) {
        guard let snapshot else { return }
        if let currentIndex = firstIndex(where: { $0.id == snapshot.task.id }) {
            self[currentIndex] = snapshot.task
        } else {
            insert(snapshot.task, at: Swift.min(snapshot.index, count))
        }
    }
}
