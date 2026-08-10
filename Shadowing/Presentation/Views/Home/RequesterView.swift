import SwiftUI
import CoreLocation

// MARK: - Container

struct RequesterView: View {

    // MARK: Environment
    @Environment(DIContainer.self) private var container

    // MARK: State
    @State private var vm: RequesterViewModel

    // MARK: Init
    init(vm: RequesterViewModel) {
        _vm = State(initialValue: vm)
    }

    // MARK: Body
    var body: some View {
        VStack(spacing: Spacing.lg) {
            RequesterTabHeader(vm: vm)
            RequesterTabContent(container: container, selectedTab: vm.selectedTab)
        }
        .requireLocation(container.locationService)
        .task {
            await vm.checkPendingRatings()
        }
        .toolbar {
            RequesterToolbar(vm: vm, locationService: container.locationService)
        }
        .sheet(isPresented: $vm.showAddTaskSheet) {
            container.makeAddTaskSheet()
                .appSheetStyle(interactiveDismissDisabled: true)
        }
        .sheet(isPresented: $vm.showApplicantsSheet) {
            container.makeApplicantsSheet()
                .appSheetStyle()
        }
        .sheet(isPresented: Binding(
            get: { vm.selectedChatTaskId != nil },
            set: { if !$0 { vm.selectedChatTaskId = nil } }
        )) {
            if let taskId = vm.selectedChatTaskId {
                container.makeDirectChatDetailView(taskId: taskId)
                    .appSheetStyle()
            }
        }
    }
}

// MARK: - Header

private struct RequesterTabHeader: View {
    let vm: RequesterViewModel

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Picker(
                "Tasks",
                selection: Binding(
                    get: { vm.selectedTab },
                    set: { vm.select($0) }
                )
            ) {
                ForEach(RequesterTab.allCases, id: \.self) { tab in
                    Text(tab.tabName)
                        .tag(tab)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.horizontal)
        .padding(.top, Spacing.sm)
    }
}

// MARK: - Content

private struct RequesterTabContent: View {
    let container: DIContainer
    let selectedTab: RequesterTab

    var body: some View {
        Group {
            switch selectedTab {
                case .publishedTasks:
                    container.makeRequesterPublishedTasksView()
                case .completedTasks:
                    container.makeRequesterCompletedTasksView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Toolbar

private struct RequesterToolbar: ToolbarContent {
    let vm: RequesterViewModel
    let locationService: LocationService

    private var isLocationAuthorized: Bool {
        locationService.authorizationStatus == .authorizedAlways
        || locationService.authorizationStatus == .authorizedWhenInUse
    }

    var body: some ToolbarContent {
        if isLocationAuthorized {
            ToolbarItem(placement: .topBarLeading) {
                Button("Show Add Task Sheet", systemImage: "plus") {
                    vm.showAddTaskSheet.toggle()
                }
            }
        }

        ToolbarSpacer(placement: .topBarLeading)

        ToolbarItem(placement: .topBarLeading) {
            if isLocationAuthorized
                && vm.selectedTab == .publishedTasks
                && !vm.requesterPublishedTasks.isEmpty
                && vm.errorMessage == nil {
                RequesterStatusFilterMenu(vm: vm)
            }
        }
    }
}

private struct RequesterStatusFilterMenu: View {
    let vm: RequesterViewModel

    var body: some View {
        Menu {
            ForEach(RequesterStatusFilter.allCases) { filter in
                Button {
                    vm.setStatusFilter(filter)
                } label: {
                    Label(
                        filter.title,
                        systemImage: vm.statusFilter == filter ? "checkmark.circle.fill" : "circle"
                    )
                }
            }
        } label: {
            Image(
                systemName: vm.statusFilter == .all
                ? "line.3.horizontal.decrease"
                : "line.3.horizontal.decrease.circle.fill"
            )
        }
    }
}
