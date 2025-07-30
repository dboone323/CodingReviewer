#!/bin/bash
# Debug Symbols Optimization Script

echo "🔧 Optimizing debug symbols for faster debugging..."

# Xcode project optimization for debugging
if [ -f "CodingReviewer.xcodeproj/project.pbxproj" ]; then
    echo "• Ensuring debug symbols are enabled..."
    # Check if debug information format is set to DWARF with dSYM
    if ! grep -q "DEBUG_INFORMATION_FORMAT.*dwarf-with-dsym" "CodingReviewer.xcodeproj/project.pbxproj"; then
        echo "  ⚠️ Consider setting DEBUG_INFORMATION_FORMAT to dwarf-with-dsym for optimal debugging"
    fi
    
    # Check optimization level for debug builds
    if grep -q "GCC_OPTIMIZATION_LEVEL.*0" "CodingReviewer.xcodeproj/project.pbxproj"; then
        echo "  ✅ Debug optimization level properly set to -O0"
    else
        echo "  ⚠️ Consider setting GCC_OPTIMIZATION_LEVEL to 0 for debug builds"
    fi
fi

echo "✅ Debug symbols optimization check complete"
