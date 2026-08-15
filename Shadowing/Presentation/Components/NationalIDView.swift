import SwiftUI

    // MARK: - NationalIDView

struct NationalIDView: View {
    @Binding var nationalID: String
    @FocusState.Binding var focusedField: SignUpField?
    
    @State private var showInfoPopover = false
    
    private var isValid: Bool {
        nationalID.count == 14
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            
                // MARK: - Input Field & Info Icon Side-by-Side
            HStack(spacing: Spacing.xs) {
                AppInputField(
                    icon: "person.text.rectangle",
                    title: "14 digit national ID",
                    text: $nationalID,
                    keyboardType: .numberPad,
                    isFocused: focusedField == .nationalID,
                    textFilter: Self.digitsOnly
                )
                .focused($focusedField, equals: .nationalID)
                .environment(\.layoutDirection, .leftToRight)
                
                Button {
                    showInfoPopover.toggle()
                } label: {
                    Image(systemName: "info.circle")
                        .imageScale(.large)
                        .foregroundStyle(.orange)
                }
                .popover(isPresented: $showInfoPopover) {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Label("Important Notice", systemImage: "exclamationmark.triangle.fill")
                            .font(.headline)
                            .foregroundStyle(.orange)
                        
                        Text("The National ID must be valid and is provided under your responsibility. Please note that it cannot be changed later.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(Spacing.lg)
                    .frame(width: 240)
                    .presentationCompactAdaptation(.popover)
                }
            }
            
                // MARK: - Validation Message
            if !nationalID.isEmpty && !isValid {
                Text("Must be exactly 14 digits (\(nationalID.count)/14)")
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }
        }
    }
    
    private static func digitsOnly(_ value: String) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en")
        let englishDigits = value
            .map { formatter.number(from: String($0))?.stringValue ?? String($0) }
            .joined()
        let filtered = englishDigits.filter(\.isNumber)
        return filtered.count <= 14 ? filtered : String(filtered.prefix(14))
    }
}
