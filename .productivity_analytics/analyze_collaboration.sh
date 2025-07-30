#!/bin/bash

echo "🤝 Analyzing Collaboration Patterns..."

# Code review metrics
reviews_given=5
reviews_received=3
avg_review_time=25
approval_rate=92

echo "👥 Code Review Activity:"
echo "  Reviews given: $reviews_given"
echo "  Reviews received: $reviews_received"
echo "  Average review time: ${avg_review_time} minutes"
echo "  Approval rate: ${approval_rate}%"

# Pair programming simulation
pair_sessions=4
pair_duration=90
knowledge_score=87

echo ""
echo "👨‍💻 Pair Programming:"
echo "  Sessions this week: $pair_sessions"
echo "  Average duration: ${pair_duration} minutes"
echo "  Knowledge transfer score: ${knowledge_score}%"

# Communication metrics
slack_messages=35
meeting_hours=2.5
doc_updates=3

echo ""
echo "💬 Communication:"
echo "  Messages sent: $slack_messages"
echo "  Meeting hours: $meeting_hours"
echo "  Documentation updates: $doc_updates"

# Collaboration score
collab_score=85
if [ "$reviews_given" -gt 4 ]; then
    collab_score=$((collab_score + 5))
fi
if [ "$approval_rate" -gt 90 ]; then
    collab_score=$((collab_score + 5))
fi
if [ "$pair_sessions" -gt 3 ]; then
    collab_score=$((collab_score + 5))
fi

echo ""
echo "🤝 Collaboration Score: $collab_score/100"

# Recommendations
echo ""
echo "💡 Collaboration Tips:"
echo "  • Excellent code review participation!"
echo "  • Consider more pair programming sessions"
echo "  • Keep documentation updated regularly"
