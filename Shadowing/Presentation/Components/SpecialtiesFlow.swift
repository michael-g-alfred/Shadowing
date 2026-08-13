import SwiftUI

struct SpecialtiesFlow: View {
    let specialties: [SpecialtyModel]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(specialties) { specialty in
                    SpecialtyBadge(specialty: specialty)
                }
            }
        }
    }
}
