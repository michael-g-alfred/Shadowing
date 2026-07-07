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
        return NSLocalizedString(self.rawValue, comment: "")
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
