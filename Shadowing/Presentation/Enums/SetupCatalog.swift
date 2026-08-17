import Foundation

extension AppLanguage {
    
    var greetingTitle: String {
        switch self {
            case .arabic:
                "أهلاً بيك"
            case .english:
                "Welcome"
            case .french:
                "Bienvenue"
        }
    }
    
    var greetingMessage: String {
        switch self {
            case .arabic:
                "اختر لغتك المفضلة للمتابعة"
            case .english:
                "Choose your preferred language to continue"
            case .french:
                "Choisissez votre langue préférée pour continuer"
        }
    }
    
    var appearanceTitle: String {
        switch self {
            case .arabic:
                "اختار مظهر التطبيق"
            case .english:
                "Choose your appearance"
            case .french:
                "Choisissez l'apparence de l'application"
        }
    }
    
    var appearanceMessage: String {
        switch self {
            case .arabic:
                "اختار الوضع اللي مريحلك"
            case .english:
                "Pick the look that feels right"
            case .french:
                "Choisissez le mode qui vous convient"
        }
    }
    
    var doneTitle: String {
        switch self {
            case .arabic:
                "كل حاجة جاهزة!"
            case .english:
                "All set!"
            case .french:
                "Tout est prêt !"
        }
    }
    
    var doneMessage: String {
        switch self {
            case .arabic:
                "تقدر تغيّر اللغة والمظهر في أي وقت من الإعدادات"
            case .english:
                "You can change the language and appearance anytime from Settings"
            case .french:
                "Vous pouvez modifier la langue et l'apparence à tout moment dans les Réglages"
        }
    }
}
