# Performance Troubleshooting Guide

## Performance Monitoring

### Built-in Performance Metrics
```python
from final_ai_operations_dashboard import AIOperationsDashboard
import time

dashboard = AIOperationsDashboard()

# Measure analysis performance
start_time = time.time()
result = await dashboard.run_comprehensive_analysis()
analysis_time = time.time() - start_time

print(f"Analysis completed in {analysis_time:.2f} seconds")
print(f"Components analyzed: {len(result.get('analysis_components', {}))}")
```

## Performance Optimization

### Memory Optimization
```python
import gc
import sys

# Monitor memory usage
def get_memory_usage():
    return sys.getsizeof(gc.get_objects())

# Optimize analysis for large codebases
def optimized_analysis():
    # Process files in batches
    files = list(Path(".").glob("*.py"))
    batch_size = 10
    
    for i in range(0, len(files), batch_size):
        batch = files[i:i+batch_size]
        # Process batch
        gc.collect()  # Clean up after each batch
```

### Analysis Performance
```python
# Exclude large files from analysis
def filter_analysis_files():
    max_file_size = 1024 * 1024  # 1MB
    
    for file_path in Path(".").glob("*.py"):
        if file_path.stat().st_size < max_file_size:
            yield file_path

# Use filtered file list
filtered_files = list(filter_analysis_files())
```

### Async Optimization
```python
import asyncio

# Parallel analysis for independent components
async def parallel_analysis():
    dashboard = AIOperationsDashboard()
    
    # Run multiple analyses concurrently
    tasks = []
    
    if hasattr(dashboard, 'mcp_integration'):
        tasks.append(dashboard.mcp_integration.run_comprehensive_analysis())
    
    if hasattr(dashboard, 'ai_reviewer'):
        tasks.append(dashboard.ai_reviewer.review_file_for_dashboard("./"))
    
    # Wait for all tasks to complete
    results = await asyncio.gather(*tasks, return_exceptions=True)
    
    return results
```

## Performance Benchmarks

### Expected Performance
- **Small codebase** (<20 files): <30 seconds
- **Medium codebase** (20-100 files): 1-3 minutes  
- **Large codebase** (>100 files): 3-10 minutes

### Performance Thresholds
```python
# Set performance alerts
def check_performance_thresholds(analysis_time: float, file_count: int):
    expected_time = file_count * 0.5  # 0.5 seconds per file
    
    if analysis_time > expected_time * 2:
        print(f"⚠️ Performance warning: Analysis took {analysis_time:.1f}s for {file_count} files")
        print(f"Expected: ~{expected_time:.1f}s")
    
    return analysis_time <= expected_time * 2
```

## Resource Management

### Memory Management
```python
# Monitor memory during analysis
import psutil

def memory_aware_analysis():
    process = psutil.Process()
    
    while True:
        memory_percent = process.memory_percent()
        
        if memory_percent > 80:  # 80% memory usage
            print("High memory usage detected - pausing analysis")
            gc.collect()
            time.sleep(1)
        else:
            break
```

### CPU Optimization
```python
# CPU usage monitoring
def cpu_aware_processing():
    cpu_percent = psutil.cpu_percent(interval=1)
    
    if cpu_percent > 90:
        print("High CPU usage - reducing analysis intensity")
        # Implement throttling logic
        time.sleep(0.1)
```

## Troubleshooting Slow Performance

### Identify Bottlenecks
```python
import cProfile
import pstats

# Profile analysis performance
def profile_analysis():
    profiler = cProfile.Profile()
    profiler.enable()
    
    # Run analysis
    dashboard = AIOperationsDashboard()
    result = await dashboard.run_comprehensive_analysis()
    
    profiler.disable()
    
    # Print performance stats
    stats = pstats.Stats(profiler)
    stats.sort_stats('cumulative')
    stats.print_stats(10)  # Top 10 slowest functions
```

### File System Optimization
```bash
# Check disk I/O performance
iostat -x 1 5

# Monitor file access patterns
sudo fs_usage -w -f filesystem python
```

### Network Optimization
```python
# Optimize for network-dependent operations
import asyncio
import aiohttp

async def optimized_network_operations():
    # Use connection pooling
    connector = aiohttp.TCPConnector(limit=10)
    async with aiohttp.ClientSession(connector=connector) as session:
        # Your network operations here
        pass
```

## Performance Monitoring Dashboard

### Real-time Metrics
```python
# Performance monitoring integration
class PerformanceMonitor:
    def __init__(self):
        self.metrics = {
            'analysis_times': [],
            'memory_usage': [],
            'error_rates': []
        }
    
    def record_analysis_time(self, duration: float):
        self.metrics['analysis_times'].append(duration)
        
        # Alert on performance degradation
        if len(self.metrics['analysis_times']) > 10:
            avg_time = sum(self.metrics['analysis_times'][-10:]) / 10
            if avg_time > 60:  # More than 1 minute average
                print(f"⚠️ Performance alert: Average analysis time {avg_time:.1f}s")
```
