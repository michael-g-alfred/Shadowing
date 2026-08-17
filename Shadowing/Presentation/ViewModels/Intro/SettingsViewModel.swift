import SwiftUI
import CoreLocation

@MainActor
@Observable
final class SettingsViewModel {
    
    private let locationService: LocationServiceProtocol
    private let languageManager: LanguageManager
    private let appearanceManager: AppearanceManager
    
    init(
        locationService: LocationServiceProtocol,
        languageManager: LanguageManager,
        appearanceManager: AppearanceManager
    ) {
        self.locationService = locationService
        self.languageManager = languageManager
        self.appearanceManager = appearanceManager
    }
    
        // MARK: - Location
    
    var locationAuthorizationStatus: CLAuthorizationStatus {
        locationService.authorizationStatus
    }
    
    var locationStatusTitle: String {
        switch locationAuthorizationStatus {
            case .authorizedAlways: return "Always Allowed"
            case .authorizedWhenInUse: return "Allowed While Using App"
            case .denied: return "Denied"
            case .restricted: return "Restricted"
            case .notDetermined: return "Not Determined"
            @unknown default: return "Unknown"
        }
    }
    
    var locationStatusIcon: String {
        switch locationAuthorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse: return "location.fill"
            case .denied, .restricted: return "location.slash"
            case .notDetermined: return "location"
            @unknown default: return "location"
        }
    }
    
    var locationStatusTint: Color {
        switch locationAuthorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse: return .green
            case .denied, .restricted: return .red
            case .notDetermined: return .orange
            @unknown default: return .gray
        }
    }
    
    var needsLocationSettingsRedirect: Bool {
        locationAuthorizationStatus == .denied || locationAuthorizationStatus == .restricted
    }
    
    var needsLocationRequest: Bool {
        locationAuthorizationStatus == .notDetermined
    }
    
    func requestLocationAccess() {
        locationService.requestLocation()
    }
    
        // MARK: - Language
    
    var currentLanguage: AppLanguage {
        languageManager.currentLanguage
    }
    
    private(set) var isLanguageSelectedByUser: Bool = false
    private(set) var currentGreetingIndex: Int = 0
    private var greetingTask: Task<Void, Never>?
    
    private var availableLanguages: [AppLanguage] {
        AppLanguage.allCases
    }
    
    func setLanguage(_ language: AppLanguage) {
        isLanguageSelectedByUser = true
        stopGreetingLoop()
        languageManager.setLanguage(language)
    }
    
    var currentGreeting: String {
        if isLanguageSelectedByUser {
            return currentLanguage.greetingTitle
        }
        guard availableLanguages.indices.contains(currentGreetingIndex) else { return "" }
        return availableLanguages[currentGreetingIndex].greetingTitle
    }
    
    var currentGreetingSubtitle: String {
        if isLanguageSelectedByUser {
            return currentLanguage.greetingMessage
        }
        guard availableLanguages.indices.contains(currentGreetingIndex) else { return "" }
        return availableLanguages[currentGreetingIndex].greetingMessage
    }
    
    func startGreetingLoop() {
            // لو المستخدم اختار لغة خلاص، مش هنشغّل اللوب ثاني
        guard !isLanguageSelectedByUser else { return }
        stopGreetingLoop()
        guard availableLanguages.count > 1 else { return }
        
        greetingTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1.6))
                guard !Task.isCancelled, let self else { break }
                
                withAnimation(.easeInOut) {
                    self.currentGreetingIndex = (self.currentGreetingIndex + 1) % self.availableLanguages.count
                }
            }
        }
    }
    
    func stopGreetingLoop() {
        greetingTask?.cancel()
        greetingTask = nil
    }
    
        // MARK: - Appearance / Mode
    
    var currentMode: AppColorScheme {
        appearanceManager.currentMode
    }
    
    func setMode(_ mode: AppColorScheme) {
        appearanceManager.setMode(mode)
    }
}
