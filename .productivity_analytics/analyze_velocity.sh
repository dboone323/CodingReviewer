#!/bin/bash

echo "⚡ Analyzing Coding Velocity..."

# Git-based velocity analysis
echo "📊 Collecting Git metrics..."

# Lines of code analysis
lines_today=$(git log --since="1 day ago" --numstat --pretty=format: | awk '{added+=$1} END {print added+0}')
lines_week=$(git log --since="7 days ago" --numstat --pretty=format: | awk '{added+=$1} END {print added+0}')
lines_month=$(git log --since="30 days ago" --numstat --pretty=format: | awk '{added+=$1} END {print added+0}')

# Commit analysis
commits_today=$(git log --since="1 day ago" --oneline | wc -l | tr -d ' ')
commits_week=$(git log --since="7 days ago" --oneline | wc -l | tr -d ' ')
commits_month=$(git log --since="30 days ago" --oneline | wc -l | tr -d ' ')

# File modification analysis
files_today=$(git log --since="1 day ago" --name-only --pretty=format: | sort | uniq | wc -l | tr -d ' ')
files_week=$(git log --since="7 days ago" --name-only --pretty=format: | sort | uniq | wc -l | tr -d ' ')

echo "📈 Velocity Metrics:"
echo "  Lines added today: $lines_today"
echo "  Lines added (7d avg): $((lines_week / 7))"
echo "  Lines added (30d avg): $((lines_month / 30))"
echo ""
echo "  Commits today: $commits_today"
echo "  Commits (7d avg): $((commits_week / 7))"
echo "  Commits (30d avg): $((commits_month / 30))"
echo ""
echo "  Files modified today: $files_today"
echo "  Files modified (7d avg): $((files_week / 7))"

# Calculate velocity score (0-100)
velocity_score=75
if [ "$lines_today" -gt 400 ]; then
    velocity_score=$((velocity_score + 10))
fi
if [ "$commits_today" -gt 6 ]; then
    velocity_score=$((velocity_score + 8))
fi
if [ "$files_today" -gt 10 ]; then
    velocity_score=$((velocity_score + 7))
fi

echo ""
echo "🎯 Velocity Score: $velocity_score/100"

if [ "$velocity_score" -gt 85 ]; then
    echo "🚀 Excellent velocity! You're in the zone!"
elif [ "$velocity_score" -gt 70 ]; then
    echo "✅ Good productivity day"
else
    echo "💡 Consider focusing on fewer, larger commits"
fi
