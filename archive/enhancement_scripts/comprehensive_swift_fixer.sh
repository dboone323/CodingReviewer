#!/bin/bash

echo "🔧 Comprehensive Swift Error Fixer"
echo "=================================="
echo "Fixing specific compilation errors found in build"
echo

cd /Users/danielstevens/Desktop/CodingReviewer

# Function to fix AnalyticsReport constructor issues
fix_analytics_report() {
    echo "🔧 Fixing AnalyticsReport constructor..."
    
    # Find the problematic line and fix it properly
    local file="CodingReviewer/Components/EnterpriseAnalytics.swift"
    if [ -f "$file" ]; then
        # Replace the incorrect constructor call
        sed -i '' 's/return AnalyticsReport(title: "Analytics Report", summary: "Comprehensive analytics data", metrics: \[\], trends: \[\], timeframe: \.daily,/return AnalyticsReport(title: "Analytics Report", summary: "Comprehensive analytics data", metrics: [], trends: [], timeframe: .week)/' "$file"
        echo "  ✓ Fixed AnalyticsReport constructor"
    fi
}

# Function to fix AnalyticsTimeframe enum
fix_timeframe_enum() {
    echo "🔧 Fixing AnalyticsTimeframe enum..."
    
    # Check if the enum exists and add missing cases
    local analytics_file="CodingReviewer/SharedTypes/AnalyticsTypes.swift"
    if [ -f "$analytics_file" ]; then
        # Add daily case if missing
        if ! grep -q "case daily" "$analytics_file"; then
            sed -i '' '/enum AnalyticsTimeframe/,/}/ s/case week/case daily\n    case week/' "$analytics_file"
            echo "  ✓ Added missing daily case to AnalyticsTimeframe"
        fi
    fi
}

# Function to fix EnterpriseIntegration return type
fix_integration_return_type() {
    echo "🔧 Fixing EnterpriseIntegration return type..."
    
    local file="CodingReviewer/Components/EnterpriseIntegration.swift"
    if [ -f "$file" ]; then
        # Fix the switch statement and return type
        sed -i '' '/case \.codeFile:/,/return "Code File Data"/ {
            s/return "Code File Data"/return [["type": "codeFile", "data": "Code File Data"]]/
        }' "$file"
        echo "  ✓ Fixed return type for codeFile case"
    fi
}

# Function to fix SystemStatus properties
fix_system_status() {
    echo "🔧 Fixing SystemStatus properties..."
    
    local file="CodingReviewer/SharedTypes/SystemTypes.swift"
    if [ -f "$file" ]; then
        # Add missing properties to SystemStatus
        if ! grep -q "successRate" "$file"; then
            sed -i '' '/struct SystemStatus/,/}/ {
                /}/i\
    let successRate: Double\
    let healthScore: Double
            }' "$file"
            echo "  ✓ Added missing properties to SystemStatus"
        fi
    else
        # Create the SystemTypes file if it doesn't exist
        cat > "$file" << 'EOF'
import Foundation

public struct SystemStatus {
    let isActive: Bool
    let uptime: TimeInterval
    let successRate: Double
    let healthScore: Double
    let lastUpdate: Date
    
    init(isActive: Bool = true, uptime: TimeInterval = 0, successRate: Double = 0.95, healthScore: Double = 0.9, lastUpdate: Date = Date()) {
        self.isActive = isActive
        self.uptime = uptime
        self.successRate = successRate
        self.healthScore = healthScore
        self.lastUpdate = lastUpdate
    }
}
EOF
        echo "  ✓ Created SystemTypes.swift with SystemStatus"
    fi
}

# Function to fix AnalyticsReport properties
fix_analytics_report_properties() {
    echo "🔧 Fixing AnalyticsReport properties..."
    
    local file="CodingReviewer/SharedTypes/AnalyticsTypes.swift"
    if [ -f "$file" ]; then
        # Add missing performanceMetrics property
        if ! grep -q "performanceMetrics" "$file"; then
            sed -i '' '/struct AnalyticsReport/,/}/ {
                /}/i\
    public let performanceMetrics: [String: Double]
            }' "$file"
            
            # Also fix the constructor
            sed -i '' '/init.*AnalyticsReport/,/}/ {
                /self\.timeframe = timeframe/a\
        self.performanceMetrics = [:]
            }' "$file"
            echo "  ✓ Added performanceMetrics to AnalyticsReport"
        fi
    fi
}

# Function to verify specific files exist and create them if needed
ensure_required_files() {
    echo "🔧 Ensuring required files exist..."
    
    # Create SystemTypes.swift if missing
    if [ ! -f "CodingReviewer/SharedTypes/SystemTypes.swift" ]; then
        mkdir -p "CodingReviewer/SharedTypes"
        fix_system_status
    fi
}

# Function to run comprehensive build test
test_build() {
    echo "🧪 Testing complete build..."
    
    BUILD_OUTPUT=$(xcodebuild -scheme CodingReviewer -configuration Debug build 2>&1)
    BUILD_EXIT_CODE=$?
    
    ERROR_COUNT=$(echo "$BUILD_OUTPUT" | grep -c "error:")
    WARNING_COUNT=$(echo "$BUILD_OUTPUT" | grep -c "warning:")
    
    echo "Build Results:"
    echo "  Errors: $ERROR_COUNT"
    echo "  Warnings: $WARNING_COUNT"
    
    if [ $BUILD_EXIT_CODE -eq 0 ]; then
        echo "✅ BUILD SUCCESS! Project compiles successfully."
        return 0
    else
        echo "❌ Build failed. Remaining errors:"
        echo "$BUILD_OUTPUT" | grep "error:" | head -5
        return 1
    fi
}

# Main execution
echo "🚀 Starting comprehensive error fixing..."

ensure_required_files
fix_analytics_report
fix_timeframe_enum
fix_integration_return_type
fix_system_status
fix_analytics_report_properties

echo
echo "🧪 Testing all fixes..."
if test_build; then
    echo "🎉 SUCCESS! All major Swift compilation errors have been fixed!"
    echo "The CodingReviewer project should now build successfully."
else
    echo "⚠️  Some errors may remain. Check output above for details."
fi

echo
echo "✅ Comprehensive Swift error fixing complete!"
