#!/usr/bin/env python3
"""
Performance Monitoring for Workflows
Monitors and reports on workflow performance metrics
"""

import time
import json
import psutil
from datetime import datetime
from pathlib import Path
from typing import Dict, Any

class PerformanceMonitor:
    """Monitors workflow performance"""
    
    def __init__(self):
        self.metrics = {
            "start_time": time.time(),
            "memory_usage": [],
            "cpu_usage": [],
            "execution_times": {}
        }
    
    def start_monitoring(self, operation_name: str):
        """Start monitoring an operation"""
        self.metrics["execution_times"][operation_name] = {
            "start_time": time.time(),
            "memory_start": self._get_memory_usage()
        }
    
    def end_monitoring(self, operation_name: str):
        """End monitoring an operation"""
        if operation_name in self.metrics["execution_times"]:
            operation = self.metrics["execution_times"][operation_name]
            operation["end_time"] = time.time()
            operation["duration"] = operation["end_time"] - operation["start_time"]
            operation["memory_end"] = self._get_memory_usage()
            operation["memory_delta"] = operation["memory_end"] - operation["memory_start"]
    
    def record_system_metrics(self):
        """Record current system metrics"""
        self.metrics["memory_usage"].append(self._get_memory_usage())
        self.metrics["cpu_usage"].append(self._get_cpu_usage())
    
    def _get_memory_usage(self) -> float:
        """Get current memory usage in MB"""
        try:
            process = psutil.Process()
            return process.memory_info().rss / 1024 / 1024
        except Exception:
            return 0.0
    
    def _get_cpu_usage(self) -> float:
        """Get current CPU usage percentage"""
        try:
            return psutil.cpu_percent(interval=0.1)
        except Exception:
            return 0.0
    
    def generate_report(self) -> Dict[str, Any]:
        """Generate performance report"""
        total_time = time.time() - self.metrics["start_time"]
        
        report = {
            "timestamp": datetime.now().isoformat(),
            "total_execution_time": total_time,
            "operations": self.metrics["execution_times"],
            "average_memory_usage": sum(self.metrics["memory_usage"]) / len(self.metrics["memory_usage"]) if self.metrics["memory_usage"] else 0,
            "average_cpu_usage": sum(self.metrics["cpu_usage"]) / len(self.metrics["cpu_usage"]) if self.metrics["cpu_usage"] else 0,
            "peak_memory_usage": max(self.metrics["memory_usage"]) if self.metrics["memory_usage"] else 0
        }
        
        # Save report
        with open("performance_report.json", 'w') as f:
            json.dump(report, f, indent=2, default=str)
        
        return report
    
    def print_summary(self):
        """Print performance summary"""
        report = self.generate_report()
        
        print("📊 PERFORMANCE MONITORING SUMMARY")
        print("=" * 50)
        print(f"Total execution time: {report['total_execution_time']:.2f}s")
        print(f"Average memory usage: {report['average_memory_usage']:.1f}MB")
        print(f"Peak memory usage: {report['peak_memory_usage']:.1f}MB")
        print(f"Average CPU usage: {report['average_cpu_usage']:.1f}%")
        
        if report["operations"]:
            print("\nOperation breakdown:")
            for op_name, op_data in report["operations"].items():
                print(f"  {op_name}: {op_data.get('duration', 0):.2f}s")

# Global monitor instance
monitor = PerformanceMonitor()

def monitor_operation(operation_name: str):
    """Decorator to monitor operation performance"""
    def decorator(func):
        def wrapper(*args, **kwargs):
            monitor.start_monitoring(operation_name)
            try:
                result = func(*args, **kwargs)
                return result
            finally:
                monitor.end_monitoring(operation_name)
        return wrapper
    return decorator

if __name__ == "__main__":
    monitor.print_summary()
