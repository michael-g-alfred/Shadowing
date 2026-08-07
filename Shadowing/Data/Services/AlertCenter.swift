import Foundation
import Observation

@MainActor
@Observable
final class AlertCenter {
    static let shared = AlertCenter()
    
    var isPresented = false
    private(set) var type: AlertType = .info
    private(set) var message: String = ""
    
    private init() {}
    
    func show(type: AlertType, message: String) {
        self.type = type
        self.message = message
        self.isPresented = true
    }
    
    func show(responseType: String, message: String) {
        show(type: AlertType(responseType: responseType), message: message)
    }
    
    func showSuccess(_ message: String) {
        show(type: .success, message: message)
    }
    
    func showWarning(_ message: String) {
        show(type: .warning, message: message)
    }
    
    func showError(_ error: String) {
        show(type: .error, message: error)
    }
}
