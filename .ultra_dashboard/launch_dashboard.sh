#!/bin/bash
echo "🚀 Launching Ultra Enterprise Dashboard..."

# Start API server in background
cd "/Users/danielstevens/Desktop/CodingReviewer/.ultra_dashboard/api"
python3 dashboard_api.py &
API_PID=$!

# Start simple HTTP server for dashboard
cd "/Users/danielstevens/Desktop/CodingReviewer/.ultra_dashboard/web"
python3 -m http.server 3000 &
WEB_PID=$!

echo "✅ Dashboard launched successfully!"
echo "🌐 Dashboard URL: http://localhost:3000"
echo "🔧 API URL: http://localhost:3001"
echo ""
echo "Press Ctrl+C to stop the dashboard..."

# Wait for interrupt
trap "kill $API_PID $WEB_PID; exit" INT
wait
