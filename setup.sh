#!/bin/bash

# CodeReviewer Development Setup Script
# This script sets up the development environment for new contributors

set -e

echo "🚀 Setting up CodeReviewer development environment..."

# Check if we're in the right directory
if [ ! -f "CodingReviewer.xcodeproj/project.pbxproj" ]; then
    echo "❌ Error: Please run this script from the CodeReviewer project root directory"
    exit 1
fi

# Check for required tools
echo "🔍 Checking for required tools..."

# Check for Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Error: Xcode is not installed or not in PATH"
    echo "Please install Xcode from the App Store"
    exit 1
fi

# Check for Git
if ! command -v git &> /dev/null; then
    echo "❌ Error: Git is not installed"
    echo "Please install Git: https://git-scm.com/download/mac"
    exit 1
fi

# Check for Homebrew
if ! command -v brew &> /dev/null; then
    echo "⚠️  Warning: Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install SwiftLint
echo "📦 Installing SwiftLint..."
if ! command -v swiftlint &> /dev/null; then
    brew install swiftlint
else
    echo "✅ SwiftLint already installed"
fi

# Set up Git hooks (optional)
echo "🔧 Setting up Git hooks..."
if [ ! -f ".git/hooks/pre-commit" ]; then
    cat > .git/hooks/pre-commit << 'EOF'
#!/bin/sh
# Run SwiftLint before commit
if which swiftlint >/dev/null; then
    swiftlint --strict
else
    echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
fi
EOF
    chmod +x .git/hooks/pre-commit
    echo "✅ Pre-commit hook installed"
else
    echo "✅ Pre-commit hook already exists"
fi

# Build the project to ensure everything works
echo "🔨 Building project..."
xcodebuild -project CodingReviewer.xcodeproj -scheme CodingReviewer -destination 'platform=macOS' build

# Run tests
echo "🧪 Running tests..."
xcodebuild -project CodingReviewer.xcodeproj -scheme CodingReviewer -destination 'platform=macOS' test

echo ""
echo "🎉 Setup complete! You're ready to start developing."
echo ""
echo "Next steps:"
echo "1. Open CodingReviewer.xcodeproj in Xcode"
echo "2. Read CONTRIBUTING.md for development guidelines"
echo "3. Check ENHANCEMENT_TRACKER.md for current feature plans"
echo "4. Create a new branch for your feature: git checkout -b feature/your-feature"
echo ""
echo "Happy coding! 🚀"
