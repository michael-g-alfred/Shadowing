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
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .frame(width: 24)
            
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(title)
                        .foregroundStyle(.secondary.opacity(0.6))
                }
                
                Group {
                    if isSecure {
                        SecureField("", text: $text)
                    } else {
                        TextField("", text: $text)
                    }
                }
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            }
        }
        .padding()
        .appGlassCapsule()
        .animation(isFocused ? .spring(duration: 0.3, bounce: 0.45) : .none, value: isFocused)
        .onChange(of: text) { _, newValue in
            guard let textFilter else { return }
            let filtered = textFilter(newValue)
            if filtered != text {
                text = filtered
            }
        }
        .environment(\.layoutDirection, container.languageManager.currentLanguage.layoutDirection)
    }
}
