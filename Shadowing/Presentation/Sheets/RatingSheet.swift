import SwiftUI

struct RatingSheet: View {
    
        // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    
        // MARK: - State
    @State var vm: RatingSheetViewModel
    
        // MARK: - Focus
    @FocusState private var commentFocused: Bool
    
        // MARK: - Init
    init(vm: RatingSheetViewModel) {
        _vm = State(initialValue: vm)
    }
    
        // MARK: - Body
    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.xxl) {
                VStack(spacing: 6) {
                    Text("Rate \(vm.target.personTitle)")
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                    
                    Text("for Task: \(vm.taskTitle)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .padding(.top, Spacing.lg)
                
                Text("This step is required to complete the task.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                starPicker
                
                commentField
                
                if let errorMessage = vm.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                ActionButton(title: "Submit Rating", systemImage: "checkmark", tint: .blue) {
                    commentFocused = false
                    Task { await vm.submit() }
                }
                .disabled(!vm.canSubmit)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled(true)
            .onChange(of: vm.didSubmit) { _, didSubmit in
                if didSubmit { dismiss() }
            }
        }
    }
    
        // MARK: - Private Views
    private var starPicker: some View {
        VStack(spacing: Spacing.lg) {
            HStack(spacing: Spacing.md) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= Int(vm.rating) ? "star.fill" : "star")
                        .imageScale(.large)
                        .foregroundStyle(star <= Int(vm.rating) ? .rating : .gray.opacity(0.5))
                        .animation(.easeInOut, value: vm.rating)
                        .onTapGesture {
                            withAnimation(.easeInOut) {
                                vm.selectRating(star)
                                commentFocused = false
                            }
                        }
                        .accessibilityLabel("\(star) star\(star == 1 ? "" : "s")")
                }
            }
            
            Slider(value: Binding(get: {
                Double(vm.rating)
            }, set: { v in
                vm.selectRating(Int(v))
            }), in: 1...5, step: 1)
            .tint(.rating)
            .frame(width: 250)
            .onChange(of: vm.rating) { _, _ in
                withAnimation(.easeInOut) {
                    commentFocused = false
                }
            }
        }
    }
    
    private var commentField: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Comment")
                .font(.subheadline.weight(.semibold))
            
            TextEditor(text: $vm.comment)
                .scrollContentBackground(.hidden)
                .padding(Spacing.md)
                .frame(height: 100)
                .overlay {
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .strokeBorder(.gray.opacity(0.5), lineWidth: 1)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .strokeBorder(.blue, lineWidth: 3)
                        .scaleEffect(commentFocused ? 1 : 0.8)
                        .opacity(commentFocused ? 1 : 0)
                }
                .animation(commentFocused ? .spring(duration: 0.3, bounce: 0.45) : .none, value: commentFocused)
                .focused($commentFocused)
        }
    }
}
