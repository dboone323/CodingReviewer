//
// ProgressIndicators.swift
// CodingReviewer
//
// Reusable progress indicator components

import SwiftUI

struct CircularProgressView: View {
    let progress: Double
    let color: Color
    
    var body: some View {
        Circle()
            .stroke(color.opacity(0.3), lineWidth: 4)
            .overlay(
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            )
    }
}

struct LinearProgressView: View {
    let progress: Double
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(color.opacity(0.3))
                    .frame(height: 4)
                
                Rectangle()
                    .fill(color)
                    .frame(width: geometry.size.width * progress, height: 4)
            }
        }
        .frame(height: 4)
    }
}
