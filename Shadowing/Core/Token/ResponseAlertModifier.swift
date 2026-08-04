import SwiftUI

struct ResponseAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    let type: AlertType
    let message: String
    let action: () -> Void
    
    func body(content: Content) -> some View {
        content
            .alert(type.label, isPresented: $isPresented) {
                Button("OK") {
                    action()
                }
            } message: {
                Text(message)
            }
    }
}

extension View {
    func responseAlert(
        isPresented: Binding<Bool>,
        type: AlertType = .info,
        message: String,
        action: @escaping () -> Void = {}
    ) -> some View {
        self.modifier(
            ResponseAlertModifier(
                isPresented: isPresented,
                type: type,
                message: message,
                action: action
            )
        )
    }
}

struct ResponseAlertView: View {
    @State private var showAlert = false
    @State private var selectedType: AlertType = .success
    
    var body: some View {
        VStack(spacing: 15) {
            Button("Success Alert") {
                selectedType = .success
                showAlert = true
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            
            Button("Error Alert") {
                selectedType = .error
                showAlert = true
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            
            Button("Warning Alert") {
                selectedType = .warning
                showAlert = true
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            
            Button("Info Alert") {
                selectedType = .info
                showAlert = true
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
        }
        .responseAlert(
            isPresented: $showAlert,
            type: selectedType,
            message: "This is a demonstration message for the selected alert type."
        ) {
            print("OK button tapped for \(selectedType.label)")
        }
    }
}

#Preview {
    ResponseAlertView()
}
