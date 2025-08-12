# quality_gates_validator API Reference

## Module Overview
Automated Quality Gates Validator
Validates all quality metrics against defined thresholds

**File**: `quality_gates_validator.py`  
**Complexity Score**: 32  
**Classes**: 1  
**Functions**: 0

---

## Classes

### class `QualityGatesValidator`

Validates quality gates for CI/CD pipeline

**Methods**:

#### `__init__`

```python
def __init__(self)
```

TODO: Add function description

**Parameters**:
- `self` (Any): TODO: Add parameter description

#### `validate_all_gates`

```python
def validate_all_gates(self) -> Dict[str, Any]
```

Validate all quality gates

**Parameters**:
- `self` (Any): TODO: Add parameter description

**Returns**: `Dict[str, Any]` - TODO: Add return description

#### `_validate_gate`

```python
def _validate_gate(self, gate: Dict[str, Any]) -> Dict[str, Any]
```

Validate a single quality gate

**Parameters**:
- `self` (Any): TODO: Add parameter description
- `gate` (Dict[str, Any]): TODO: Add parameter description

**Returns**: `Dict[str, Any]` - TODO: Add return description

#### `_get_metric_value`

```python
def _get_metric_value(self, metric: str) -> float
```

Get actual metric value from system

**Parameters**:
- `self` (Any): TODO: Add parameter description
- `metric` (str): TODO: Add parameter description

**Returns**: `float` - TODO: Add return description

#### `_get_test_coverage`

```python
def _get_test_coverage(self) -> float
```

Get test coverage percentage

**Parameters**:
- `self` (Any): TODO: Add parameter description

**Returns**: `float` - TODO: Add return description

#### `_get_debt_score`

```python
def _get_debt_score(self) -> float
```

Get technical debt score

**Parameters**:
- `self` (Any): TODO: Add parameter description

**Returns**: `float` - TODO: Add return description

#### `_get_analysis_time`

```python
def _get_analysis_time(self) -> float
```

Get average analysis time

**Parameters**:
- `self` (Any): TODO: Add parameter description

**Returns**: `float` - TODO: Add return description

#### `_get_error_rate`

```python
def _get_error_rate(self) -> float
```

Get system error rate

**Parameters**:
- `self` (Any): TODO: Add parameter description

**Returns**: `float` - TODO: Add return description

#### `_get_documentation_coverage`

```python
def _get_documentation_coverage(self) -> float
```

Get documentation coverage percentage

**Parameters**:
- `self` (Any): TODO: Add parameter description

**Returns**: `float` - TODO: Add return description

---

## Dependencies

```python
from json
from pathlib.Path
from subprocess
from sys
from typing.Any
from typing.Dict
from typing.List
```

