#!/usr/bin/env python3
"""
Continuous Monitoring Dashboard System
Real-time development metrics tracking and alerting

This system provides continuous monitoring of development metrics,
real-time dashboard updates, and automated alerting for critical changes.
"""

import json
import asyncio
import logging
import threading
import time
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any, Callable
from dataclasses import dataclass, asdict
from pathlib import Path
import websockets
import aiohttp
from aiohttp import web
import sqlite3
from collections import deque
import statistics

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@dataclass
class MetricReading:
    """Individual metric reading"""
    metric_name: str
    value: float
    timestamp: datetime
    status: str
    source: str
    metadata: Dict[str, Any]

@dataclass
class AlertRule:
    """Alert rule configuration"""
    metric_name: str
    condition: str  # 'above', 'below', 'equals', 'change'
    threshold: float
    severity: str  # 'info', 'warning', 'critical'
    action: str
    enabled: bool = True

class MetricsDatabase:
    """SQLite database for storing metrics history"""
    
    def __init__(self, db_path: Path):
        self.db_path = db_path
        self._init_database()
    
    def _init_database(self):
        """Initialize the metrics database"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS metrics (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                metric_name TEXT NOT NULL,
                value REAL NOT NULL,
                timestamp TEXT NOT NULL,
                status TEXT NOT NULL,
                source TEXT NOT NULL,
                metadata TEXT
            )
        ''')
        
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS alerts (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                metric_name TEXT NOT NULL,
                alert_type TEXT NOT NULL,
                message TEXT NOT NULL,
                severity TEXT NOT NULL,
                timestamp TEXT NOT NULL,
                resolved BOOLEAN DEFAULT FALSE
            )
        ''')
        
        conn.commit()
        conn.close()
    
    def store_metric(self, metric: MetricReading):
        """Store a metric reading"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute('''
            INSERT INTO metrics (metric_name, value, timestamp, status, source, metadata)
            VALUES (?, ?, ?, ?, ?, ?)
        ''', (
            metric.metric_name,
            metric.value,
            metric.timestamp.isoformat(),
            metric.status,
            metric.source,
            json.dumps(metric.metadata)
        ))
        
        conn.commit()
        conn.close()
    
    def get_recent_metrics(self, metric_name: str, hours: int = 24) -> List[MetricReading]:
        """Get recent metrics for a specific metric"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cutoff_time = (datetime.now() - timedelta(hours=hours)).isoformat()
        
        cursor.execute('''
            SELECT metric_name, value, timestamp, status, source, metadata
            FROM metrics
            WHERE metric_name = ? AND timestamp > ?
            ORDER BY timestamp DESC
        ''', (metric_name, cutoff_time))
        
        results = []
        for row in cursor.fetchall():
            results.append(MetricReading(
                metric_name=row[0],
                value=row[1],
                timestamp=datetime.fromisoformat(row[2]),
                status=row[3],
                source=row[4],
                metadata=json.loads(row[5]) if row[5] else {}
            ))
        
        conn.close()
        return results

class AlertManager:
    """Manages alerts and notifications"""
    
    def __init__(self, db: MetricsDatabase):
        self.db = db
        self.alert_rules: List[AlertRule] = []
        self.alert_callbacks: List[Callable] = []
    
    def add_alert_rule(self, rule: AlertRule):
        """Add an alert rule"""
        self.alert_rules.append(rule)
        logger.info(f"Added alert rule for {rule.metric_name}: {rule.condition} {rule.threshold}")
    
    def add_alert_callback(self, callback: Callable):
        """Add a callback for alert notifications"""
        self.alert_callbacks.append(callback)
    
    def check_alerts(self, metric: MetricReading):
        """Check if a metric triggers any alerts"""
        for rule in self.alert_rules:
            if not rule.enabled or rule.metric_name != metric.metric_name:
                continue
            
            triggered = False
            message = ""
            
            if rule.condition == 'above' and metric.value > rule.threshold:
                triggered = True
                message = f"{metric.metric_name} is {metric.value} (above threshold {rule.threshold})"
            elif rule.condition == 'below' and metric.value < rule.threshold:
                triggered = True
                message = f"{metric.metric_name} is {metric.value} (below threshold {rule.threshold})"
            elif rule.condition == 'equals' and metric.value == rule.threshold:
                triggered = True
                message = f"{metric.metric_name} equals critical value {rule.threshold}"
            
            if triggered:
                self._trigger_alert(rule, metric, message)
    
    def _trigger_alert(self, rule: AlertRule, metric: MetricReading, message: str):
        """Trigger an alert"""
        alert_data = {
            "metric_name": rule.metric_name,
            "alert_type": rule.condition,
            "message": message,
            "severity": rule.severity,
            "timestamp": datetime.now().isoformat(),
            "metric_value": metric.value,
            "rule": asdict(rule)
        }
        
        # Store alert in database
        conn = sqlite3.connect(self.db.db_path)
        cursor = conn.cursor()
        cursor.execute('''
            INSERT INTO alerts (metric_name, alert_type, message, severity, timestamp)
            VALUES (?, ?, ?, ?, ?)
        ''', (rule.metric_name, rule.condition, message, rule.severity, alert_data["timestamp"]))
        conn.commit()
        conn.close()
        
        # Notify callbacks
        for callback in self.alert_callbacks:
            try:
                callback(alert_data)
            except Exception as e:
                logger.error(f"Alert callback error: {e}")
        
        logger.warning(f"ALERT [{rule.severity.upper()}]: {message}")

class DashboardServer:
    """Web-based dashboard server"""
    
    def __init__(self, db: MetricsDatabase, port: int = 8080):
        self.db = db
        self.port = port
        self.app = web.Application()
        self.connected_clients = set()
        self._setup_routes()
    
    def _setup_routes(self):
        """Setup web routes"""
        self.app.router.add_get('/', self.serve_dashboard)
        self.app.router.add_get('/api/metrics', self.api_metrics)
        self.app.router.add_get('/api/metrics/{metric_name}', self.api_metric_history)
        self.app.router.add_get('/ws', self.websocket_handler)
        self.app.router.add_static('/static', Path(__file__).parent / 'static')
    
    async def serve_dashboard(self, request) -> Any:
        """Serve the main dashboard page"""
        html_content = """
<!DOCTYPE html>
<html>
<head>
    <title>CodingReviewer Monitoring Dashboard</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .dashboard { display: grid; grid-template-columns: repeat(auto-fit, minmax(400px, 1fr)); gap: 20px; }
        .metric-card { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .metric-value { font-size: 2em; font-weight: bold; margin: 10px 0; }
        .metric-status { padding: 5px 10px; border-radius: 4px; color: white; }
        .status-good { background: #28a745; }
        .status-warning { background: #ffc107; color: black; }
        .status-critical { background: #dc3545; }
        .alert { background: #f8d7da; border: 1px solid #f5c6cb; padding: 10px; margin: 10px 0; border-radius: 4px; }
        h1 { color: #333; text-align: center; }
        .timestamp { color: #666; font-size: 0.9em; }
    </style>
</head>
<body>
    <h1>🚀 CodingReviewer Monitoring Dashboard</h1>
    <div id="alerts"></div>
    <div class="dashboard" id="dashboard">
        <div class="metric-card">
            <h3>📊 Loading Metrics...</h3>
            <p>Connecting to real-time data feed...</p>
        </div>
    </div>
    
    <script>
        const ws = new WebSocket('ws://localhost:8080/ws');
        const dashboard = document.getElementById('dashboard');
        const alertsContainer = document.getElementById('alerts');
        
        ws.onmessage = function(event) {
            const data = JSON.parse(event.data);
            updateDashboard(data);
        };
        
        function updateDashboard(data) {
            if (data.type === 'metrics_update') {
                renderMetrics(data.metrics);
            } else if (data.type === 'alert') {
                showAlert(data.alert);
            }
        }
        
        function renderMetrics(metrics) {
            dashboard.innerHTML = '';
            for (const [name, metric] of Object.entries(metrics)) {
                const card = document.createElement('div');
                card.className = 'metric-card';
                card.innerHTML = `
                    <h3>${metric.name}</h3>
                    <div class="metric-value">${metric.value}</div>
                    <div class="metric-status status-${metric.status}">${metric.status.toUpperCase()}</div>
                    <div class="timestamp">Last updated: ${new Date(metric.timestamp).toLocaleString()}</div>
                `;
                dashboard.appendChild(card);
            }
        }
        
        function showAlert(alert) {
            const alertDiv = document.createElement('div');
            alertDiv.className = 'alert';
            alertDiv.innerHTML = `
                <strong>🚨 ${alert.severity.toUpperCase()} ALERT:</strong> ${alert.message}
                <div class="timestamp">${new Date(alert.timestamp).toLocaleString()}</div>
            `;
            alertsContainer.appendChild(alertDiv);
            setTimeout(() => alertDiv.remove(), 10000); // Remove after 10 seconds
        }
        
        // Request initial data
        fetch('/api/metrics').then(r => r.json()).then(data => {
            renderMetrics(data);
        });
    </script>
</body>
</html>
        """
        return web.Response(text=html_content, content_type='text/html')
    
    async def api_metrics(self, request) -> Any:
        """API endpoint for current metrics"""
        # Get latest metrics from database
        conn = sqlite3.connect(self.db.db_path)
        cursor = conn.cursor()
        
        cursor.execute('''
            SELECT metric_name, value, timestamp, status, source
            FROM metrics
            WHERE timestamp = (
                SELECT MAX(timestamp) FROM metrics m2 WHERE m2.metric_name = metrics.metric_name
            )
        ''')
        
        metrics = {}
        for row in cursor.fetchall():
            metrics[row[0]] = {
                'name': row[0],
                'value': row[1],
                'timestamp': row[2],
                'status': row[3],
                'source': row[4]
            }
        
        conn.close()
        return web.json_response(metrics)
    
    async def websocket_handler(self, request) -> Any:
        """WebSocket handler for real-time updates"""
        ws = web.WebSocketResponse()
        await ws.prepare(request)
        
        self.connected_clients.add(ws)
        logger.info(f"Dashboard client connected. Total clients: {len(self.connected_clients)}")
        
        try:
            async for msg in ws:
                if msg.type == aiohttp.WSMsgType.TEXT:
                    if msg.data == 'close':
                        await ws.close()
                elif msg.type == aiohttp.WSMsgType.ERROR:
                    logger.error(f'WebSocket error: {ws.exception()}')
        finally:
            self.connected_clients.discard(ws)
            logger.info(f"Dashboard client disconnected. Total clients: {len(self.connected_clients)}")
        
        return ws
    
    async def broadcast_update(self, data: Dict[str, Any]) -> Any:
        """Broadcast update to all connected clients"""
        if not self.connected_clients:
            return
        
        message = json.dumps(data)
        disconnected = set()
        
        for client in self.connected_clients:
            try:
                await client.send_str(message)
            except Exception:
                disconnected.add(client)
        
        # Remove disconnected clients
        self.connected_clients -= disconnected

class ContinuousMonitor:
    """Main continuous monitoring system"""
    
    def __init__(self, project_path: str = "."):
        self.project_path = Path(project_path)
        self.output_dir = self.project_path / ".monitoring"
        self.output_dir.mkdir(exist_ok=True)
        
        # Initialize components
        self.db = MetricsDatabase(self.output_dir / "metrics.db")
        self.alert_manager = AlertManager(self.db)
        self.dashboard = DashboardServer(self.db)
        
        # Monitoring state
        self.monitoring_active = False
        self.monitoring_thread = None
        self.metrics_cache = {}
        
        # Setup default alert rules
        self._setup_default_alerts()
        
        # Setup alert callbacks
        self.alert_manager.add_alert_callback(self._handle_alert)
        
        logger.info("Continuous monitoring system initialized")
    
    def _setup_default_alerts(self):
        """Setup default alert rules"""
        alerts = [
            AlertRule("code_complexity_score", "below", 70.0, "warning", "quality_degradation"),
            AlertRule("technical_debt_score", "above", 80.0, "critical", "technical_debt_critical"),
            AlertRule("high_impact_issues", "above", 5.0, "warning", "quality_issues"),
            AlertRule("overall_health_score", "below", 60.0, "critical", "health_critical"),
            AlertRule("failed_tests", "above", 0.0, "critical", "test_failures"),
        ]
        
        for alert in alerts:
            self.alert_manager.add_alert_rule(alert)
    
    def _handle_alert(self, alert_data: Dict[str, Any]):
        """Handle triggered alerts"""
        # Broadcast to dashboard
        asyncio.create_task(self.dashboard.broadcast_update({
            "type": "alert",
            "alert": alert_data
        }))
        
        # Log to file
        alert_log = self.output_dir / "alerts.log"
        with open(alert_log, 'a') as f:
            f.write(f"{alert_data['timestamp']}: {alert_data['message']}\n")
    
    async def collect_metrics(self) -> Any:
        """Collect current metrics from various sources"""
        metrics = {}
        
        try:
            # Try to get metrics from advanced integration
            import sys
            sys.path.append(str(self.project_path))
            from advanced_mcp_integration import AdvancedMCPIntegration
            
            integration = AdvancedMCPIntegration(str(self.project_path))
            results = await integration.run_comprehensive_analysis()
            
            # Extract metrics from analysis results
            summary = results.get("summary", {})
            analytics = results.get("analytics", {})
            
            # Core metrics
            metrics.update({
                "patterns_detected": summary.get("patterns_detected", 0),
                "high_impact_issues": summary.get("high_impact_issues", 0),
                "overall_health_score": summary.get("overall_health_score", 0),
                "optimization_opportunities": summary.get("optimization_opportunities", 0),
                "estimated_time_savings": summary.get("estimated_time_savings_hours", 0)
            })
            
            # Analytics metrics
            for category, category_metrics in analytics.items():
                for metric in category_metrics:
                    metric_name = f"{category}_{metric['metric_name'].lower().replace(' ', '_')}"
                    metrics[metric_name] = metric['metric_value']
            
        except Exception as e:
            logger.warning(f"Could not collect advanced metrics: {e}")
            # Fallback to basic file-based metrics
            metrics.update(await self._collect_basic_metrics())
        
        return metrics
    
    async def _collect_basic_metrics(self) -> Dict[str, float]:
        """Collect basic metrics from file system"""
        metrics = {}
        
        # Count files
        py_files = len(list(self.project_path.glob("**/*.py")))
        swift_files = len(list(self.project_path.glob("**/*.swift")))
        
        metrics["python_files"] = py_files
        metrics["swift_files"] = swift_files
        metrics["total_files"] = py_files + swift_files
        
        # Check for recent changes
        recent_changes = 0
        cutoff = datetime.now() - timedelta(hours=24)
        
        for file_path in self.project_path.glob("**/*.py"):
            try:
                if datetime.fromtimestamp(file_path.stat().st_mtime) > cutoff:
                    recent_changes += 1
            except Exception as e:
                continue
        
        metrics["recent_changes_24h"] = recent_changes
        
        return metrics
    
    async def monitoring_loop(self):
        """Main monitoring loop"""
        logger.info("Starting continuous monitoring loop")
        
        while self.monitoring_active:
            try:
                # Collect metrics
                current_metrics = await self.collect_metrics()
                
                # Store metrics and check alerts
                timestamp = datetime.now()
                dashboard_metrics = {}
                
                for name, value in current_metrics.items():
                    # Determine status based on metric type and value
                    status = self._determine_metric_status(name, value)
                    
                    # Create metric reading
                    metric = MetricReading(
                        metric_name=name,
                        value=float(value),
                        timestamp=timestamp,
                        status=status,
                        source="continuous_monitor",
                        metadata={}
                    )
                    
                    # Store in database
                    self.db.store_metric(metric)
                    
                    # Check alerts
                    self.alert_manager.check_alerts(metric)
                    
                    # Prepare for dashboard
                    dashboard_metrics[name] = {
                        'name': name.replace('_', ' ').title(),
                        'value': value,
                        'timestamp': timestamp.isoformat(),
                        'status': status,
                        'source': 'continuous_monitor'
                    }
                
                # Update dashboard
                await self.dashboard.broadcast_update({
                    "type": "metrics_update",
                    "metrics": dashboard_metrics
                })
                
                # Cache metrics
                self.metrics_cache = current_metrics
                
                logger.info(f"Collected {len(current_metrics)} metrics")
                
                # Wait before next collection
                await asyncio.sleep(60)  # Collect every minute
                
            except Exception as e:
                logger.error(f"Error in monitoring loop: {e}")
                await asyncio.sleep(30)  # Shorter wait on error
    
    def _determine_metric_status(self, metric_name: str, value: float) -> str:
        """Determine the status of a metric based on its value"""
        # Define status rules
        status_rules = {
            "overall_health_score": {"good": 80, "warning": 60},
            "code_complexity_score": {"good": 80, "warning": 60},
            "technical_debt_score": {"warning": 40, "critical": 70},
            "high_impact_issues": {"good": 2, "warning": 5},
            "failed_tests": {"good": 0, "warning": 0},
        }
        
        rules = status_rules.get(metric_name, {"good": float('inf'), "warning": float('inf')})
        
        if "failed_tests" in metric_name and value > 0:
            return "critical"
        elif "debt_score" in metric_name:
            if value > rules.get("critical", 70):
                return "critical"
            elif value > rules.get("warning", 40):
                return "warning"
            else:
                return "good"
        else:
            if value >= rules.get("good", 80):
                return "good"
            elif value >= rules.get("warning", 60):
                return "warning"
            else:
                return "critical"
    
    async def start(self) -> Any:
        """Start the continuous monitoring system"""
        if self.monitoring_active:
            logger.warning("Monitoring already active")
            return
        
        self.monitoring_active = True
        
        # Start monitoring loop
        monitoring_task = asyncio.create_task(self.monitoring_loop())
        
        # Start dashboard server
        runner = web.AppRunner(self.dashboard.app)
        await runner.setup()
        site = web.TCPSite(runner, 'localhost', self.dashboard.port)
        await site.start()
        
        logger.info(f"Dashboard server started at http://localhost:{self.dashboard.port}")
        logger.info("Continuous monitoring system started")
        
        return monitoring_task
    
    def stop(self):
        """Stop the continuous monitoring system"""
        self.monitoring_active = False
        logger.info("Continuous monitoring system stopped")

# Demo and CLI
async def main():
    """Main function for testing"""
    print("🔍 Starting Continuous Monitoring Dashboard System...")
    
    monitor = ContinuousMonitor()
    
    try:
        # Start the monitoring system
        monitoring_task = await monitor.start()
        
        print(f"✅ Monitoring dashboard running at: http://localhost:{monitor.dashboard.port}")
        print("📊 Real-time metrics collection active")
        print("🚨 Alert system operational")
        print("💡 Press Ctrl+C to stop")
        
        # Keep running
        await monitoring_task
        
    except KeyboardInterrupt:
        print("\n🛑 Stopping monitoring system...")
        monitor.stop()
    except Exception as e:
        print(f"❌ Error: {e}")
        monitor.stop()

if __name__ == "__main__":
    asyncio.run(main())