import SwiftUI
import PhotosUI

// MARK: - NationalIDView

struct NationalIDView: View {
    @Binding var nationalIDCells: [String]
    @FocusState.Binding var focusedField: SignUpView.Field?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("National ID (14 Digits)")
                .font(.footnote).foregroundStyle(.secondary).fontWeight(.semibold)

            HStack(spacing: 6) {
                ForEach(0..<7, id: \.self) { otpTextField(index: $0) }
            }
            HStack(spacing: 6) {
                ForEach(7..<14, id: \.self) { otpTextField(index: $0) }
            }
        }
        .padding(.vertical, 4)
        .environment(\.layoutDirection, .leftToRight)
    }

    @ViewBuilder
    private func otpTextField(index: Int) -> some View {
        TextField("", text: Binding(
            get: { nationalIDCells[index] },
            set: { newValue in
                let formatter     = NumberFormatter()
                formatter.locale  = Locale(identifier: "en")
                let englishDigits = newValue
                    .map { formatter.number(from: String($0))?.stringValue ?? String($0) }
                    .joined()
                let filtered      = englishDigits.filter(\.isNumber)
                nationalIDCells[index] = filtered.count <= 1 ? filtered : String(filtered.suffix(1))

                if !nationalIDCells[index].isEmpty {
                    focusedField = index < 13 ? .nationalID(index + 1) : .password
                }
            }
        ))
        .frame(maxWidth: .infinity, minHeight: 45)
        .multilineTextAlignment(.center)
        .keyboardType(.numberPad)
        .font(.body.bold())
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(focusedField == .nationalID(index) ? Color.blue : Color.clear, lineWidth: 2)
        )
        .focused($focusedField, equals: .nationalID(index))
        .onKeyPress(.delete) {
            if nationalIDCells[index].isEmpty && index > 0 {
                focusedField = .nationalID(index - 1)
                nationalIDCells[index - 1] = ""
            }
            return .handled
        }
    }
}
