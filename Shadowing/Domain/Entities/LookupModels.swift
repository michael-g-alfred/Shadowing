import SwiftUI

extension Locale {
    var isArabic: Bool {
        LanguageManager.shared.currentLanguage == .arabic
    }
    var isFrench: Bool {
        LanguageManager.shared.currentLanguage == .french
    }
}

private func pickLabel(locale: Locale, ar: String, en: String, fr: String) -> String {
    if locale.isArabic { return ar }
    if locale.isFrench { return fr }
    return en
}

    // MARK: - 1. Role Lookup
struct RoleLookupDTO: Codable {
    let id: Int?
    let name: String?
    let labelAr: String?
    let labelEn: String?
    let labelFr: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case labelAr = "label_ar"
        case labelEn = "label_en"
        case labelFr = "label_fr"
    }
}

struct RoleLookup: Identifiable, Hashable {
    let id: Int
    let name: String
    let label: String
}

extension RoleLookupDTO {
    func toDomain(locale: Locale) -> RoleLookup {
        let en = labelEn ?? labelAr ?? labelFr ?? ""
        let ar = labelAr ?? en
        let fr = labelFr ?? en
        return RoleLookup(
            id: id ?? 0,
            name: name ?? "",
            label: pickLabel(locale: locale, ar: ar, en: en, fr: fr)
        )
    }
}

    // MARK: - 2. Account Status Lookup
struct AccountStatusLookupDTO: Codable {
    let id: Int?
    let name: String?
    let labelAr: String?
    let labelEn: String?
    let labelFr: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case labelAr = "label_ar"
        case labelEn = "label_en"
        case labelFr = "label_fr"
    }
}

struct AccountStatusLookup: Identifiable, Hashable {
    let id: Int
    let name: String
    let label: String
    
    var color: Color {
        switch name {
            case "active": return .green
            case "suspended": return .orange
            case "deleted": return .red
            default: return .gray
        }
    }
}

extension AccountStatusLookupDTO {
    func toDomain(locale: Locale) -> AccountStatusLookup {
        let en = labelEn ?? labelAr ?? labelFr ?? ""
        let ar = labelAr ?? en
        let fr = labelFr ?? en
        return AccountStatusLookup(
            id: id ?? 0,
            name: name ?? "",
            label: pickLabel(locale: locale, ar: ar, en: en, fr: fr)
        )
    }
}

    // MARK: - 3. Country Lookup
struct CountryLookupDTO: Codable {
    let id: Int?
    let code: String?
    let labelAr: String?
    let labelEn: String?
    let labelFr: String?
    
    enum CodingKeys: String, CodingKey {
        case id, code
        case labelAr = "label_ar"
        case labelEn = "label_en"
        case labelFr = "label_fr"
    }
}

struct CountryLookup: Identifiable, Hashable {
    let id: Int
    let code: String
    let label: String
}

extension CountryLookupDTO {
    func toDomain(locale: Locale) -> CountryLookup {
        let en = labelEn ?? labelAr ?? labelFr ?? ""
        let ar = labelAr ?? en
        let fr = labelFr ?? en
        return CountryLookup(
            id: id ?? 0,
            code: code ?? "",
            label: pickLabel(locale: locale, ar: ar, en: en, fr: fr)
        )
    }
}

    // MARK: - 4. Governorate Lookup
struct GovernorateLookupDTO: Codable {
    let id: Int?
    let countryId: Int?
    let labelAr: String?
    let labelEn: String?
    let labelFr: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case countryId = "country_id"
        case labelAr = "label_ar"
        case labelEn = "label_en"
        case labelFr = "label_fr"
    }
}

struct GovernorateLookup: Identifiable, Hashable {
    let id: Int
    let countryId: Int
    let label: String
}

extension GovernorateLookupDTO {
    func toDomain(locale: Locale) -> GovernorateLookup {
        let en = labelEn ?? labelAr ?? labelFr ?? ""
        let ar = labelAr ?? en
        let fr = labelFr ?? en
        return GovernorateLookup(
            id: id ?? 0,
            countryId: countryId ?? 0,
            label: pickLabel(locale: locale, ar: ar, en: en, fr: fr)
        )
    }
}

    // MARK: - 5. Currency Lookup
struct CurrencyLookupDTO: Codable {
    let id: Int?
    let code: String?
    let labelAr: String?
    let labelEn: String?
    let labelFr: String?
    let symbol: String?
    
    enum CodingKeys: String, CodingKey {
        case id, code, symbol
        case labelAr = "label_ar"
        case labelEn = "label_en"
        case labelFr = "label_fr"
    }
}

struct CurrencyLookup: Identifiable, Hashable {
    let id: Int
    let code: String
    let label: String
    let symbol: String
}

extension CurrencyLookupDTO {
    func toDomain(locale: Locale) -> CurrencyLookup {
        let en = labelEn ?? labelAr ?? labelFr ?? ""
        let ar = labelAr ?? en
        let fr = labelFr ?? en
        return CurrencyLookup(
            id: id ?? 0,
            code: code ?? "",
            label: pickLabel(locale: locale, ar: ar, en: en, fr: fr),
            symbol: symbol ?? ""
        )
    }
}

    // MARK: - 6. Phone Lookup
struct PhoneLookupDTO: Codable {
    let id: Int?
    let countryId: Int?
    let dialCode: String?
    let flag: String?
    
    enum CodingKeys: String, CodingKey {
        case id, flag
        case countryId = "country_id"
        case dialCode = "dial_code"
    }
}

struct PhoneLookup: Identifiable, Hashable {
    let id: Int
    let countryId: Int
    let dialCode: String
    let flag: String
}

extension PhoneLookupDTO {
    func toDomain(locale: Locale) -> PhoneLookup {
        PhoneLookup(
            id: id ?? 0,
            countryId: countryId ?? 0,
            dialCode: dialCode ?? "",
            flag: flag ?? "🏳️"
        )
    }
}

    // MARK: - 7. Priority Lookup
struct PriorityLookupDTO: Codable {
    let id: Int?
    let name: String?
    let labelAr: String?
    let labelEn: String?
    let labelFr: String?
    let color: String?
    let icon: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, color, icon
        case labelAr = "label_ar"
        case labelEn = "label_en"
        case labelFr = "label_fr"
    }
}

struct PriorityLookup: Identifiable, Hashable {
    let id: Int
    let name: String
    let label: String
    let color: String
    let icon: String
}

extension PriorityLookupDTO {
    func toDomain(locale: Locale) -> PriorityLookup {
        let en = labelEn ?? labelAr ?? labelFr ?? ""
        let ar = labelAr ?? en
        let fr = labelFr ?? en
        let selectedLabel = pickLabel(locale: locale, ar: ar, en: en, fr: fr)
        
        return PriorityLookup(
            id: id ?? 0,
            name: name ?? "",
            label: selectedLabel,
            color: color ?? "#000000",
            icon: icon ?? "slash.circle"
        )
    }
}

    // MARK: - 8. Status Lookup
struct StatusLookupDTO: Codable {
    let id: Int?
    let name: String?
    let labelAr: String?
    let labelEn: String?
    let labelFr: String?
    let color: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, color
        case labelAr = "label_ar"
        case labelEn = "label_en"
        case labelFr = "label_fr"
    }
}

struct StatusLookup: Identifiable, Hashable {
    let id: Int
    let name: String
    let label: String
    let color: String
}

extension StatusLookupDTO {
    func toDomain(locale: Locale) -> StatusLookup {
        let en = labelEn ?? labelAr ?? labelFr ?? ""
        let ar = labelAr ?? en
        let fr = labelFr ?? en
        return StatusLookup(
            id: id ?? 0,
            name: name ?? "",
            label: pickLabel(locale: locale, ar: ar, en: en, fr: fr),
            color: color ?? "#000000"
        )
    }
}

    // MARK: - 9. Task Service Lookup
struct TaskServiceLookupDTO: Codable {
    let id: Int?
    let name: String?
    let labelAr: String?
    let labelEn: String?
    let labelFr: String?
    let icon: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, icon
        case labelAr = "label_ar"
        case labelEn = "label_en"
        case labelFr = "label_fr"
    }
}

struct TaskServiceLookup: Identifiable, Hashable {
    let id: Int
    let name: String
    let label: String
    let icon: String
}

extension TaskServiceLookupDTO {
    func toDomain(locale: Locale) -> TaskServiceLookup {
        let en = labelEn ?? labelAr ?? labelFr ?? ""
        let ar = labelAr ?? en
        let fr = labelFr ?? en
        return TaskServiceLookup(
            id: id ?? 0,
            name: name ?? "",
            label: pickLabel(locale: locale, ar: ar, en: en, fr: fr),
            icon: icon ?? ""
        )
    }
}

    // MARK: - 10. Time Of Day Lookup
struct TimeOfDayLookupDTO: Codable {
    let id: Int?
    let name: String?
    let labelAr: String?
    let labelEn: String?
    let labelFr: String?
    let subTitleAr: String?
    let subTitleEn: String?
    let subTitleFr: String?
    let icon: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, icon
        case labelAr = "label_ar"
        case labelEn = "label_en"
        case labelFr = "label_fr"
        case subTitleAr = "sub_title_ar"
        case subTitleEn = "sub_title_en"
        case subTitleFr = "sub_title_fr"
    }
}

struct TimeOfDayLookup: Identifiable, Hashable {
    let id: Int
    let name: String
    let label: String
    let subTitle: String
    let icon: String
}

extension TimeOfDayLookupDTO {
    func toDomain(locale: Locale) -> TimeOfDayLookup {
        let labelEnVal = labelEn ?? labelAr ?? labelFr ?? ""
        let labelArVal = labelAr ?? labelEnVal
        let labelFrVal = labelFr ?? labelEnVal
        let subEnVal = subTitleEn ?? subTitleAr ?? subTitleFr ?? ""
        let subArVal = subTitleAr ?? subEnVal
        let subFrVal = subTitleFr ?? subEnVal
        
        return TimeOfDayLookup(
            id: id ?? 0,
            name: name ?? "",
            label: pickLabel(locale: locale, ar: labelArVal, en: labelEnVal, fr: labelFrVal),
            subTitle: pickLabel(locale: locale, ar: subArVal, en: subEnVal, fr: subFrVal),
            icon: icon ?? ""
        )
    }
}

    // MARK: - 11. Escrow Status Lookup
struct EscrowStatusLookupDTO: Codable {
    let id: Int?
    let name: String?
    let labelAr: String?
    let labelEn: String?
    let labelFr: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case labelAr = "label_ar"
        case labelEn = "label_en"
        case labelFr = "label_fr"
    }
}

struct EscrowStatusLookup: Identifiable, Hashable {
    let id: Int
    let name: String
    let label: String
}

extension EscrowStatusLookupDTO {
    func toDomain(locale: Locale) -> EscrowStatusLookup {
        let en = labelEn ?? labelAr ?? labelFr ?? ""
        let ar = labelAr ?? en
        let fr = labelFr ?? en
        return EscrowStatusLookup(
            id: id ?? 0,
            name: name ?? "",
            label: pickLabel(locale: locale, ar: ar, en: en, fr: fr)
        )
    }
}

    // MARK: - All Lookups Container
struct AllLookupsDTO: Codable {
    let roles: [RoleLookupDTO]?
    let accountStatuses: [AccountStatusLookupDTO]?
    let countries: [CountryLookupDTO]?
    let governorates: [GovernorateLookupDTO]?
    let currencies: [CurrencyLookupDTO]?
    let phone: [PhoneLookupDTO]?
    let priorities: [PriorityLookupDTO]?
    let statuses: [StatusLookupDTO]?
    let services: [TaskServiceLookupDTO]?
    let timesOfDay: [TimeOfDayLookupDTO]?
    let escrowStatuses: [EscrowStatusLookupDTO]?
}

struct AllLookups {
    let roles: [RoleLookup]
    let accountStatuses: [AccountStatusLookup]
    let countries: [CountryLookup]
    let governorates: [GovernorateLookup]
    let currencies: [CurrencyLookup]
    let phone: [PhoneLookup]
    let priorities: [PriorityLookup]
    let statuses: [StatusLookup]
    let services: [TaskServiceLookup]
    let timesOfDay: [TimeOfDayLookup]
    let escrowStatuses: [EscrowStatusLookup]
}

extension AllLookupsDTO {
    func toDomain(locale: Locale = .current) -> AllLookups {
        AllLookups(
            roles: roles?.map { $0.toDomain(locale: locale) } ?? [],
            accountStatuses: accountStatuses?.map { $0.toDomain(locale: locale) } ?? [],
            countries: countries?.map { $0.toDomain(locale: locale) } ?? [],
            governorates: governorates?.map { $0.toDomain(locale: locale) } ?? [],
            currencies: currencies?.map { $0.toDomain(locale: locale) } ?? [],
            phone: phone?.map { $0.toDomain(locale: locale) } ?? [],
            priorities: priorities?.map { $0.toDomain(locale: locale) } ?? [],
            statuses: statuses?.map { $0.toDomain(locale: locale) } ?? [],
            services: services?.map { $0.toDomain(locale: locale) } ?? [],
            timesOfDay: timesOfDay?.map { $0.toDomain(locale: locale) } ?? [],
            escrowStatuses: escrowStatuses?.map { $0.toDomain(locale: locale) } ?? []
        )
    }
}

    // MARK: - Lookup Type Enum
enum LookupType: String {
    case roles
    case accountStatuses
    case countries
    case governorates
    case currencies
    case phone
    case priorities
    case statuses
    case services
    case timesOfDay
    case escrowStatuses
}
