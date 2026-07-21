import Foundation
import SwiftUI

extension DIContainer {
        /// A lightweight static instance of DIContainer configured safely for SwiftUI Previews.
    @MainActor
    static var mock: DIContainer {
        let container = DIContainer()
        
            // You can configure specific properties on the mock container here if needed.
            // e.g., setting a baseline app state for your preview canvas context:
            // container.appState = .main
        
        return container
    }
}
