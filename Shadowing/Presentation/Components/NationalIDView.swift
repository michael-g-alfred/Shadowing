import SwiftUI

    // MARK: - NationalIDView

struct NationalIDView: View {
    @Binding var nationalID: String
    @FocusState.Binding var focusedField: SignUpView.Field?
    
    private var isValid: Bool {
        nationalID.count == 14
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
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
            
            if !nationalID.isEmpty && !isValid {
                Text("Must be exactly 14 digits (\(nationalID.count)/14)")
                    .font(.caption2)
                    .foregroundStyle(.red)
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
