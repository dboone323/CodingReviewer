#!/bin/bash

# Quick Setup Script for CodingReviewer Development
# Run this script to set up your daily development environment

echo "🚀 Setting up CodingReviewer development environment..."

# Navigate to project directory
cd /Users/danielstevens/Desktop/CodingReviewer

# Activate Python environment
echo "🐍 Activating Python virtual environment..."
source .venv/bin/activate

# Run quick health check
echo "🔍 Running system health check..."
python -c "
import sys
print(f'✅ Python: {sys.version}')

try:
    import pytest, jupyter, pandas, plotly, numpy, matplotlib
    print('✅ All Python packages available')
except ImportError as e:
    print(f'❌ Missing package: {e}')

try:
    import subprocess
    result = subprocess.run(['xcodebuild', '-version'], capture_output=True, text=True)
    if result.returncode == 0:
        print('✅ Xcode available')
    else:
        print('⚠️ Xcode not available')
except:
    print('⚠️ Xcode not available')
"

# Run quick test to ensure everything works
echo "🧪 Running quick test validation..."
python -m pytest python_tests/ -x -q

echo ""
echo "🎯 Environment ready! Next steps:"
echo "1. Open VS Code: open -a 'Visual Studio Code' ."
echo "2. Open notebook: open jupyter_notebooks/pylance_jupyter_integration.ipynb"
echo "3. Run tests: python -m pytest python_tests/ -v"
echo "4. Check Swift tests: xcodebuild test -scheme CodingReviewer"
echo ""
echo "📚 See DEVELOPMENT_WORKFLOW.md for detailed workflows"
