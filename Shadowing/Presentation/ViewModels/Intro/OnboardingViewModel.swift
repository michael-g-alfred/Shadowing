import SwiftUI
import MGOnboardingKit

@Observable
final class OnboardingViewModel {
    let items: [MGOnboardingItem] = [
        MGOnboardingItem(
            title: "Shadowing",
            description: "Stay at home\nand let us handle the task for you",
            logoSystemImage: "figure.walk", isLogoVisible: true, isDescriptionVisible: true,
            logoFrameSize: 100, logoCornerRadius: 150,
            logoGradientColors: [.indigo.opacity(0.4), .indigo.opacity(0.15)],
            logoMainColor: .indigo, logoBorderLineWidth: 0,
            titleColor: .indigo, titleDesign: .default,
            descriptionColor: .secondary, descriptionDesign: .default,
            buttonColor: .white, nextButtonIcon: "chevron.right",
            backgroundColor: [.indigo.opacity(0.25), .indigo.opacity(0.1)]
        ),
        MGOnboardingItem(
            title: "Request or Complete",
            description: "Post a task or complete one for others\nquickly and easily",
            logoSystemImage: "person.3.fill", isLogoVisible: true, isDescriptionVisible: true,
            logoFrameSize: 100, logoCornerRadius: 150,
            logoGradientColors: [.purple.opacity(0.4), .purple.opacity(0.15)],
            logoMainColor: .purple, logoBorderLineWidth: 0,
            titleColor: .purple, titleDesign: .default,
            descriptionColor: .secondary, descriptionDesign: .default,
            buttonColor: .white, nextButtonIcon: "chevron.right",
            backgroundColor: [.purple.opacity(0.25), .purple.opacity(0.1)]
        ),
        MGOnboardingItem(
            title: "Get Started",
            description: "Simple, fast, and reliable\ntask matching for everyone",
            logoSystemImage: "checkmark.seal.fill", isLogoVisible: true, isDescriptionVisible: true,
            logoFrameSize: 100, logoCornerRadius: 150,
            logoGradientColors: [.green.opacity(0.4), .green.opacity(0.15)],
            logoMainColor: .green, logoBorderLineWidth: 0,
            titleColor: .green, titleDesign: .default,
            descriptionColor: .secondary, descriptionDesign: .default,
            buttonColor: .white, nextButtonIcon: "chevron.right",
            backgroundColor: [.green.opacity(0.25), .green.opacity(0.1)]
        )
    ]
}
