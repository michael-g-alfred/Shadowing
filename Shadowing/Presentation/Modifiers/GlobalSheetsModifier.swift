import SwiftUI

    // MARK: - Pending Rating

    /// A unified representation of a rating that is currently pending presentation.
    ///
    /// The app supports two independent rating flows:
    /// - Executor rates the requester.
    /// - Requester rates the executor.
    ///
    /// `PendingRating` normalizes both flows into one value so the
    /// global sheets modifier can drive a single sheet presentation.
fileprivate struct PendingRating: Identifiable {
    
        // MARK: Source
    
    enum Source {
            /// The signed-in user is the executor and needs to rate the requester.
        case executor
        
            /// The signed-in user is the requester and needs to rate the executor.
        case requester
    }
    
        // MARK: Properties
    
        /// The task associated with this pending rating.
    let task: TaskModel
    
        /// The user being rated.
    let target: RatingTarget
    
        /// Which rating flow produced this pending rating.
    let source: Source
    
        /// A unique identifier for the pending rating.
        ///
        /// Including the source prevents two different rating flows
        /// for the same task from being treated as the same Identifiable item.
    var id: String {
        switch source {
            case .executor:
                "\(task.id)-executor"
                
            case .requester:
                "\(task.id)-requester"
        }
    }
}

    // MARK: - Global Sheets Modifier

    /// Owns every global sheet/alert presentation that belongs to the
    /// main application flow (requester + executor), so that `RootView`
    /// only has to attach a single modifier.
    ///
    /// Reads shared dependencies and ViewModels from `DIContainer`,
    /// same as `RootView` did before this was extracted.
struct GlobalSheetsModifier: ViewModifier {
    
        // MARK: Environment
    
    @Environment(DIContainer.self) private var container
    
        // MARK: Pending Rating
    
        /// The rating currently waiting to be presented.
        ///
        /// The executor flow is checked first, followed by the requester flow.
        /// If neither flow has a pending rating, this returns `nil`.
    private var pendingRating: PendingRating? {
        
            // Executor → Rate Requester
        if let task = container.executorViewModel.currentRatingTask {
            
            return PendingRating(
                task: task,
                target: .requester(
                    userId: task.requester.id,
                    displayName: task.requester.displayName
                ),
                source: .executor
            )
        }
        
            // Requester → Rate Executor
        if let task = container.requesterViewModel.currentRatingTask,
           let executor = task.executor {
            
            return PendingRating(
                task: task,
                target: .executor(
                    userId: executor.id,
                    displayName: executor.displayName
                ),
                source: .requester
            )
        }
        
        return nil
    }
    
        // MARK: Body
    
    func body(content: Content) -> some View {
        content
        
            // MARK: Rating Sheet
        
            .sheet(
                item: Binding(
                    get: {
                        pendingRating
                    },
                    set: { newValue in
                        handleRatingSheetChange(newValue)
                    }
                )
            ) { pending in
                
                container.makeRatingSheet(
                    taskId: pending.task.id,
                    taskTitle: pending.task.title,
                    target: pending.target
                )
                .appSheetStyle(
                    interactiveDismissDisabled: true
                )
            }
        
            // MARK: Executor - Applied Sheet
            //
            // Owns the whole apply flow now — budget entry, fee confirmation,
            // and submission — as internal steps of AppliedSheet itself
            // (see ExecutorViewModel.isConfirmingApply / .isApplying). There is
            // no separate "Apply Confirmation" alert anymore; it was removed
            // because closing this sheet before showing that alert meant the
            // real network call ran with no visible loading state. See
            // AppliedSheet.swift and ExecutorViewModel.swift for the fix.
        
            .sheet(
                isPresented: Binding(
                    get: {
                        container.executorViewModel.showAppliedSheet
                    },
                    set: {
                        container.executorViewModel.showAppliedSheet = $0
                    }
                )
            ) {
                AppliedSheet(
                    vm: container.executorViewModel
                )
                .appSheetStyle()
            }
        
            // MARK: Executor - Direct Chat
        
            .sheet(
                isPresented: Binding(
                    get: {
                        container.executorViewModel.selectedChatTaskId != nil
                    },
                    set: { isPresented in
                        if !isPresented {
                            container.executorViewModel.selectedChatTaskId = nil
                        }
                    }
                )
            ) {
                if let taskId = container.executorViewModel.selectedChatTaskId {
                    container.makeDirectChatDetailView(
                        taskId: taskId
                    )
                    .appSheetStyle()
                }
            }
        
            // MARK: Requester - Add Task
        
            .sheet(
                isPresented: Binding(
                    get: {
                        container.requesterViewModel.showAddTaskSheet
                    },
                    set: {
                        container.requesterViewModel.showAddTaskSheet = $0
                    }
                )
            ) {
                container.makeAddTaskSheet()
                    .appSheetStyle(
                        interactiveDismissDisabled: true
                    )
            }
        
            // MARK: Requester - Applicants
        
            .sheet(
                isPresented: Binding(
                    get: {
                        container.requesterViewModel.showApplicantsSheet
                    },
                    set: {
                        container.requesterViewModel.showApplicantsSheet = $0
                    }
                )
            ) {
                container.makeApplicantsSheet()
                    .appSheetStyle()
            }
        
            // MARK: Requester - Direct Chat
        
            .sheet(
                isPresented: Binding(
                    get: {
                        container.requesterViewModel.selectedChatTaskId != nil
                    },
                    set: { isPresented in
                        if !isPresented {
                            container.requesterViewModel.selectedChatTaskId = nil
                        }
                    }
                )
            ) {
                if let taskId = container.requesterViewModel.selectedChatTaskId {
                    container.makeDirectChatDetailView(
                        taskId: taskId
                    )
                    .appSheetStyle()
                }
            }
        
            // MARK: Requester - Payment
            //
            // Driven by `selectedTaskForPayment`, set via the `.pay` swipe
            // action (see `requesterSwipePerform` in DIContainer-TaskListView.swift)
            // — same one-shot, set-then-clear pattern as the applicants and
            // direct-chat sheets above. This is the ONLY place that presents
            // it — `DIContainer.makeRequesterPublishedTasksView()` must not
            // also attach a `.sheet` for this property, or the two would race.
        
            .sheet(
                item: Binding(
                    get: {
                        container.requesterViewModel.selectedTaskForPayment
                    },
                    set: { newValue in
                        if newValue == nil {
                            container.requesterViewModel.selectedTaskForPayment = nil
                        }
                    }
                )
            ) { task in
                container.makePaymentView(for: task)
                    .appSheetStyle()
            }
            .onChange(of: container.requesterViewModel.selectedTaskForPayment?.id) { oldTaskId, newTaskId in
                    // The payment sheet just closed. No synchronous success
                    // signal here — Paymob confirms via webhook, asynchronously
                    // — so this refresh either picks up the new status/
                    // escrowStatus if the webhook already landed, or leaves the
                    // task showing pending_payment/unpaid, with `.pay` still
                    // offered, if it hasn't yet.
                    // `paymentSheetDismissed(taskId:)` first asks the server to
                    // re-check the payment with Paymob, then reloads the list.
                if newTaskId == nil, let oldTaskId {
                    Task { await container.requesterViewModel.paymentSheetDismissed(taskId: oldTaskId) }
                }
            }
        
            // MARK: Requester - Refund Confirmation
            //
            // A refund cancels the task and returns the money, so it always asks
            // first. `requesterSwipePerform` only sets `taskPendingRefund`.
        
            .alert(
                "Refund this task?",
                isPresented: Binding(
                    get: {
                        container.requesterViewModel.taskPendingRefund != nil
                    },
                    set: { isPresented in
                        if !isPresented {
                            container.requesterViewModel.taskPendingRefund = nil
                        }
                    }
                ),
                presenting: container.requesterViewModel.taskPendingRefund
            ) { task in
                Button("Refund", role: .destructive) {
                    container.requesterViewModel.taskPendingRefund = nil
                    Task { await container.requesterViewModel.refundTask(task) }
                }
                Button("Cancel", role: .cancel) {}
            } message: { _ in
                Text("The money you paid will be returned and the task will be cancelled. The executor will be notified.")
            }
        
            // MARK: Executor - Withdraw Confirmation
            //
            // `executorSwipePerform` only sets `taskPendingWithdraw`, so every
            // entry point (swipe, details menu) goes through this alert.
        
            .alert(
                "Withdraw from this task?",
                isPresented: Binding(
                    get: {
                        container.executorViewModel.taskPendingWithdraw != nil
                    },
                    set: { isPresented in
                        if !isPresented {
                            container.executorViewModel.taskPendingWithdraw = nil
                        }
                    }
                ),
                presenting: container.executorViewModel.taskPendingWithdraw
            ) { task in
                Button("Withdraw", role: .destructive) {
                    container.executorViewModel.taskPendingWithdraw = nil
                    Task { await container.executorViewModel.withdrawFromTask(task) }
                }
                Button("Cancel", role: .cancel) {}
            } message: { task in
                Text(withdrawMessage(for: task))
            }
    }
    
        // MARK: Withdraw Message
    
        /// What the executor is agreeing to, depending on how far the task got.
    private func withdrawMessage(for task: TaskModel) -> LocalizedStringKey {
        switch task.status {
            case TaskStatus.inProgress.rawValue:
                return "The requester will be refunded and the task will be reopened. Withdrawing after work has started may count as a strike against your account."
            case TaskStatus.pendingPayment.rawValue:
                return "You'll be removed from this task. There's no penalty because the requester hasn't paid yet."
            default:
                return "Your application will be withdrawn."
        }
    }
    
        // MARK: Rating Sheet Handling
    
        /// Handles changes to the rating sheet binding.
        ///
        /// A `nil` value can be produced when the sheet is dismissed.
        /// The actual submission state should be managed by the corresponding
        /// ViewModel rather than assuming every dismissal means a successful rating.
    private func handleRatingSheetChange(
        _ newValue: PendingRating?
    ) {
        
        guard newValue == nil else {
            return
        }
        
        guard let current = pendingRating else {
            return
        }
        
        switch current.source {
                
            case .executor:
                container.executorViewModel.ratingSheetDismissed(
                    for: current.task.id,
                    wasSubmitted: true
                )
                
            case .requester:
                container.requesterViewModel.ratingSheetDismissed(
                    for: current.task.id,
                    wasSubmitted: true
                )
        }
    }
}

    // MARK: - View Extension

extension View {
    
        /// Attaches every global sheet/alert belonging to the main
        /// application flow (rating, applied, direct chat, add task,
        /// applicants, payment).
    func withGlobalSheets() -> some View {
        modifier(GlobalSheetsModifier())
    }
}
