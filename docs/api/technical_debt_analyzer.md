# technical_debt_analyzer API Reference

## Module Overview
Technical Debt Analyzer - Priority 2 Implementation
Analyzes code quality and provides automated improvements

**File**: `technical_debt_analyzer.py`  
**Complexity Score**: 64  
**Classes**: 3  
**Functions**: 1

---

## Classes

### class `TechnicalDebtIssue`

Represents a technical debt issue

---

### class `CodeQualityMetrics`

Code quality metrics for a file

---

### class `TechnicalDebtAnalyzer`

Analyzes and reports technical debt across the codebase

**Methods**:

#### `__init__`

```python
def __init__(self, workspace_path: str)
```

TODO: Add function description

**Parameters**:
- `self` (Any): TODO: Add parameter description
- `workspace_path` (str): TODO: Add parameter description

#### `analyze_codebase`

```python
def analyze_codebase(self) -> Dict[str, Any]
```

Run comprehensive technical debt analysis

**Parameters**:
- `self` (Any): TODO: Add parameter description

**Returns**: `Dict[str, Any]` - TODO: Add return description

#### `_analyze_file`

```python
def _analyze_file(self, file_path: Path) -> Optional[CodeQualityMetrics]
```

Analyze a single Python file for technical debt

**Parameters**:
- `self` (Any): TODO: Add parameter description
- `file_path` (Path): TODO: Add parameter description

**Returns**: `Optional[CodeQualityMetrics]` - TODO: Add return description

#### `_calculate_complexity`

```python
def _calculate_complexity(self, tree: ast.AST) -> int
```

Calculate cyclomatic complexity

**Parameters**:
- `self` (Any): TODO: Add parameter description
- `tree` (ast.AST): TODO: Add parameter description

**Returns**: `int` - TODO: Add return description

#### `_find_duplicate_code`

```python
def _find_duplicate_code(self, content: str) -> List[str]
```

Find potential duplicate code blocks

**Parameters**:
- `self` (Any): TODO: Add parameter description
- `content` (str): TODO: Add parameter description

**Returns**: `List[str]` - TODO: Add return description

#### `_check_type_annotations`

```python
def _check_type_annotations(self, tree: ast.AST) -> float
```

Check type annotation coverage

**Parameters**:
- `self` (Any): TODO: Add parameter description
- `tree` (ast.AST): TODO: Add parameter description

**Returns**: `float` - TODO: Add return description

#### `_assess_error_handling`

```python
def _assess_error_handling(self, tree: ast.AST) -> float
```

Assess error handling quality

**Parameters**:
- `self` (Any): TODO: Add parameter description
- `tree` (ast.AST): TODO: Add parameter description

**Returns**: `float` - TODO: Add return description

#### `_assess_documentation`

```python
def _assess_documentation(self, tree: ast.AST) -> float
```

Assess documentation quality

**Parameters**:
- `self` (Any): TODO: Add parameter description
- `tree` (ast.AST): TODO: Add parameter description

**Returns**: `float` - TODO: Add return description

#### `_calculate_file_score`

```python
def _calculate_file_score(self, complexity: int, type_coverage: float, error_handling: float, documentation: float) -> float
```

Calculate overall file quality score

**Parameters**:
- `self` (Any): TODO: Add parameter description
- `complexity` (int): TODO: Add parameter description
- `type_coverage` (float): TODO: Add parameter description
- `error_handling` (float): TODO: Add parameter description
- `documentation` (float): TODO: Add parameter description

**Returns**: `float` - TODO: Add return description

#### `_generate_file_issues`

```python
def _generate_file_issues(self, file_path: Path, tree: ast.AST, content: str, complexity: int, type_coverage: float)
```

Generate specific issues for a file

**Parameters**:
- `self` (Any): TODO: Add parameter description
- `file_path` (Path): TODO: Add parameter description
- `tree` (ast.AST): TODO: Add parameter description
- `content` (str): TODO: Add parameter description
- `complexity` (int): TODO: Add parameter description
- `type_coverage` (float): TODO: Add parameter description

#### `_calculate_overall_metrics`

```python
def _calculate_overall_metrics(self) -> Dict[str, Any]
```

Calculate overall codebase metrics

**Parameters**:
- `self` (Any): TODO: Add parameter description

**Returns**: `Dict[str, Any]` - TODO: Add return description

#### `_generate_recommendations`

```python
def _generate_recommendations(self) -> List[Dict[str, Any]]
```

Generate improvement recommendations

**Parameters**:
- `self` (Any): TODO: Add parameter description

**Returns**: `List[Dict[str, Any]]` - TODO: Add return description

#### `_identify_quick_wins`

```python
def _identify_quick_wins(self) -> List[Dict[str, Any]]
```

Identify quick wins for immediate improvement

**Parameters**:
- `self` (Any): TODO: Add parameter description

**Returns**: `List[Dict[str, Any]]` - TODO: Add return description

#### `generate_report`

```python
def generate_report(self, output_file: str) -> str
```

Generate and save detailed technical debt report

**Parameters**:
- `self` (Any): TODO: Add parameter description
- `output_file` (str): TODO: Add parameter description

**Returns**: `str` - TODO: Add return description

---

## Functions

### `main`

```python
def main() -> Any
```

Main execution for technical debt analysis

**Returns**: `Any` - TODO: Add return description

## Dependencies

```python
from ast
from dataclasses.dataclass
from datetime.datetime
from enhanced_error_logging.ErrorCategory
from enhanced_error_logging.log_error
from enhanced_error_logging.log_info
from enhanced_error_logging.log_warning
from json
from os
from pathlib.Path
from re
from typing.Any
from typing.Dict
from typing.List
from typing.Optional
from typing.Tuple
```

