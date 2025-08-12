# Debugging Guide

## Debug Workflow

### 1. Enable Debug Logging
```python
from enhanced_error_logging import error_logger
import logging

# Set debug level
logging.basicConfig(level=logging.DEBUG)

# Check error logger status
report = error_logger.get_error_report()
print(f"Error logger health: {report['system_health_impact']}")
```

### 2. System Health Check
```python
from final_ai_operations_dashboard import AIOperationsDashboard

dashboard = AIOperationsDashboard()
print(f"System status: {dashboard.system_status}")

# Check individual components
for system in dashboard.system_status.get('active_systems', []):
    print(f"{system}: Operational")
```

### 3. Component-Level Debugging

#### Error Logging System
```python
from enhanced_error_logging import log_info, log_error, ErrorCategory

# Test logging functionality
log_info("Debug", "Testing info logging")
log_error("Debug", "Testing error logging", category=ErrorCategory.SYSTEM_INTEGRATION)

# Check error report
report = error_logger.get_error_report()
print(f"Recent errors: {report['recent_errors_count']}")
```

#### Technical Debt Analyzer
```python
from technical_debt_analyzer import TechnicalDebtAnalyzer

analyzer = TechnicalDebtAnalyzer()
results = analyzer.analyze_codebase()

# Check specific files
for metric in results['file_metrics']:
    if metric['overall_score'] < 30:
        print(f"Low quality file: {metric['file_path']} (score: {metric['overall_score']})")
```

## Common Debugging Scenarios

### Analysis Pipeline Issues

#### Problem: Analysis Components Empty
```python
# Debug analysis components
from final_ai_operations_dashboard import AIOperationsDashboard
dashboard = AIOperationsDashboard()
analysis = await dashboard.run_comprehensive_analysis()

if not analysis['analysis_components']:
    print("No analysis components found")
    # Check individual systems
    print(f"MCP available: {hasattr(dashboard, 'mcp_integration')}")
    print(f"Code reviewer available: {hasattr(dashboard, 'ai_reviewer')}")
```

#### Problem: Integration Failures
```python
# Test individual integrations
from final_ai_operations_dashboard import AIOperationsDashboard
dashboard = AIOperationsDashboard()
try:
    if hasattr(dashboard, 'mcp_integration'):
        mcp_result = await dashboard.mcp_integration.run_comprehensive_analysis()
        print(f"MCP analysis successful: {len(mcp_result.get('code_patterns', []))} patterns")
except Exception as e:
    print(f"MCP integration failed: {e}")
```

### Performance Debugging

#### Memory Usage Analysis
```python
import psutil
import gc

# Check memory before analysis
process = psutil.Process()
memory_before = process.memory_info().rss / 1024 / 1024  # MB

# Run analysis
result = await dashboard.run_comprehensive_analysis()

# Check memory after
memory_after = process.memory_info().rss / 1024 / 1024  # MB
print(f"Memory usage: {memory_before:.1f}MB -> {memory_after:.1f}MB")

# Force garbage collection if needed
gc.collect()
```

#### Timing Analysis
```python
import time
import asyncio

async def timed_analysis():
    start_time = time.time()
    
    result = await dashboard.run_comprehensive_analysis()
    
    end_time = time.time()
    print(f"Analysis completed in {end_time - start_time:.2f} seconds")
    
    return result

# Run timed analysis
result = await timed_analysis()
```

## Debugging Tools

### Log Analysis
```bash
# View recent error logs
tail -f .error_logs/error_events.jsonl

# Search for specific errors
grep "CRITICAL" .error_logs/error_events.jsonl

# Count errors by category
jq '.category' .error_logs/error_events.jsonl | sort | uniq -c
```

### System Monitoring
```python
# Create monitoring script
from enhanced_error_logging import error_logger
import time

def monitor_system():
    while True:
        report = error_logger.get_error_report()
        print(f"Health: {report['system_health_impact']['overall_health_score']}")
        time.sleep(30)  # Check every 30 seconds

# Run monitoring
monitor_system()
```

### Validation Tools
```python
# Run system validation
from final_system_validation import comprehensive_system_validation

validation_results = await comprehensive_system_validation()
print(f"System validation: {validation_results['overall_status']}")

# Check individual test results
for test_name, result in validation_results['test_results'].items():
    status = "✅ PASS" if result['status'] == 'pass' else "❌ FAIL"
    print(f"{test_name}: {status}")
```
