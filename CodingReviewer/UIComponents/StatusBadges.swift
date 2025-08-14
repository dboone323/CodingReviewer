import Foundation

//
// StatusBadges.swift
// CodingReviewer
//
// Reusable status badge components

import SwiftUI

struct StatusBadge: View {
    let status: String
    let color: Color

    var body: some View {
        Text(status)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(4)
    }
}

struct QualityScoreBadge: View {
    let score: Double

    var color: Color {
        if score >= 0.9 { .green }
        else if score >= 0.7 { .orange }
        else { .red }
    }

    var body: some View {
        StatusBadge(
            status: String(format: "%.1f", score),
            color: color
        )
    }
}
