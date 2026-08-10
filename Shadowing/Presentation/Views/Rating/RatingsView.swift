import SwiftUI

// MARK: - Container

struct RatingsView: View {

    // MARK: State
    @State private var vm: RatingsViewModel

    // MARK: Init
    init(vm: RatingsViewModel) {
        _vm = State(initialValue: vm)
    }

    // MARK: Body
    var body: some View {
        RatingsContentView(state: state, vm: vm)
            .navigationTitle("\(vm.userName)'s Ratings")
            .navigationBarTitleDisplayMode(.inline)
            .task { await vm.loadRatings() }
    }

    // MARK: Private Helpers
    private var state: ViewState<[RatingModel]> {
        if vm.isLoading && vm.ratings.isEmpty { return .loading }
        if let errorMessage = vm.errorMessage { return .error(errorMessage) }
        if vm.ratings.isEmpty { return .empty }
        return .loaded(vm.ratings)
    }
}

// MARK: - Content (state routing)

private struct RatingsContentView: View {
    let state: ViewState<[RatingModel]>
    let vm: RatingsViewModel

    var body: some View {
        DataStateView(
            state: state,
            loadingState: .loading(title: "Loading", subtitle: "Fetching ratings."),
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
                RatingRow(rating: rating)
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

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .top) {
                AvatarView(profile: rating, nameLayout: .horizontal, subtitle: rating.createdAt.toRelativeString())

                Spacer()

                HStack(spacing: 3) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= rating.rating ? "star.fill" : "star")
                            .font(.footnote)
                            .foregroundStyle(star <= rating.rating ? .rating : .gray.opacity(0.3))
                    }
                }
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
