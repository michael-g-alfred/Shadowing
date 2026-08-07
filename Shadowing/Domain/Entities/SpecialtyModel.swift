import Foundation

struct SpecialtyModel: Codable, Identifiable, Equatable, Hashable {
    let id: Int
    let name: String
    let labelAr: String
    let labelEn: String
    let icon: String

    var label: String {
        LanguageManager.shared.currentLanguage == .arabic ? labelAr : labelEn
    }
}
