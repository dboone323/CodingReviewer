# automated_fix_applicator API Reference

## Module Overview
Automated Fix Applicator for Priority 3D Optimization

Applies automated fixes for the 28 refactoring opportunities identified
in the Priority 3D analysis, focusing on type annotations, complexity
reduction, and performance improvements.

**File**: `automated_fix_applicator.py`  
**Complexity Score**: 73  
**Classes**: 1  
**Functions**: 1

---

## Classes

### class `AutomatedFixApplicator`

Applies automated fixes for Priority 3D optimization recommendations.

Focuses on safe, automated improvements that can be applied systematically
without breaking existing functionality.

**Methods**:

#### `__init__`

```python
def __init__(self)
```

TODO: Add function description

**Parameters**:
- `self` (Any): TODO: Add parameter description

#### `load_analysis_results`

```python
def load_analysis_results(self) -> Dict[str, Any]
```

Load Priority 3D analysis results

**Parameters**:
- `self` (Any): TODO: Add parameter description

**Returns**: `Dict[str, Any]` - TODO: Add return description

#### `apply_type_annotation_fixes`

```python
def apply_type_annotation_fixes(self) -> int
```

Apply automated type annotation improvements

**Parameters**:
- `self` (Any): TODO: Add parameter description

**Returns**: `int` - TODO: Add return description

#### `_add_basic_type_annotations`

```python
def _add_basic_type_annotations(self, recommendation: Dict[str, Any]) -> bool
```

Add basic type annotations to functions missing them

**Parameters**:
- `self` (Any): TODO: Add parameter description
- `recommendation` (Dict[str, Any]): TODO: Add parameter description

**Returns**: `bool` - TODO: Add return description

#### `_insert_type_annotations`

```python
def _insert_type_annotations(self, content: str, node: ast.FunctionDef) -> str
```

Insert basic type annotations for a function

**Parameters**:
- `self` (Any): TODO: Add parameter description
- `content` (str): TODO: Add parameter description
- `node` (ast.FunctionDef): TODO: Add parameter description

**Returns**: `str` - TODO: Add return description

⚠️ **Complexity**: 13 (consider refactoring)

#### `apply_complexity_reduction_fixes`

```python
def apply_complexity_reduction_fixes(self) -> int
```

Apply automated complexity reduction improvements

**Parameters**:
- `self` (Any): TODO: Add parameter description

**Returns**: `int` - TODO: Add return description

#### `_apply_complexity_fix`

```python
def _apply_complexity_fix(self, recommendation: Dict[str, Any]) -> bool
```

Apply automated complexity reduction where safe

**Parameters**:
- `self` (Any): TODO: Add parameter description
- `recommendation` (Dict[str, Any]): TODO: Add parameter description

**Returns**: `bool` - TODO: Add return description

#### `_consolidate_returns`

```python
def _consolidate_returns(self, content: str, function_name: str) -> str
```

Consolidate multiple return statements where safe

**Parameters**:
- `self` (Any): TODO: Add parameter description
- `content` (str): TODO: Add parameter description
- `function_name` (str): TODO: Add parameter description

**Returns**: `str` - TODO: Add return description

#### `_reduce_nesting`

```python
def _reduce_nesting(self, content: str, function_name: str) -> str
```

Reduce nesting levels using guard clauses

**Parameters**:
- `self` (Any): TODO: Add parameter description
- `content` (str): TODO: Add parameter description
- `function_name` (str): TODO: Add parameter description

**Returns**: `str` - TODO: Add return description

#### `apply_performance_optimizations`

```python
def apply_performance_optimizations(self) -> int
```

Apply automated performance optimizations

**Parameters**:
- `self` (Any): TODO: Add parameter description

**Returns**: `int` - TODO: Add return description

#### `_apply_performance_fix`

```python
def _apply_performance_fix(self, metrics: Dict[str, Any]) -> bool
```

Apply automated performance optimizations

**Parameters**:
- `self` (Any): TODO: Add parameter description
- `metrics` (Dict[str, Any]): TODO: Add parameter description

**Returns**: `bool` - TODO: Add return description

#### `_optimize_string_operations`

```python
def _optimize_string_operations(self, content: str) -> str
```

Optimize string concatenation patterns

**Parameters**:
- `self` (Any): TODO: Add parameter description
- `content` (str): TODO: Add parameter description

**Returns**: `str` - TODO: Add return description

#### `_optimize_list_comprehensions`

```python
def _optimize_list_comprehensions(self, content: str) -> str
```

Optimize nested list comprehensions

**Parameters**:
- `self` (Any): TODO: Add parameter description
- `content` (str): TODO: Add parameter description

**Returns**: `str` - TODO: Add return description

#### `run_automated_fixes`

```python
def run_automated_fixes(self) -> Dict[str, Any]
```

Run all automated fixes and return summary

**Parameters**:
- `self` (Any): TODO: Add parameter description

**Returns**: `Dict[str, Any]` - TODO: Add return description

#### `generate_fix_report`

```python
def generate_fix_report(self)
```

Generate detailed fix application report

**Parameters**:
- `self` (Any): TODO: Add parameter description

---

## Functions

### `main`

```python
def main()
```

Main execution function for automated fix application

## Dependencies

```python
from ast
from json
from logging
from os
from pathlib.Path
from re
from typing.Any
from typing.Dict
from typing.List
from typing.Optional
from typing.Tuple
```

