import SwiftUI

struct RatingSheet: View {
    
    @State var vm: RatingViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var commentFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text(vm.target.title)
                    .font(.title2.bold())
                    .padding(.top, 8)
                
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
    
    private var starPicker: some View {
        HStack(spacing: 12) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= vm.rating ? "star.fill" : "star")
                    .font(.system(size: 34))
                    .foregroundStyle(star <= vm.rating ? .yellow : .gray.opacity(0.4))
                    .onTapGesture {
                        withAnimation(.easeInOut) {
                            vm.selectRating(star)
                            commentFocused = false
                        }
                    }
                    .accessibilityLabel("\(star) star\(star == 1 ? "" : "s")")
            }
        }
    }
    
    private var commentField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Comment")
                .font(.subheadline.weight(.semibold))
            
            TextEditor(text: $vm.comment)
                .frame(height: 100)
                .padding(8)
                .background(.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                .focused($commentFocused)
        }
    }
}
