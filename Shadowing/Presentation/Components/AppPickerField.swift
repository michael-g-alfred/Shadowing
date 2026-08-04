import SwiftUI

struct AppPickerField<T: Hashable>: View {
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var backgroundColor: Color {
        colorScheme == .dark
        ? .accentColor.opacity(0.15)
        : .gray.opacity(0.15)
    }
    
    let icon: String
    let placeholder: LocalizedStringResource
    @Binding var selection: T?
    let options: [T]
    let labelProvider: (T) -> String
    var iconColor: Color = .accentColor
    var isFocused: Bool = false
    
    var body: some View {
        Menu {
            Picker("", selection: $selection) {
                Text(placeholder).tag(T?.none)
                ForEach(options, id: \.self) { option in
                    Text(labelProvider(option)).tag(Optional(option))
                }
            }
        } label: {
            HStack(spacing: 0) {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                    .frame(width: 30, alignment: .leading)
                
                Text(selection != nil ? labelProvider(selection!) : String(localized: placeholder))
                    .foregroundStyle(selection == nil ? .secondary : .primary)
                
                Spacer()
                
                Image(systemName: "chevron.up.chevron.down")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding()
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .strokeBorder(.separator, lineWidth: 1)
        }
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .strokeBorder(.blue, lineWidth: 3)
                .scaleEffect(isFocused ? 1 : 0.8)
                .opacity(isFocused ? 1 : 0)
        }
        .animation(isFocused ? .spring(response: 0.35, dampingFraction: 0.75) : .none, value: isFocused)
    }
}
