import Foundation

enum EscrowStatus: String, Codable {
    case notPaid = "not_paid"
    case held
    case released
    case refunded
    
    var localizedLabel: String {
        if AppLanguage.current == "ar" {
            switch self {
                case .notPaid: return "غير مدفوع"
                case .held: return "محتجز"
                case .released: return "تم الإفراج عنه"
                case .refunded: return "مسترد"
            }
        } else {
            switch self {
                case .notPaid: return "Not Paid"
                default: return self.rawValue.capitalized
            }
        }
    }
}
