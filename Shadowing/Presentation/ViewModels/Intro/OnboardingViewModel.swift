import SwiftUI
import MGOnboardingKit

@Observable
final class OnboardingViewModel {
    let items: [MGOnboardingItem] = [
        
        // 1) التعريف بالتطبيق
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
        
        // 2) الفكرة العامة: اطلب أو نفّذ
        MGOnboardingItem(
            title: "Request or Complete",
            description: "Post a task or complete one for others\nquickly and easily",
            logoSystemImage: "person.2.fill", isLogoVisible: true, isDescriptionVisible: true,
            logoFrameSize: 100, logoCornerRadius: 150,
            logoGradientColors: [.purple.opacity(0.4), .purple.opacity(0.15)],
            logoMainColor: .purple, logoBorderLineWidth: 0,
            titleColor: .purple, titleDesign: .default,
            descriptionColor: .secondary, descriptionDesign: .default,
            buttonColor: .white, nextButtonIcon: "chevron.right",
            backgroundColor: [.purple.opacity(0.25), .purple.opacity(0.1)]
        ),
        
        // 3) إنشاء الحساب بشكل آمن
        MGOnboardingItem(
            title: "Sign Up Securely",
            description: "Create your account once\nand sign in safely every time",
            logoSystemImage: "lock.shield.fill", isLogoVisible: true, isDescriptionVisible: true,
            logoFrameSize: 100, logoCornerRadius: 150,
            logoGradientColors: [.pink.opacity(0.4), .pink.opacity(0.15)],
            logoMainColor: .pink, logoBorderLineWidth: 0,
            titleColor: .pink, titleDesign: .default,
            descriptionColor: .secondary, descriptionDesign: .default,
            buttonColor: .white, nextButtonIcon: "chevron.right",
            backgroundColor: [.pink.opacity(0.25), .pink.opacity(0.1)]
        ),
        
        // 4) توثيق الهوية
        MGOnboardingItem(
            title: "Verify Your Identity",
            description: "A quick ID check\nkeeps the whole community safe",
            logoSystemImage: "person.text.rectangle.fill", isLogoVisible: true, isDescriptionVisible: true,
            logoFrameSize: 100, logoCornerRadius: 150,
            logoGradientColors: [.gray.opacity(0.4), .gray.opacity(0.15)],
            logoMainColor: .gray, logoBorderLineWidth: 0,
            titleColor: .gray, titleDesign: .default,
            descriptionColor: .secondary, descriptionDesign: .default,
            buttonColor: .white, nextButtonIcon: "chevron.right",
            backgroundColor: [.gray.opacity(0.25), .gray.opacity(0.1)]
        ),
        
        // 5) الصورة الشخصية
        MGOnboardingItem(
            title: "Add a Profile Photo",
            description: "A friendly face builds trust\nfaster with requesters and executors",
            logoSystemImage: "camera.circle.fill", isLogoVisible: true, isDescriptionVisible: true,
            logoFrameSize: 100, logoCornerRadius: 150,
            logoGradientColors: [.indigo.opacity(0.4), .indigo.opacity(0.15)],
            logoMainColor: .indigo, logoBorderLineWidth: 0,
            titleColor: .indigo, titleDesign: .default,
            descriptionColor: .secondary, descriptionDesign: .default,
            buttonColor: .white, nextButtonIcon: "chevron.right",
            backgroundColor: [.indigo.opacity(0.25), .indigo.opacity(0.1)]
        ),
        
        // 6) صلاحية الموقع
        MGOnboardingItem(
            title: "Enable Your Location",
            description: "See tasks near you\nand let requesters find you too",
            logoSystemImage: "location.fill", isLogoVisible: true, isDescriptionVisible: true,
            logoFrameSize: 100, logoCornerRadius: 150,
            logoGradientColors: [.red.opacity(0.4), .red.opacity(0.15)],
            logoMainColor: .red, logoBorderLineWidth: 0,
            titleColor: .red, titleDesign: .default,
            descriptionColor: .secondary, descriptionDesign: .default,
            buttonColor: .white, nextButtonIcon: "chevron.right",
            backgroundColor: [.red.opacity(0.25), .red.opacity(0.1)]
        ),
        
        // 7) استعراض المهام على الخريطة والقائمة
        MGOnboardingItem(
            title: "Browse Nearby Tasks",
            description: "Explore tasks around you\non a map or a simple list",
            logoSystemImage: "map.fill", isLogoVisible: true, isDescriptionVisible: true,
            logoFrameSize: 100, logoCornerRadius: 150,
            logoGradientColors: [.mint.opacity(0.4), .mint.opacity(0.15)],
            logoMainColor: .mint, logoBorderLineWidth: 0,
            titleColor: .mint, titleDesign: .default,
            descriptionColor: .secondary, descriptionDesign: .default,
            buttonColor: .white, nextButtonIcon: "chevron.right",
            backgroundColor: [.mint.opacity(0.25), .mint.opacity(0.1)]
        ),
        
        // 8) نشر تاسك جديد
        MGOnboardingItem(
            title: "Post in Seconds",
            description: "Add your task location, price, and details in just a few taps",
            logoSystemImage: "square.and.pencil", isLogoVisible: true, isDescriptionVisible: true,
            logoFrameSize: 100, logoCornerRadius: 150,
            logoGradientColors: [.orange.opacity(0.4), .orange.opacity(0.15)],
            logoMainColor: .orange, logoBorderLineWidth: 0,
            titleColor: .orange, titleDesign: .default,
            descriptionColor: .secondary, descriptionDesign: .default,
            buttonColor: .white, nextButtonIcon: "chevron.right",
            backgroundColor: [.orange.opacity(0.25), .orange.opacity(0.1)]
        ),
        
        // 9) تفاصيل التاسك بوضوح
        MGOnboardingItem(
            title: "Clear Task Details",
            description: "Every task shows exactly\nwhat's needed, where, and for how much",
            logoSystemImage: "doc.text.magnifyingglass", isLogoVisible: true, isDescriptionVisible: true,
            logoFrameSize: 100, logoCornerRadius: 150,
            logoGradientColors: [.brown.opacity(0.4), .brown.opacity(0.15)],
            logoMainColor: .brown, logoBorderLineWidth: 0,
            titleColor: .brown, titleDesign: .default,
            descriptionColor: .secondary, descriptionDesign: .default,
            buttonColor: .white, nextButtonIcon: "chevron.right",
            backgroundColor: [.brown.opacity(0.25), .brown.opacity(0.1)]
        ),
        
        // 10) التقديم على المهام
        MGOnboardingItem(
            title: "Apply for Any Task",
            description: "Found a task you can do?\nApply with one tap and wait to get picked",
            logoSystemImage: "hand.raised.fill", isLogoVisible: true, isDescriptionVisible: true,
            logoFrameSize: 100, logoCornerRadius: 150,
            logoGradientColors: [.yellow.opacity(0.4), .yellow.opacity(0.15)],
            logoMainColor: .yellow, logoBorderLineWidth: 0,
            titleColor: .yellow, titleDesign: .default,
            descriptionColor: .secondary, descriptionDesign: .default,
            buttonColor: .white, nextButtonIcon: "chevron.right",
            backgroundColor: [.yellow.opacity(0.25), .yellow.opacity(0.1)]
        ),
        
        // 11) متابعة كل تقديماتك
        MGOnboardingItem(
            title: "Track What You Applied To",
            description: "See every task you applied for\nand its current status in one list",
            logoSystemImage: "tray.full.fill", isLogoVisible: true, isDescriptionVisible: true,
            logoFrameSize: 100, logoCornerRadius: 150,
            logoGradientColors: [.cyan.opacity(0.4), .cyan.opacity(0.15)],
            logoMainColor: .cyan, logoBorderLineWidth: 0,
            titleColor: .cyan, titleDesign: .default,
            descriptionColor: .secondary, descriptionDesign: .default,
            buttonColor: .white, nextButtonIcon: "chevron.right",
            backgroundColor: [.cyan.opacity(0.25), .cyan.opacity(0.1)]
        ),
        
        // 12) اختيار المتقدم المناسب
        MGOnboardingItem(
            title: "Choose the Right Person",
            description: "Review applicants' profiles and ratings\nthen pick who fits best",
            logoSystemImage: "person.crop.circle.badge.checkmark", isLogoVisible: true, isDescriptionVisible: true,
            logoFrameSize: 100, logoCornerRadius: 150,
            logoGradientColors: [.teal.opacity(0.4), .teal.opacity(0.15)],
            logoMainColor: .teal, logoBorderLineWidth: 0,
            titleColor: .teal, titleDesign: .default,
            descriptionColor: .secondary, descriptionDesign: .default,
            buttonColor: .white, nextButtonIcon: "chevron.right",
            backgroundColor: [.teal.opacity(0.25), .teal.opacity(0.1)]
        ),
        
        // 13) الشات المباشر
        MGOnboardingItem(
            title: "Chat in Real Time",
            description: "Message the requester or executor\ndirectly inside the task",
            logoSystemImage: "message.fill", isLogoVisible: true, isDescriptionVisible: true,
            logoFrameSize: 100, logoCornerRadius: 150,
            logoGradientColors: [.blue.opacity(0.4), .blue.opacity(0.15)],
            logoMainColor: .blue, logoBorderLineWidth: 0,
            titleColor: .blue, titleDesign: .default,
            descriptionColor: .secondary, descriptionDesign: .default,
            buttonColor: .white, nextButtonIcon: "chevron.right",
            backgroundColor: [.blue.opacity(0.25), .blue.opacity(0.1)]
        ),
        
        // 14) الإشعارات
        MGOnboardingItem(
            title: "Never Miss an Update",
            description: "Get notified the moment\nsomeone applies, messages, or accepts",
            logoSystemImage: "bell.badge.fill", isLogoVisible: true, isDescriptionVisible: true,
            logoFrameSize: 100, logoCornerRadius: 150,
            logoGradientColors: [.purple.opacity(0.4), .purple.opacity(0.15)],
            logoMainColor: .purple, logoBorderLineWidth: 0,
            titleColor: .purple, titleDesign: .default,
            descriptionColor: .secondary, descriptionDesign: .default,
            buttonColor: .white, nextButtonIcon: "chevron.right",
            backgroundColor: [.purple.opacity(0.25), .purple.opacity(0.1)]
        ),
        
        // 15) متابعة حالة التاسك
        MGOnboardingItem(
            title: "Track Every Step",
            description: "Follow your task's status\nfrom posted to completed",
            logoSystemImage: "list.bullet.clipboard.fill", isLogoVisible: true, isDescriptionVisible: true,
            logoFrameSize: 100, logoCornerRadius: 150,
            logoGradientColors: [.indigo.opacity(0.4), .indigo.opacity(0.15)],
            logoMainColor: .indigo, logoBorderLineWidth: 0,
            titleColor: .indigo, titleDesign: .default,
            descriptionColor: .secondary, descriptionDesign: .default,
            buttonColor: .white, nextButtonIcon: "chevron.right",
            backgroundColor: [.indigo.opacity(0.25), .indigo.opacity(0.1)]
        ),
        
        // 16) الدفع الآمن
        MGOnboardingItem(
            title: "Secure Payments",
            description: "Your money stays protected\nuntil the task is confirmed done",
            logoSystemImage: "creditcard.fill", isLogoVisible: true, isDescriptionVisible: true,
            logoFrameSize: 100, logoCornerRadius: 150,
            logoGradientColors: [.green.opacity(0.4), .green.opacity(0.15)],
            logoMainColor: .green, logoBorderLineWidth: 0,
            titleColor: .green, titleDesign: .default,
            descriptionColor: .secondary, descriptionDesign: .default,
            buttonColor: .white, nextButtonIcon: "chevron.right",
            backgroundColor: [.green.opacity(0.25), .green.opacity(0.1)]
        ),
        
        // 17) الانسحاب من مهمة
        MGOnboardingItem(
            title: "Fair Withdrawal Policy",
            description: "Free withdrawal within 15 minutes\nof being assigned, no penalty",
            logoSystemImage: "clock.badge.checkmark.fill", isLogoVisible: true, isDescriptionVisible: true,
            logoFrameSize: 100, logoCornerRadius: 150,
            logoGradientColors: [.orange.opacity(0.4), .orange.opacity(0.15)],
            logoMainColor: .orange, logoBorderLineWidth: 0,
            titleColor: .orange, titleDesign: .default,
            descriptionColor: .secondary, descriptionDesign: .default,
            buttonColor: .white, nextButtonIcon: "chevron.right",
            backgroundColor: [.orange.opacity(0.25), .orange.opacity(0.1)]
        ),
        
        // 18) عقوبة الانسحاب المتكرر
        MGOnboardingItem(
            title: "Keep Withdrawals Rare",
            description: "3 late withdrawals in a week\nsuspend your account for 7 days",
            logoSystemImage: "exclamationmark.triangle.fill", isLogoVisible: true, isDescriptionVisible: true,
            logoFrameSize: 100, logoCornerRadius: 150,
            logoGradientColors: [.red.opacity(0.4), .red.opacity(0.15)],
            logoMainColor: .red, logoBorderLineWidth: 0,
            titleColor: .red, titleDesign: .default,
            descriptionColor: .secondary, descriptionDesign: .default,
            buttonColor: .white, nextButtonIcon: "chevron.right",
            backgroundColor: [.red.opacity(0.25), .red.opacity(0.1)]
        ),
        
        // 19) التقييمات وبناء الثقة
        MGOnboardingItem(
            title: "Rate & Build Trust",
            description: "Rate every task you finish\nand build a trusted profile",
            logoSystemImage: "star.fill", isLogoVisible: true, isDescriptionVisible: true,
            logoFrameSize: 100, logoCornerRadius: 150,
            logoGradientColors: [.yellow.opacity(0.4), .yellow.opacity(0.15)],
            logoMainColor: .yellow, logoBorderLineWidth: 0,
            titleColor: .yellow, titleDesign: .default,
            descriptionColor: .secondary, descriptionDesign: .default,
            buttonColor: .white, nextButtonIcon: "chevron.right",
            backgroundColor: [.yellow.opacity(0.25), .yellow.opacity(0.1)]
        ),
        
        // 20) الملف الشخصي
        MGOnboardingItem(
            title: "Your Profile, Your Reputation",
            description: "Show your history, ratings,\nand completed tasks in one place",
            logoSystemImage: "person.crop.circle.fill", isLogoVisible: true, isDescriptionVisible: true,
            logoFrameSize: 100, logoCornerRadius: 150,
            logoGradientColors: [.pink.opacity(0.4), .pink.opacity(0.15)],
            logoMainColor: .pink, logoBorderLineWidth: 0,
            titleColor: .pink, titleDesign: .default,
            descriptionColor: .secondary, descriptionDesign: .default,
            buttonColor: .white, nextButtonIcon: "chevron.right",
            backgroundColor: [.pink.opacity(0.25), .pink.opacity(0.1)]
        ),
        
        // 21) دعم الأجهزة اللوحية
        MGOnboardingItem(
            title: "Works Great on iPad Too",
            description: "Enjoy an adaptive layout\nbuilt for bigger screens",
            logoSystemImage: "ipad.and.iphone", isLogoVisible: true, isDescriptionVisible: true,
            logoFrameSize: 100, logoCornerRadius: 150,
            logoGradientColors: [.gray.opacity(0.4), .gray.opacity(0.15)],
            logoMainColor: .gray, logoBorderLineWidth: 0,
            titleColor: .gray, titleDesign: .default,
            descriptionColor: .secondary, descriptionDesign: .default,
            buttonColor: .white, nextButtonIcon: "chevron.right",
            backgroundColor: [.gray.opacity(0.25), .gray.opacity(0.1)]
        ),
        
        // 22) اللغة العربية والإنجليزية
        MGOnboardingItem(
            title: "Arabic & English",
            description: "Use the app comfortably\nin the language you prefer",
            logoSystemImage: "globe", isLogoVisible: true, isDescriptionVisible: true,
            logoFrameSize: 100, logoCornerRadius: 150,
            logoGradientColors: [.mint.opacity(0.4), .mint.opacity(0.15)],
            logoMainColor: .mint, logoBorderLineWidth: 0,
            titleColor: .mint, titleDesign: .default,
            descriptionColor: .secondary, descriptionDesign: .default,
            buttonColor: .white, nextButtonIcon: "chevron.right",
            backgroundColor: [.mint.opacity(0.25), .mint.opacity(0.1)]
        ),
        
        // 23) الخاتمة والبدء
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
