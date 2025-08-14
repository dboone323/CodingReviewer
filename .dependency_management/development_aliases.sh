#!/bin/bash

# Development Aliases for CodingReviewer Project
# This file contains useful aliases and functions for development workflow

# Git aliases for quick operations
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline'

# Project specific aliases
alias run-tests='python -m pytest Tests/'
alias quality-check='python workflow_quality_check.py'
alias build-project='xcodebuild -project CodingReviewer.xcodeproj'

# Quick navigation
alias cdcr='cd /Users/danielstevens/Desktop/Code/Projects/CodingReviewer'

# Python environment
alias activate-env='source .venv/bin/activate'

# Quality tools
alias lint='flake8 . --exclude=.venv'
alias format='black . --exclude=.venv'

echo "CodingReviewer development aliases loaded successfully!"
