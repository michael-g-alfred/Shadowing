import SwiftUI

struct InfoRow<Value: View>: View {
    
    let title: LocalizedStringResource
    let systemImage: String
    var iconColor: Color = .accentColor
    @ViewBuilder let value: () -> Value
    
    var body: some View {
        LabeledContent {
            value()
        } label: {
            Label {
                Text(title)
            } icon: {
                Image(systemName: systemImage)
                    .foregroundStyle(iconColor)
            }
        }
    }
}

extension InfoRow where Value == Text {
    
        // MARK: - String
    
    init(
        title: LocalizedStringResource,
        systemImage: String,
        value: String,
        iconColor: Color = .accentColor,
        valueColor: Color = .secondary
    ) {
        self.title = title
        self.systemImage = systemImage
        self.iconColor = iconColor
        self.value = {
            Text(value)
                .foregroundStyle(valueColor)
                .bold()
        }
    }
    
        // MARK: - LocalizedStringResource
    
    init(
        title: LocalizedStringResource,
        systemImage: String,
        localizedValue: LocalizedStringResource,
        iconColor: Color = .accentColor,
        valueColor: Color = .secondary
    ) {
        self.title = title
        self.systemImage = systemImage
        self.iconColor = iconColor
        self.value = {
            Text(localizedValue)
                .foregroundStyle(valueColor)
                .bold()
        }
    }
}
