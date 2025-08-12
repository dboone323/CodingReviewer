import Foundation
//
//  EnhancedProgressIndicators.swift
//  CodingReviewer
//
//  Created by Phase 3 Production Enhancement on 8/5/25.
//

import SwiftUI

// MARK: - Enhanced Progress Indicators

/// Enhanced Progress View with animation and accessibility support
struct ProgressIndicatorView: View {
    let progress: Double
    let total: Double
    let title: String
    let subtitle: String?
    let style: ProgressStyle
    
    enum ProgressStyle {
        case linear
        case circular
        case detailed
        case minimal
    }
    
    init(progress: Double, total: Double = 1.0, title: String, subtitle: String? = nil, style: ProgressStyle = .detailed) {
        self.progress = progress
        self.total = total
        self.title = title
        self.subtitle = subtitle
        self.style = style
    }
    
    var body: some View {
        switch style {
        case .linear:
            linearProgressView
        case .circular:
            circularProgressView
        case .detailed:
            detailedProgressView
        case .minimal:
            minimalProgressView
        }
    }
    
    private var linearProgressView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: progress, total: total)
                .progressViewStyle(LinearProgressViewStyle())
                .tint(.accentColor)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private var circularProgressView: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color(.separatorColor), lineWidth: 4)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: progress / total)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: progress)
                
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            
            Text(title)
                .font(.caption)
                .multilineTextAlignment(.center)
        }
    }
    
    private var detailedProgressView: some View {
        VStack(spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.accentColor)
            }
            
            ProgressView(value: progress, total: total)
                .progressViewStyle(LinearProgressViewStyle())
                .tint(.accentColor)
                .scaleEffect(x: 1, y: 1.5)
            
            if let subtitle = subtitle {
                HStack {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Estimated: \(estimatedTimeRemaining)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor).opacity(0.5))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(.separatorColor), lineWidth: 1)
        )
    }
    
    private var minimalProgressView: some View {
        HStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.8)
            Text(title)
                .font(.caption)
        }
    }
    
    private var estimatedTimeRemaining: String {
        if progress <= 0 { return "Calculating..." }
        let remainingProgress = (total - progress) / total
        let estimatedSeconds = Int(remainingProgress * 30) // Rough estimation
        
        if estimatedSeconds < 60 {
            return "\(estimatedSeconds)s"
        } else {
            let minutes = estimatedSeconds / 60
            return "\(minutes)m \(estimatedSeconds % 60)s"
        }
    }
}

// MARK: - Analysis Progress Card

struct AnalysisProgressCard: View {
    let stage: AnalysisStage
    let progress: Double
    @State private var isAnimating = false
    
    enum AnalysisStage {
        case parsing
        case analyzing
        case generating
        case finalizing
        
        var title: String {
            switch self {
            case .parsing: return "Parsing Code"
            case .analyzing: return "Running Analysis"
            case .generating: return "Generating Insights"
            case .finalizing: return "Preparing Results"
            }
        }
        
        var icon: String {
            switch self {
            case .parsing: return "doc.text.magnifyingglass"
            case .analyzing: return "brain.head.profile"
            case .generating: return "sparkles"
            case .finalizing: return "checkmark.circle"
            }
        }
        
        var color: Color {
            switch self {
            case .parsing: return .blue
            case .analyzing: return .purple
            case .generating: return .orange
            case .finalizing: return .green
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Animated icon
            Image(systemName: stage.icon)
                .font(.title2)
                .foregroundColor(stage.color)
                .scaleEffect(isAnimating ? 1.1 : 0.9)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
                .onAppear { isAnimating = true }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(stage.title)
                    .font(.headline)
                
                ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle())
                    .tint(stage.color)
                
                Text("\(Int(progress * 100))% complete")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// MARK: - Multi-Step Progress Indicator

struct MultiStepProgressIndicator: View {
    let steps: [String]
    let currentStep: Int
    let progress: Double
    
    var body: some View {
        VStack(spacing: 16) {
            // Step indicators
            HStack {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack {
                        Circle()
                            .fill(stepColor(for: index))
                            .frame(width: 20, height: 20)
                            .overlay(
                                Group {
                                    if index < currentStep {
                                        Image(systemName: "checkmark")
                                            .font(.caption)
                                            .foregroundColor(.white)
                                    } else if index == currentStep {
                                        Text("\(index + 1)")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                    } else {
                                        Text("\(index + 1)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            )
                        
                        if index < steps.count - 1 {
                            Rectangle()
                                .fill(index < currentStep ? Color.accentColor : Color(.separatorColor))
                                .frame(height: 2)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            
            // Current step info
            VStack(spacing: 8) {
                Text(steps[min(currentStep, steps.count - 1)])
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle())
                    .tint(.accentColor)
            }
        }
        .padding()
    }
    
    private func stepColor(for index: Int) -> Color {
        if index < currentStep {
            return .accentColor
        } else if index == currentStep {
            return .accentColor
        } else {
            return Color(.separatorColor)
        }
    }
}

// MARK: - Smart Loading State

struct SmartLoadingView: View {
    let title: String
    let tips: [String]
    @State private var currentTipIndex = 0
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 20) {
            // Animated loading indicator
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 12, height: 12)
                        .scaleEffect(animationOffset == CGFloat(index) ? 1.5 : 1.0)
                        .animation(.easeInOut(duration: 0.6).repeatForever().delay(Double(index) * 0.2), 
                                 value: animationOffset)
                }
            }
            .onAppear {
                animationOffset = 2
            }
            
            Text(title)
                .font(.headline)
            
            // Rotating tips
            if !tips.isEmpty {
                VStack(spacing: 8) {
                    Text("💡 Pro Tip:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(tips[currentTipIndex])
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                        .transition(.opacity.combined(with: .slide))
                        .id(currentTipIndex)
                }
                .onAppear {
                    startTipRotation()
                }
            }
        }
        .padding(24)
        .frame(maxWidth: 300)
        .background(Color(.windowBackgroundColor))
        .cornerRadius(16)
        .shadow(radius: 8)
    }
    
    private func startTipRotation() {
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            Task { @MainActor in
                withAnimation(.easeInOut(duration: 0.5)) {
                    currentTipIndex = (currentTipIndex + 1) % tips.count
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        ProgressIndicatorView(
            progress: 0.65,
            title: "Analyzing Code",
            subtitle: "Processing 12 of 20 files",
            style: .detailed
        )
        
        AnalysisProgressCard(stage: .analyzing, progress: 0.45)
        
        MultiStepProgressIndicator(
            steps: ["Parse Code", "Analyze Patterns", "Generate Report"],
            currentStep: 1,
            progress: 0.7
        )
        
        SmartLoadingView(
            title: "Analyzing Your Code",
            tips: [
                "Complex functions may take longer to analyze",
                "You can cancel analysis at any time",
                "Results are cached for faster future analysis"
            ]
        )
    }
    .padding()
}
