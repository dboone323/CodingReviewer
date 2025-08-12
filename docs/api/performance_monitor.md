# performance_monitor API Reference

## Module Overview
Performance Monitoring for Workflows
Monitors and reports on workflow performance metrics

**File**: `performance_monitor.py`  
**Complexity Score**: 10  
**Classes**: 1  
**Functions**: 1

---

## Classes

### class `PerformanceMonitor`

Monitors workflow performance

**Methods**:

#### `__init__`

```python
def __init__(self)
```

TODO: Add function description

**Parameters**:
- `self` (Any): TODO: Add parameter description

#### `start_monitoring`

```python
def start_monitoring(self, operation_name: str)
```

Start monitoring an operation

**Parameters**:
- `self` (Any): TODO: Add parameter description
- `operation_name` (str): TODO: Add parameter description

#### `end_monitoring`

```python
def end_monitoring(self, operation_name: str)
```

End monitoring an operation

**Parameters**:
- `self` (Any): TODO: Add parameter description
- `operation_name` (str): TODO: Add parameter description

#### `record_system_metrics`

```python
def record_system_metrics(self)
```

Record current system metrics

**Parameters**:
- `self` (Any): TODO: Add parameter description

#### `_get_memory_usage`

```python
def _get_memory_usage(self) -> float
```

Get current memory usage in MB

**Parameters**:
- `self` (Any): TODO: Add parameter description

**Returns**: `float` - TODO: Add return description

#### `_get_cpu_usage`

```python
def _get_cpu_usage(self) -> float
```

Get current CPU usage percentage

**Parameters**:
- `self` (Any): TODO: Add parameter description

**Returns**: `float` - TODO: Add return description

#### `generate_report`

```python
def generate_report(self) -> Dict[str, Any]
```

Generate performance report

**Parameters**:
- `self` (Any): TODO: Add parameter description

**Returns**: `Dict[str, Any]` - TODO: Add return description

#### `print_summary`

```python
def print_summary(self)
```

Print performance summary

**Parameters**:
- `self` (Any): TODO: Add parameter description

---

## Functions

### `monitor_operation`

```python
def monitor_operation(operation_name: str)
```

Decorator to monitor operation performance

**Parameters**:
- `operation_name` (str): TODO: Add parameter description

## Dependencies

```python
from datetime.datetime
from json
from pathlib.Path
from psutil
from time
from typing.Any
from typing.Dict
```

