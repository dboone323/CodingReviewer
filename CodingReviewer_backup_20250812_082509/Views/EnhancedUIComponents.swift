import Foundation
import SwiftUI
import Combine

// MARK: - Modern UI Components for Enhanced User Experience

/// Enhanced Button with accessibility features and multiple styles
/// Enhanced Progress Indicator with multiple display styles
struct EnhancedProgressView: View {
    let progress: Double
    let title: String
    let subtitle: String?
    let style: ProgressStyle
    
    @State private var animatedProgress: Double = 0.0
    
    enum ProgressStyle {
        case minimal, detailed, circular
    }
    
    var body: some View {
        Group {
            switch style {
            case .minimal:
                VStack(spacing: 4) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
            case .detailed:
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(title)
                            .font(.headline)
                        
                        Spacer()
                        
                        Text("\(Int(animatedProgress * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                    
                    ProgressView(value: animatedProgress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                
            case .circular:
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                            .frame(width: 40, height: 40)
                        
                        Circle()
                            .trim(from: 0, to: animatedProgress)
                            .stroke(Color.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .frame(width: 40, height: 40)
                        
                        Text("\(Int(animatedProgress * 100))%")
                            .font(.caption2)
                            .fontWeight(.semibold)
                    }
                    
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .onAppear {
            // Animate progress from 0 to target value
            withAnimation(.easeInOut(duration: 2.0)) {
                animatedProgress = progress
            }
            
            // If progress is 0 (indeterminate), create pulsing animation
            if progress == 0.0 {
                Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                    Task { @MainActor in
                        withAnimation(.easeInOut(duration: 0.5)) {
                            animatedProgress = Double.random(in: 0.3...0.9)
                        }
                    }
                }
            }
        }
        .onChange(of: progress) { _, newProgress in
            withAnimation(.easeInOut(duration: 0.3)) {
                animatedProgress = newProgress
            }
        }
    }
}

/// Status Indicator with enhanced accessibility
struct AccessibleStatusIndicator: View {
    let status: StatusType
    let showLabel: Bool
    
    enum StatusType {
        case ready, analyzing, success, error, warning
        
        var color: Color {
            switch self {
            case .ready: return Color.green
            case .analyzing: return Color.blue
            case .success: return Color.green
            case .error: return Color.red
            case .warning: return Color.orange
            }
        }
        
        var icon: String {
            switch self {
            case .ready: return "checkmark.circle.fill"
            case .analyzing: return "gear.circle.fill"
            case .success: return "checkmark.circle.fill"
            case .error: return "xmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            }
        }
        
        var label: String {
            switch self {
            case .ready: return "Ready"
            case .analyzing: return "Analyzing"
            case .success: return "Success"
            case .error: return "Error"
            case .warning: return "Warning"
            }
        }
        
        var accessibilityDescription: String {
            switch self {
            case .ready: return "System is ready"
            case .analyzing: return "Analysis in progress"
            case .success: return "Operation completed successfully"
            case .error: return "Error occurred"
            case .warning: return "Warning condition"
            }
        }
    }
    
    init(_ status: StatusType, showLabel: Bool = true) {
        self.status = status
        self.showLabel = showLabel
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: status.icon)
                .foregroundColor(status.color)
                .font(.system(size: 16, weight: .medium))
                .accessibilityLabel(status.accessibilityDescription)
            
            if showLabel {
                Text(status.label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(status.label)
        .accessibilityValue(status.accessibilityDescription)
    }
}

/// Enhanced Card Component with multiple styles
struct EnhancedCard: View {
    let title: String
    let subtitle: String?
    let icon: String?
    let content: AnyView
    let style: CardStyle
    
    enum CardStyle {
        case standard, featured, warning, success
        
        var backgroundColor: Color {
            switch self {
            case .standard: return Color(NSColor.controlBackgroundColor)
            case .featured: return Color.blue.opacity(0.1)
            case .warning: return Color.orange.opacity(0.1)
            case .success: return Color.green.opacity(0.1)
            }
        }
        
        var borderColor: Color {
            switch self {
            case .standard: return Color.gray.opacity(0.3)
            case .featured: return Color.blue.opacity(0.5)
            case .warning: return Color.orange.opacity(0.5)
            case .success: return Color.green.opacity(0.5)
            }
        }
    }
    
    init<Content: View>(
        title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        style: CardStyle = .standard,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.style = style
        self.content = AnyView(content())
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(.blue)
                        .font(.title3)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            // Content
            content
        }
        .padding()
        .background(style.backgroundColor)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(style.borderColor, lineWidth: 1)
        )
    }
}

/// Enhanced Smart Loading View with contextual tips
struct EnhancedSmartLoadingView: View {
    let title: String
    let tips: [String]
    
    @State private var currentTipIndex = 0
    @State private var timer: Timer?
    
    var body: some View {
        VStack(spacing: 20) {
            // Animated loader
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(Double(Date().timeIntervalSince1970) * 180))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: Date().timeIntervalSince1970)
            }
            
            // Title and current tip
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                if !tips.isEmpty {
                    VStack(spacing: 4) {
                        Text("💡 Tip")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .fontWeight(.medium)
                        
                        Text(tips[currentTipIndex])
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .transition(.opacity.combined(with: .slide))
                    }
                }
            }
        }
        .onAppear {
            startTipRotation()
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }
    
    /// Initiates process with proper setup and monitoring
    private func startTipRotation() {
        guard tips.count > 1 else { return }
        
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            Task { @MainActor in
                withAnimation(.easeInOut(duration: 0.5)) {
                    currentTipIndex = (currentTipIndex + 1) % tips.count
                }
            }
        }
    }
}

/// Results Summary Card
struct ResultsSummaryCard: View {
    let totalIssues: Int
    let highSeverity: Int
    let mediumSeverity: Int
    let lowSeverity: Int
    
    var body: some View {
        EnhancedCard(
            title: "Analysis Summary",
            subtitle: "\(totalIssues) total issues found",
            icon: "chart.bar.fill",
            style: totalIssues > 0 ? .warning : .success
        ) {
            HStack(spacing: 20) {
                SeverityIndicator(count: highSeverity, severity: "High", color: .red)
                SeverityIndicator(count: mediumSeverity, severity: "Medium", color: .orange)
                SeverityIndicator(count: lowSeverity, severity: "Low", color: .yellow)
            }
        }
    }
}

struct SeverityIndicator: View {
    let count: Int
    let severity: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(count > 0 ? color : .secondary)
            
            Text(severity)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(count) \(severity) severity issues")
    }
}

/// Expandable Section Component
struct ExpandableSection<Content: View>: View {
    let title: String
    let icon: String?
    let isExpanded: Bool
    let onToggle: () -> Void
    let content: () -> Content
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: onToggle) {
                HStack {
                    if let icon = icon {
                        Image(systemName: icon)
                            .foregroundColor(.blue)
                    }
                    
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                content()
                    .transition(.opacity.combined(with: .slide))
            }
        }
        .background(Color(NSColor.textBackgroundColor))
        .cornerRadius(8)
        .animation(.easeInOut(duration: 0.3), value: isExpanded)
    }
}

/// Toast Notification Component
struct ToastNotification: View {
    let message: String
    let type: ToastType
    let isVisible: Bool
    let onDismiss: () -> Void
    
    enum ToastType {
        case success, error, warning, info
        
        var color: Color {
            switch self {
            case .success: return .green
            case .error: return .red
            case .warning: return .orange
            case .info: return .blue
            }
        }
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "xmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .info: return "info.circle.fill"
            }
        }
    }
    
    var body: some View {
        if isVisible {
            HStack(spacing: 12) {
                Image(systemName: type.icon)
                    .foregroundColor(.white)
                    .font(.title3)
                
                Text(message)
                    .foregroundColor(.white)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .foregroundColor(.white.opacity(0.8))
                        .font(.caption)
                }
            }
            .padding()
            .background(type.color)
            .cornerRadius(12)
            .shadow(radius: 8)
            .transition(.move(edge: .top).combined(with: .opacity))
            .onAppear {
                // Auto-dismiss after 4 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    onDismiss()
                }
            }
        }
    }
}

/// Performance Metrics Card
struct EnhancedPerformanceMetricsCard: View {
    let title: String
    let value: String
    let unit: String
    let trend: TrendDirection
    let color: Color
    
    enum TrendDirection {
        case up, down, stable
        
        var icon: String {
            switch self {
            case .up: return "arrow.up.circle.fill"
            case .down: return "arrow.down.circle.fill"
            case .stable: return "minus.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .stable: return .gray
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Image(systemName: trend.icon)
                    .foregroundColor(trend.color)
                    .font(.caption2)
            }
            
            HStack(alignment: .bottom, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

/// Modern Tab Bar Alternative
struct ModernTabBar: View {
    let tabs: [TabItem]
    @Binding var selectedTab: String
    
    struct TabItem: Identifiable, Hashable {
        let id = UUID()
        let title: String
        let icon: String
        let badge: Int?
        
        init(title: String, icon: String, badge: Int? = nil) {
            self.title = title
            self.icon = icon
            self.badge = badge
        }
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(tabs) { tab in
                    ModernTabButton(
                        tab: tab,
                        isSelected: selectedTab == tab.title,
                        action: {
                            selectedTab = tab.title
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct ModernTabButton: View {
    let tab: ModernTabBar.TabItem
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                ZStack {
                    Image(systemName: tab.icon)
                        .font(.system(size: 16, weight: .medium))
                    
                    if let badge = tab.badge, badge > 0 {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Text("\(badge)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            )
                            .offset(x: 12, y: -8)
                    }
                }
                
                Text(tab.title)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
            }
            .foregroundColor(isSelected ? .white : .secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.blue : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview("Enhanced UI Components") {
    VStack(spacing: 20) {
        Button("Primary Action") {
            AppLogger.shared.debug("Button tapped in preview")
        }
        .buttonStyle(.borderedProminent)
        
        EnhancedProgressView(
            progress: 0.7,
            title: "Processing",
            subtitle: "Analyzing your code...",
            style: .detailed
        )
        
        AccessibleStatusIndicator(.analyzing)
        
        ResultsSummaryCard(
            totalIssues: 8,
            highSeverity: 2,
            mediumSeverity: 3,
            lowSeverity: 3
        )
    }
    .padding()
    .frame(width: 400)
}
