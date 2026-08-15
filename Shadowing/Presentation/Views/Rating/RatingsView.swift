import SwiftUI

    // MARK: - Container

struct RatingsView: View {
    
        // MARK: Environment
    @Environment(DIContainer.self) private var container
    
        // MARK: State
    @State private var vm: RatingsViewModel
    
        // MARK: Init
    init(vm: RatingsViewModel) {
        _vm = State(initialValue: vm)
    }
    
        // MARK: Body
    var body: some View {
        NavigationStack {
            RatingsContentView(state: state, vm: vm)
                .navigationTitle("\(vm.userName)'s Ratings")
                .navigationBarTitleDisplayMode(.inline)
                .task { await vm.loadRatings() }
                .navigationDestination(isPresented: isRaterPresented) {
                    if let raterId = vm.selectedRaterId {
                        container.makeUserView(userId: raterId)
                    }
                }
        }
    }
    
        // MARK: Private Helpers
    private var state: ViewState<[RatingModel]> {
        if vm.isLoading && vm.ratings.isEmpty { return .loading }
        if let errorMessage = vm.errorMessage { return .error(errorMessage) }
        if vm.ratings.isEmpty { return .empty }
        return .loaded(vm.ratings)
    }
    
    private var isRaterPresented: Binding<Bool> {
        Binding(
            get: { vm.selectedRaterId != nil },
            set: { isPresented in
                if !isPresented { vm.selectedRaterId = nil }
            }
        )
    }
}

    // MARK: - Content (state routing)

private struct RatingsContentView: View {
    let state: ViewState<[RatingModel]>
    let vm: RatingsViewModel
    
    var body: some View {
        DataStateView(
            state: state,
            loadingState: .loading(title: "Loading ratings", subtitle: "Please wait a moment..."),
            emptyState: .noRatings
        ) { ratings in
            RatingsLoadedView(ratings: ratings, vm: vm)
        }
    }
}

    // MARK: - Loaded

private struct RatingsLoadedView: View {
    let ratings: [RatingModel]
    let vm: RatingsViewModel
    
    var body: some View {
        List {
            ForEach(ratings) { rating in
                RatingRow(rating: rating, vm: vm)
                    .task {
                        if ratings.suffix(5).contains(where: { $0.id == rating.id }) {
                            await vm.loadMoreIfNeeded(current: rating)
                        }
                    }
            }
            
            if vm.isLoadingMore {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(.insetGrouped)
    }
}

    // MARK: - Row

private struct RatingRow: View {
    let rating: RatingModel
    let vm: RatingsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            AvatarView(profile: rating, nameLayout: .horizontal, subtitle: rating.createdAt.toRelativeString()) {
                HStack(spacing: 3) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= rating.rating ? "star.fill" : "star")
                            .font(.footnote)
                            .foregroundStyle(star <= rating.rating ? .rating : .gray.opacity(0.3))
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
//                vm.didTapRater(of: rating)
//                NOTE: I don't yet decide
            }
            
            if !rating.comment.isEmpty {
                Text(rating.comment)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
        }
        .padding(.vertical, Spacing.xs)
    }
}
