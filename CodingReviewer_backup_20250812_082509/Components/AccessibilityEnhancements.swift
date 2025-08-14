import Foundation

//
//  AccessibilityEnhancements.swift
//  CodingReviewer
//
//  Created by Phase 3 Production Enhancement on 8/5/25.
//

import SwiftUI

// MARK: - Accessibility Helpers

struct AccessibleButton: View {
    let title: String
    let subtitle: String?
    let icon: String?
    let action: () -> Void
    let style: AccessibleButtonStyle

    enum AccessibleButtonStyle {
        case primary
        case secondary
        case destructive
        case plain
    }

    init(
        _ title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        style: AccessibleButtonStyle = .primary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.style = style
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let icon {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(iconColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(textColor)

                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if subtitle != nil || icon != nil {
                    Spacer()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(backgroundColor)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint ?? "Button")
        .accessibilityAddTraits(.isButton)
    }

    private var backgroundColor: Color {
        switch style {
        case .primary: .accentColor.opacity(0.1)
        case .secondary: Color(.controlBackgroundColor)
        case .destructive: .red.opacity(0.1)
        case .plain: .clear
        }
    }

    private var textColor: Color {
        switch style {
        case .primary: .accentColor
        case .secondary: .primary
        case .destructive: .red
        case .plain: .primary
        }
    }

    private var iconColor: Color {
        switch style {
        case .primary: .accentColor
        case .secondary: .secondary
        case .destructive: .red
        case .plain: .secondary
        }
    }

    private var borderColor: Color {
        switch style {
        case .primary: .accentColor.opacity(0.3)
        case .secondary: Color(.separatorColor)
        case .destructive: .red.opacity(0.3)
        case .plain: .clear
        }
    }

    private var accessibilityLabel: String {
        if let subtitle {
            return "\(title), \(subtitle)"
        }
        return title
    }

    private var accessibilityHint: String? {
        switch style {
        case .primary: "Double tap to perform primary action"
        case .secondary: "Double tap to perform secondary action"
        case .destructive: "Double tap to perform destructive action"
        case .plain: nil
        }
    }
}

// MARK: - Accessible Info Card

struct AccessibleInfoCard: View {
    let title: String
    let value: String
    let description: String?
    let icon: String
    let color: Color
    let importance: AccessibilityPriority

    enum AccessibilityPriority {
        case low
        case medium
        case high
        case critical

        var traits: AccessibilityTraits {
            switch self {
            case .low: []
            case .medium: [.updatesFrequently]
            case .high: [.updatesFrequently, .causesPageTurn]
            case .critical: [.updatesFrequently, .causesPageTurn, .playsSound]
            }
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                Spacer()

                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .multilineTextAlignment(.leading)

                if let description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(value)
        .accessibilityHint(description ?? "Information card")
        .accessibilityAddTraits(importance.traits)
    }

    private var accessibilityLabel: String {
        if let description {
            return "\(title): \(value). \(description)"
        }
        return "\(title): \(value)"
    }
}

// MARK: - Accessible Progress View

struct AccessibleProgressView: View {
    let progress: Double
    let total: Double
    let title: String
    let description: String?
    @State private var previousProgress: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            ProgressView(value: progress, total: total)
                .progressViewStyle(LinearProgressViewStyle())
                .tint(.accentColor)

            if let description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue("\(Int(progress * 100)) percent complete")
        .accessibilityHint(description ?? "Progress indicator")
        .accessibilityAddTraits([.updatesFrequently])
        .onChange(of: progress) { _, newValue in
            // Announce significant progress changes
            if newValue - previousProgress >= 0.1 {
                let announcement = "\(Int(newValue * 100)) percent complete"
                AccessibilityNotification.Announcement(announcement).post()
                previousProgress = newValue
            }
        }
    }
}

// MARK: - Accessible Status Indicator

// MARK: - Accessible Navigation

struct AccessibleTabView: View {
    @Binding var selection: Tab
    let tabs: [Tab]

    struct Tab: Identifiable, Hashable {
        let id: String
        let title: String
        let icon: String
        let badge: String?
        let isEnabled: Bool

        init(id: String, title: String, icon: String, badge: String? = nil, isEnabled: Bool = true) {
            self.id = id
            self.title = title
            self.icon = icon
            self.badge = badge
            self.isEnabled = isEnabled
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs) { tab in
                Button(action: { selection = tab }) {
                    VStack(spacing: 4) {
                        ZStack {
                            Image(systemName: tab.icon)
                                .font(.title3)
                                .foregroundColor(iconColor(for: tab))

                            if let badge = tab.badge {
                                Text(badge)
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.red)
                                    .cornerRadius(8)
                                    .offset(x: 10, y: -10)
                            }
                        }

                        Text(tab.title)
                            .font(.caption)
                            .foregroundColor(textColor(for: tab))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(selection == tab ? Color.accentColor.opacity(0.1) : Color.clear)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!tab.isEnabled)
                .accessibilityLabel(tabAccessibilityLabel(for: tab))
                .accessibilityHint("Double tap to switch to \(tab.title) tab")
                .accessibilityAddTraits(.isButton)
                .accessibilityAddTraits(selection == tab ? .isSelected : [])
            }
        }
        .padding(.horizontal, 8)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }

    private func iconColor(for tab: Tab) -> Color {
        if !tab.isEnabled {
            return Color.gray
        }
        return selection == tab ? .accentColor : .secondary
    }

    private func textColor(for tab: Tab) -> Color {
        if !tab.isEnabled {
            return Color.gray
        }
        return selection == tab ? .accentColor : .secondary
    }

    private func tabAccessibilityLabel(for tab: Tab) -> String {
        var label = tab.title
        if let badge = tab.badge {
            label += ", \(badge) notifications"
        }
        if !tab.isEnabled {
            label += ", disabled"
        }
        return label
    }
}

// MARK: - Keyboard Navigation Helper

struct KeyboardNavigable: ViewModifier {
    let onUpArrow: (() -> Void)?
    let onDownArrow: (() -> Void)?
    let onLeftArrow: (() -> Void)?
    let onRightArrow: (() -> Void)?
    let onEnter: (() -> Void)?
    let onEscape: (() -> Void)?

    /// <#Description#>
    /// - Returns: <#description#>
    func body(content: Content) -> some View {
        content
            .focusable()
            .onKeyPress(.upArrow) {
                onUpArrow?()
                return .handled
            }
            .onKeyPress(.downArrow) {
                onDownArrow?()
                return .handled
            }
            .onKeyPress(.leftArrow) {
                onLeftArrow?()
                return .handled
            }
            .onKeyPress(.rightArrow) {
                onRightArrow?()
                return .handled
            }
            .onKeyPress(.return) {
                onEnter?()
                return .handled
            }
            .onKeyPress(.escape) {
                onEscape?()
                return .handled
            }
    }
}

extension View {
    func keyboardNavigable(
        onUpArrow: (() -> Void)? = nil,
        onDownArrow: (() -> Void)? = nil,
        onLeftArrow: (() -> Void)? = nil,
        onRightArrow: (() -> Void)? = nil,
        onEnter: (() -> Void)? = nil,
        onEscape: (() -> Void)? = nil
    ) -> some View {
        modifier(KeyboardNavigable(
            onUpArrow: onUpArrow,
            onDownArrow: onDownArrow,
            onLeftArrow: onLeftArrow,
            onRightArrow: onRightArrow,
            onEnter: onEnter,
            onEscape: onEscape
        ))
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        AccessibleButton(
            "Analyze Code",
            subtitle: "Run comprehensive analysis",
            icon: "brain.head.profile",
            style: AccessibleButton.AccessibleButtonStyle.primary
        ) {
            AppLogger.shared.debug("Analyze button tapped in preview")
        }

        AccessibleInfoCard(
            title: "Code Quality",
            value: "85%",
            description: "Above average quality score",
            icon: "chart.bar.fill",
            color: .green,
            importance: .medium
        )

        AccessibleProgressView(
            progress: 0.65,
            total: 1.0,
            title: "Analysis Progress",
            description: "Processing file 13 of 20"
        )

        AccessibleStatusIndicator(.analyzing)

        AccessibleTabView(
            selection: .constant(AccessibleTabView.Tab(
                id: "analysis",
                title: "Analysis",
                icon: "doc.text.magnifyingglass"
            )),
            tabs: [
                AccessibleTabView.Tab(id: "analysis", title: "Analysis", icon: "doc.text.magnifyingglass"),
                AccessibleTabView.Tab(id: "files", title: "Files", icon: "folder", badge: "3"),
                AccessibleTabView.Tab(id: "insights", title: "Insights", icon: "brain.head.profile"),
            ]
        )
    }
    .padding()
}
