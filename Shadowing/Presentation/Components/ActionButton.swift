import SwiftUI

struct ActionButton<S: LabelStyle>: View {
    let title:        LocalizedStringResource
    let systemImage:  String
    var labelStyle:   S
    let tint:         Color
    var role:         ButtonRole?
    var buttonSizing: ButtonSizing
    var isLoading:    Bool = false
    let action:       () -> Void
    
    var body: some View {
        Button(role: role) { action() } label: {
            Group {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Label(title, systemImage: systemImage)
                        .labelStyle(labelStyle)
                }
            }
            .font(.headline).bold()
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.glassProminent)
        .buttonSizing(buttonSizing)
        .tint(tint)
        .listRowInsets(.init())
        .listRowBackground(Color.clear)
        .padding(.horizontal)
        .keyboardShortcut(.defaultAction)
    }
}

extension ActionButton where S == TitleAndIconLabelStyle {
    init(
        title:        LocalizedStringResource,
        systemImage:  String,
        labelStyle:   S = .titleAndIcon,
        tint:         Color,
        role:         ButtonRole? = nil,
        buttonSizing: ButtonSizing = .flexible,
        isLoading:    Bool = false,
        action:       @escaping () -> Void
    ) {
        self.title        = title
        self.systemImage  = systemImage
        self.labelStyle   = labelStyle
        self.tint         = tint
        self.role         = role
        self.buttonSizing = buttonSizing
        self.isLoading    = isLoading
        self.action       = action
    }
}
