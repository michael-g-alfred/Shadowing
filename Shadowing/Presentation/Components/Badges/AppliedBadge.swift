//
//  AppliedBadge.swift
//  Shadowing
//
//  Created by Michael George on 09/07/2026.
//


import SwiftUI

struct AppliedBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(.white)
                .frame(width: 5, height: 5)

            Text("Applied")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background { Capsule().fill(.green.opacity(0.8)) }
        .overlay { Capsule().strokeBorder(.green.opacity(1), lineWidth: 1) }
    }
}