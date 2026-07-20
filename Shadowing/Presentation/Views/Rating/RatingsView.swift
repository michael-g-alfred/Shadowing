import SwiftUI

struct RatingsView: View {

    // MARK: - State
    @State private var vm: RatingsViewModel
    
    // MARK: - Init
    init(vm: RatingsViewModel) {
        _vm = State(initialValue: vm)
    }
    
    // MARK: - Body
    var body: some View {
        content
            .navigationTitle("\(vm.userName)'s Ratings")
            .navigationBarTitleDisplayMode(.inline)
            .task { await vm.loadRatings() }
    }
    
    // MARK: - Private Views
    @ViewBuilder
    private var content: some View {
        if vm.isLoading {
            LoadingState.loading(
                title: "Loading",
                subtitle: "Fetching ratings."
            ).view
        } else if let errorMessage = vm.errorMessage {
            Text(errorMessage)
                .foregroundStyle(.red)
                .padding()
        } else if vm.ratings.isEmpty {
            ContentUnavailableView(
                "No Ratings Yet",
                systemImage: "star.slash",
                description: Text("This user hasn't received any ratings yet.")
            )
        } else {
            List {
                ForEach(vm.ratings) { rating in
                    ratingRow(rating)
                        .task {
                            if vm.ratings.suffix(5).contains(where: { $0.id == rating.id }) {
                                await vm.loadMoreIfNeeded(current: rating)
                            }
                        }
                }
                
                if vm.isLoadingMore {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .listRowBackground(Color.clear)
                }            }
            .listStyle(.insetGrouped)
        }
    }
    
    @ViewBuilder
    private func ratingRow(_ rating: RatingModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(rating.raterName)
                    .font(.headline)
                
                Spacer()
                
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= rating.rating ? "star.fill" : "star")
                            .font(.caption)
                            .foregroundStyle(star <= rating.rating ? .orange : .gray.opacity(0.4))
                    }
                }
            }
            
            Text(rating.comment)
                .font(.subheadline)
                .foregroundStyle(.primary)
            
            Text(rating.createdAt.toRelativeString())
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
