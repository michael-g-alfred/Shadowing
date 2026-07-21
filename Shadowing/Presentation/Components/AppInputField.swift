import SwiftUI

struct AppInputField: View {
    
        // MARK: - Environment
    @Environment(DIContainer.self) private var container
    @Environment(\.colorScheme) private var colorScheme
    
        // MARK: - Properties
    private var backgroundColor: Color? {
        colorScheme == .dark
        ? .accentColor.opacity(0.15)
        : .gray.opacity(0.15)
    }

    // MARK: Config
    let icon: String
    let title: LocalizedStringResource
    @Binding var text: String
    var iconColor: Color = .accentColor
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var isFocused: Bool = false

    var textFilter: ((String) -> String)? = nil
    

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .frame(width: 30)
            
            Group {
                if isSecure {
                    SecureField(title, text: $text)
                } else {
                    TextField(title, text: $text)
                }
            }
            .keyboardType(keyboardType)
            .textContentType(textContentType)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
        }
        .padding()
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(.separator, lineWidth: 1)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(.blue, lineWidth: 3)
                .scaleEffect(isFocused ? 1 : 0.8)
                .opacity(isFocused ? 1 : 0)
        }
        .animation(isFocused ? .spring(duration: 0.3, bounce: 0.45) : .none, value: isFocused)
        .onChange(of: text) { _, newValue in
            guard let textFilter else { return }
            let filtered = textFilter(newValue)
            if filtered != text {
                text = filtered
            }
        }
    }
}
