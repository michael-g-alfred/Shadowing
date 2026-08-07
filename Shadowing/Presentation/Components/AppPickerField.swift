import SwiftUI

struct AppPickerField<T: Hashable>: View {
    
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
    let placeholder: LocalizedStringResource
    @Binding var selection: T?
    let options: [T]
    let labelProvider: (T) -> String
    var iconColor: Color = .accentColor
    var isFocused: Bool = false
    
    var body: some View {
        HStack(spacing: 0) {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .frame(width: 30)
            
            Picker(placeholder, selection: $selection) {
                Text(placeholder).tag(T?.none)
                ForEach(options, id: \.self) { option in
                    Text(labelProvider(option)).tag(Optional(option))
                }
            }
            .pickerStyle(.menu)
            .font(.body)
            .tint(.primary)
            .labelsHidden()
            
            Spacer()
        }
        .frame(height: 8)
        .padding()
        .appGlassCapsule()
        .animation(isFocused ? .spring(response: 0.35, dampingFraction: 0.75) : .none, value: isFocused)
    }
}
