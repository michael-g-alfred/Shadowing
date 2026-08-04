import Foundation

enum Governorate: Int, Codable, CaseIterable {
    // Egypt
    case cairo = 101
    case giza = 102
    case alexandria = 103
    case qalyubia = 104
    case portSaid = 105
    case suez = 106
    case dakahlia = 107
    case sharqia = 108
    case gharbia = 109
    case monufia = 110
    case beheira = 111
    case ismailia = 112
    case faiyum = 113
    case beniSuef = 114
    case minya = 115
    case asyut = 116
    case sohag = 117
    case qena = 118
    case luxor = 119
    case aswan = 120
    case redSea = 121
    case newValley = 122
    case matrouh = 123
    case northSinai = 124
    case southSinai = 125
    case kafrElSheikh = 126
    case damietta = 127
    
    // Saudi Arabia
    case riyadhRegion = 201
    case makkahRegion = 202
    case madinahRegion = 203
    case easternProvince = 204
    case asirRegion = 205
    case tabukRegion = 206
    case qassimRegion = 207
    case hailRegion = 208
    case northernBordersRegion = 209
    case jazanRegion = 210
    case najranRegion = 211
    case alBahahRegion = 212
    case alJoufRegion = 213
    
    // United Arab Emirates
    case abuDhabi = 301
    case dubai = 302
    case sharjah = 303
    case ajman = 304
    case ummAlQuwain = 305
    case rasAlKhaimah = 306
    case fujairah = 307
    
    var country: Country {
        switch rawValue {
            case 101...127: return .egypt
            case 201...213: return .saudiArabia
            case 301...307: return .uae
            default: return .egypt
        }
    }
    
    var localizedLabel: String {
        if LanguageManager.shared.currentLanguage == .arabic {
            switch self {
                case .cairo: return "القاهرة"
                case .giza: return "الجيزة"
                case .alexandria: return "الإسكندرية"
                case .qalyubia: return "القليوبية"
                case .portSaid: return "بورسعيد"
                case .suez: return "السويس"
                case .dakahlia: return "الدقهلية"
                case .sharqia: return "الشرقية"
                case .gharbia: return "الغربية"
                case .monufia: return "المنوفية"
                case .beheira: return "البحيرة"
                case .ismailia: return "الإسماعيلية"
                case .faiyum: return "الفيوم"
                case .beniSuef: return "بني سويف"
                case .minya: return "المنيا"
                case .asyut: return "أسيوط"
                case .sohag: return "سوهاج"
                case .qena: return "قنا"
                case .luxor: return "الأقصر"
                case .aswan: return "أسوان"
                case .redSea: return "البحر الأحمر"
                case .newValley: return "الوادي الجديد"
                case .matrouh: return "مطروح"
                case .northSinai: return "شمال سيناء"
                case .southSinai: return "جنوب سيناء"
                case .kafrElSheikh: return "كفر الشيخ"
                case .damietta: return "دمياط"
                case .riyadhRegion: return "منطقة الرياض"
                case .makkahRegion: return "منطقة مكة المكرمة"
                case .madinahRegion: return "منطقة المدينة المنورة"
                case .easternProvince: return "المنطقة الشرقية"
                case .asirRegion: return "منطقة عسير"
                case .tabukRegion: return "منطقة تبوك"
                case .qassimRegion: return "منطقة القصيم"
                case .hailRegion: return "منطقة حائل"
                case .northernBordersRegion: return "منطقة الحدود الشمالية"
                case .jazanRegion: return "منطقة جازان"
                case .najranRegion: return "منطقة نجران"
                case .alBahahRegion: return "منطقة الباحة"
                case .alJoufRegion: return "منطقة الجوف"
                case .abuDhabi: return "أبوظبي"
                case .dubai: return "دبي"
                case .sharjah: return "الشارقة"
                case .ajman: return "عجمان"
                case .ummAlQuwain: return "أم القيوين"
                case .rasAlKhaimah: return "رأس الخيمة"
                case .fujairah: return "الفجيرة"
            }
        } else {
            switch self {
                case .cairo: return "Cairo"
                case .giza: return "Giza"
                case .alexandria: return "Alexandria"
                case .qalyubia: return "Qalyubia"
                case .portSaid: return "Port Said"
                case .suez: return "Suez"
                case .dakahlia: return "Dakahlia"
                case .sharqia: return "Sharqia"
                case .gharbia: return "Gharbia"
                case .monufia: return "Monufia"
                case .beheira: return "Beheira"
                case .ismailia: return "Ismailia"
                case .faiyum: return "Faiyum"
                case .beniSuef: return "Beni Suef"
                case .minya: return "Minya"
                case .asyut: return "Asyut"
                case .sohag: return "Sohag"
                case .qena: return "Qena"
                case .luxor: return "Luxor"
                case .aswan: return "Aswan"
                case .redSea: return "Red Sea"
                case .newValley: return "New Valley"
                case .matrouh: return "Matrouh"
                case .northSinai: return "North Sinai"
                case .southSinai: return "South Sinai"
                case .kafrElSheikh: return "Kafr El Sheikh"
                case .damietta: return "Damietta"
                case .riyadhRegion: return "Riyadh Region"
                case .makkahRegion: return "Makkah Region"
                case .madinahRegion: return "Madinah Region"
                case .easternProvince: return "Eastern Province"
                case .asirRegion: return "Asir Region"
                case .tabukRegion: return "Tabuk Region"
                case .qassimRegion: return "Qassim Region"
                case .hailRegion: return "Hail Region"
                case .northernBordersRegion: return "Northern Borders Region"
                case .jazanRegion: return "Jazan Region"
                case .najranRegion: return "Najran Region"
                case .alBahahRegion: return "Al Bahah Region"
                case .alJoufRegion: return "Al Jouf Region"
                case .abuDhabi: return "Abu Dhabi"
                case .dubai: return "Dubai"
                case .sharjah: return "Sharjah"
                case .ajman: return "Ajman"
                case .ummAlQuwain: return "Umm Al Quwain"
                case .rasAlKhaimah: return "Ras Al Khaimah"
                case .fujairah: return "Fujairah"
            }
        }
    }
    
    /// All governorates belonging to a given country, in declared order —
    /// what the cascading picker in SignUpView will show once a country is selected.
    static func governorates(for country: Country) -> [Governorate] {
        allCases.filter { $0.country == country }
    }
}
