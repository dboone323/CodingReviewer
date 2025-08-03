import SwiftUI

struct PatternAnalysisView: View {
    @EnvironmentObject private var fileManager: FileManagerService

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundColor(.blue)

            Text("Pattern Analysis")
                .font(.title)
                .fontWeight(.bold)

            if fileManager.uploadedFiles.isEmpty {
                Text("Upload code files to start pattern analysis")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("Analyzing \(fileManager.uploadedFiles.count) files for code patterns and improvements")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 12) {
                AnalysisFeatureItem(icon: "magnifyingglass", title: "Code Smell Detection", description: "Identify code smells automatically")
                AnalysisFeatureItem(icon: "arrow.triangle.2.circlepath", title: "Refactoring Suggestions", description: "Smart refactoring recommendations")
                AnalysisFeatureItem(icon: "chart.bar", title: "Complexity Analysis", description: "Measure code complexity metrics")
                AnalysisFeatureItem(icon: "link", title: "Dependency Analysis", description: "Analyze code dependencies")
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)

            if !fileManager.uploadedFiles.isEmpty {
                Text("Advanced pattern analysis features are being developed and will be available in the next update")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct AnalysisFeatureItem: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

struct FeatureItem: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}
