import Foundation

enum TaskService: String, Codable, CaseIterable {
    case accounting
    case airportTransfer
    case carRental
    case catering
    case chauffeur
    case childcare
    case cleaning
    case dataEntry
    case delivery
    case documentation
    case elderCare
    case electrical
    case errands
    case eventPlanning
    case foodDelivery
    case gardening
    case giftSourcing
    case governmentServices
    case groceryDelivery
    case homeRepair
    case itSupport
    case legalAssistance
    case marketing
    case medicalAppointment
    case mentalHealth
    case moving
    case packagePickup
    case personalHelp
    case pestControl
    case petCare
    case pharmacy
    case photography
    case plumbing
    case printing
    case queue
    case returnItems
    case shopping
    case translation
    case travel
    case tutoring
    
    var localizedLabel: String {
        if AppLanguage.current == "ar" {
            switch self {
                case .accounting: return "محاسبة"
                case .airportTransfer: return "توصيل من/إلى المطار"
                case .carRental: return "تأجير سيارات"
                case .catering: return "تموين طعام"
                case .chauffeur: return "سائق خاص"
                case .childcare: return "رعاية أطفال"
                case .cleaning: return "تنظيف"
                case .dataEntry: return "إدخال بيانات"
                case .delivery: return "توصيل"
                case .documentation: return "توثيق مستندات"
                case .elderCare: return "رعاية كبار السن"
                case .electrical: return "أعمال كهرباء"
                case .errands: return "مشاوير"
                case .eventPlanning: return "تنظيم مناسبات"
                case .foodDelivery: return "توصيل طعام"
                case .gardening: return "بستنة"
                case .giftSourcing: return "تأمين هدايا"
                case .governmentServices: return "خدمات حكومية"
                case .groceryDelivery: return "توصيل بقالة"
                case .homeRepair: return "صيانة منزلية"
                case .itSupport: return "دعم تقني"
                case .legalAssistance: return "مساعدة قانونية"
                case .marketing: return "تسويق"
                case .medicalAppointment: return "موعد طبي"
                case .mentalHealth: return "صحة نفسية"
                case .moving: return "نقل عفش"
                case .packagePickup: return "استلام طرد"
                case .personalHelp: return "مساعدة شخصية"
                case .pestControl: return "مكافحة حشرات"
                case .petCare: return "رعاية حيوانات أليفة"
                case .pharmacy: return "صيدلية"
                case .photography: return "تصوير"
                case .plumbing: return "سباكة"
                case .printing: return "طباعة"
                case .queue: return "وقوف في طابور"
                case .returnItems: return "إرجاع مشتريات"
                case .shopping: return "تسوق"
                case .translation: return "ترجمة"
                case .travel: return "سفر"
                case .tutoring: return "دروس خصوصية"
            }
        } else {
            switch self {
                case .airportTransfer: return "Airport Transfer"
                case .carRental: return "Car Rental"
                case .dataEntry: return "Data Entry"
                case .elderCare: return "Elder Care"
                case .eventPlanning: return "Event Planning"
                case .foodDelivery: return "Food Delivery"
                case .giftSourcing: return "Gift Sourcing"
                case .governmentServices: return "Government Services"
                case .groceryDelivery: return "Grocery Delivery"
                case .homeRepair: return "Home Repair"
                case .itSupport: return "IT Support"
                case .legalAssistance: return "Legal Assistance"
                case .medicalAppointment: return "Medical Appointment"
                case .mentalHealth: return "Mental Health"
                case .packagePickup: return "Package Pickup"
                case .personalHelp: return "Personal Help"
                case .pestControl: return "Pest Control"
                case .petCare: return "Pet Care"
                case .returnItems: return "Return Items"
                default: return self.rawValue.capitalized
            }
        }
    }
    
    var icon: String {
        switch self {
            case .accounting: return "dollarsign.circle"
            case .airportTransfer: return "airplane"
            case .carRental: return "car"
            case .catering: return "frying.pan"
            case .chauffeur: return "steeringwheel"
            case .childcare: return "figure.and.child.holdinghands"
            case .cleaning: return "bubbles.and.sparkles"
            case .dataEntry: return "keyboard"
            case .delivery: return "box.truck"
            case .documentation: return "doc.text"
            case .elderCare: return "figure.roll"
            case .electrical: return "bolt"
            case .errands: return "checklist"
            case .eventPlanning: return "calendar.badge.plus"
            case .foodDelivery: return "fork.knife"
            case .gardening: return "leaf"
            case .giftSourcing: return "gift"
            case .governmentServices: return "seal"
            case .groceryDelivery: return "cart"
            case .homeRepair: return "hammer"
            case .itSupport: return "desktopcomputer"
            case .legalAssistance: return "building.columns"
            case .marketing: return "megaphone"
            case .medicalAppointment: return "cross.case"
            case .mentalHealth: return "brain.head.profile"
            case .moving: return "house.and.flag"
            case .packagePickup: return "shippingbox"
            case .personalHelp: return "hand.raised"
            case .pestControl: return "ant"
            case .petCare: return "pawprint"
            case .pharmacy: return "pills"
            case .photography: return "camera"
            case .plumbing: return "wrench.and.screwdriver"
            case .printing: return "printer"
            case .queue: return "person.3"
            case .returnItems: return "arrow.uturn.left.circle"
            case .shopping: return "bag"
            case .translation: return "globe"
            case .travel: return "suitcase"
            case .tutoring: return "book"
        }
    }
}
