import SwiftUI

struct SettingsSheet: View {
    
        // MARK: - Environment
    @Environment(\.openURL) private var openURL
    @Environment(\.colorScheme) private var colorScheme
    
        // MARK: - Properties
    private var listRowColor: Color? {
        colorScheme == .dark
        ? Color.accentColor.opacity(0.12)
        : nil
    }
    
        // MARK: - State
    @State private var vm: SettingsViewModel
    @AppStorage("appColorScheme") private var appColorScheme: AppColorScheme = .dark
    
        // MARK: - Init
    init(vm: SettingsViewModel) {
        _vm = State(initialValue: vm)
    }
    
        // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                List {
                    locationSection
                        .listRowBackground(listRowColor)
                    
                    appearanceSection
                        .listRowBackground(listRowColor)
                    
                    languageSection
                        .listRowBackground(listRowColor)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
        // MARK: - Private Views
    private var locationSection: some View {
        Section("Location Access") {
            Label(vm.locationStatusTitle, systemImage: vm.locationStatusIcon)
                .bold()
                .foregroundStyle(vm.locationStatusTint)
            
            if vm.needsLocationSettingsRedirect {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                }
            } else if vm.needsLocationRequest {
                Button("Enable Location") {
                    vm.requestLocationAccess()
                }
            }
        }
    }
    
    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("App Appearance", selection: Binding(
                get: { vm.currentMode },
                set: { vm.setMode($0) }
            )) {
                ForEach(AppColorScheme.allCases) { option in
                    Label(option.title, systemImage: option.icon)
                        .tag(option)
                }
            }
            .pickerStyle(.menu)
        }
    }

    
    private var languageSection: some View {
        Section("Language") {
            Picker("App Language", selection: Binding(
                get: { vm.currentLanguage },
                set: { vm.setLanguage($0) }
            )) {
                ForEach(AppLanguage.allCases, id: \.self) { language in
                    Text(language.title).tag(language)
                }
            }
            .pickerStyle(.menu)
        }
    }
}
