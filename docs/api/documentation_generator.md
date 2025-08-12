# documentation_generator API Reference

## Module Overview
Priority 3A - Automated Documentation Generator
Transforms TODO placeholders into comprehensive documentation

**File**: `documentation_generator.py`  
**Complexity Score**: 78  
**Classes**: 4  
**Functions**: 1

---

## Classes

### class `FunctionInfo`

Information about a function for documentation

---

### class `ClassInfo`

Information about a class for documentation

---

### class `ModuleInfo`

Information about a module for documentation

---

### class `DocumentationGenerator`

Generates comprehensive documentation from code analysis

**Methods**:

#### `__init__`

```python
def __init__(self, workspace_path: str)
```

TODO: Add function description

**Parameters**:
- `self` (Any): TODO: Add parameter description
- `workspace_path` (str): TODO: Add parameter description

#### `generate_comprehensive_documentation`

```python
def generate_comprehensive_documentation(self) -> Dict[str, Any]
```

Generate complete documentation suite

**Parameters**:
- `self` (Any): TODO: Add parameter description

**Returns**: `Dict[str, Any]` - TODO: Add return description

#### `_analyze_codebase`

```python
def _analyze_codebase(self)
```

Analyze Python files to extract documentation information

**Parameters**:
- `self` (Any): TODO: Add parameter description

#### `_analyze_module`

```python
def _analyze_module(self, file_path: Path) -> Optional[ModuleInfo]
```

Analyze a single Python module

**Parameters**:
- `self` (Any): TODO: Add parameter description
- `file_path` (Path): TODO: Add parameter description

**Returns**: `Optional[ModuleInfo]` - TODO: Add return description

#### `_analyze_class`

```python
def _analyze_class(self, node: ast.ClassDef) -> ClassInfo
```

Analyze a class definition

**Parameters**:
- `self` (Any): TODO: Add parameter description
- `node` (ast.ClassDef): TODO: Add parameter description

**Returns**: `ClassInfo` - TODO: Add return description

#### `_analyze_function`

```python
def _analyze_function(self, node: ast.FunctionDef | ast.AsyncFunctionDef, class_name: Optional[str]) -> FunctionInfo
```

Analyze a function definition

**Parameters**:
- `self` (Any): TODO: Add parameter description
- `node` (ast.FunctionDef | ast.AsyncFunctionDef): TODO: Add parameter description
- `class_name` (Optional[str]): TODO: Add parameter description

**Returns**: `FunctionInfo` - TODO: Add return description

#### `_extract_import_info`

```python
def _extract_import_info(self, node: ast.Import | ast.ImportFrom) -> List[str]
```

Extract import information

**Parameters**:
- `self` (Any): TODO: Add parameter description
- `node` (ast.Import | ast.ImportFrom): TODO: Add parameter description

**Returns**: `List[str]` - TODO: Add return description

#### `_calculate_module_complexity`

```python
def _calculate_module_complexity(self, tree: ast.AST) -> int
```

Calculate overall module complexity

**Parameters**:
- `self` (Any): TODO: Add parameter description
- `tree` (ast.AST): TODO: Add parameter description

**Returns**: `int` - TODO: Add return description

#### `_calculate_function_complexity`

```python
def _calculate_function_complexity(self, func_node: ast.AST) -> int
```

Calculate function complexity

**Parameters**:
- `self` (Any): TODO: Add parameter description
- `func_node` (ast.AST): TODO: Add parameter description

**Returns**: `int` - TODO: Add return description

#### `_generate_api_documentation`

```python
def _generate_api_documentation(self)
```

Generate comprehensive API reference documentation

**Parameters**:
- `self` (Any): TODO: Add parameter description

#### `_generate_module_api_doc`

```python
def _generate_module_api_doc(self, module: ModuleInfo, docs_dir: Path)
```

Generate API documentation for a single module

**Parameters**:
- `self` (Any): TODO: Add parameter description
- `module` (ModuleInfo): TODO: Add parameter description
- `docs_dir` (Path): TODO: Add parameter description

#### `_format_class_documentation`

```python
def _format_class_documentation(self, class_info: ClassInfo) -> str
```

Format class documentation

**Parameters**:
- `self` (Any): TODO: Add parameter description
- `class_info` (ClassInfo): TODO: Add parameter description

**Returns**: `str` - TODO: Add return description

#### `_format_function_documentation`

```python
def _format_function_documentation(self, func_info: FunctionInfo, is_method: bool) -> str
```

Format function documentation

**Parameters**:
- `self` (Any): TODO: Add parameter description
- `func_info` (FunctionInfo): TODO: Add parameter description
- `is_method` (bool): TODO: Add parameter description

**Returns**: `str` - TODO: Add return description

#### `_generate_api_index`

```python
def _generate_api_index(self, docs_dir: Path)
```

Generate API documentation index

**Parameters**:
- `self` (Any): TODO: Add parameter description
- `docs_dir` (Path): TODO: Add parameter description

#### `_generate_user_guides`

```python
def _generate_user_guides(self)
```

Generate comprehensive user guides

**Parameters**:
- `self` (Any): TODO: Add parameter description

#### `_create_getting_started_guide`

```python
def _create_getting_started_guide(self, guides_dir: Path)
```

Create getting started guide

**Parameters**:
- `self` (Any): TODO: Add parameter description
- `guides_dir` (Path): TODO: Add parameter description

#### `_create_feature_guides`

```python
def _create_feature_guides(self, guides_dir: Path)
```

Create feature-specific guides

**Parameters**:
- `self` (Any): TODO: Add parameter description
- `guides_dir` (Path): TODO: Add parameter description

#### `_create_configuration_guide`

```python
def _create_configuration_guide(self, guides_dir: Path)
```

Create configuration guide

**Parameters**:
- `self` (Any): TODO: Add parameter description
- `guides_dir` (Path): TODO: Add parameter description

#### `_generate_developer_guides`

```python
def _generate_developer_guides(self)
```

Generate developer guides

**Parameters**:
- `self` (Any): TODO: Add parameter description

#### `_create_contribution_guide`

```python
def _create_contribution_guide(self, dev_dir: Path)
```

Create contribution guide

**Parameters**:
- `self` (Any): TODO: Add parameter description
- `dev_dir` (Path): TODO: Add parameter description

#### `_create_extension_guide`

```python
def _create_extension_guide(self, dev_dir: Path)
```

Create extension guide

**Parameters**:
- `self` (Any): TODO: Add parameter description
- `dev_dir` (Path): TODO: Add parameter description

#### `_create_architecture_overview`

```python
def _create_architecture_overview(self, dev_dir: Path)
```

Create architecture overview

**Parameters**:
- `self` (Any): TODO: Add parameter description
- `dev_dir` (Path): TODO: Add parameter description

#### `_generate_architecture_documentation`

```python
def _generate_architecture_documentation(self)
```

Generate detailed architecture documentation

**Parameters**:
- `self` (Any): TODO: Add parameter description

#### `_create_component_diagrams`

```python
def _create_component_diagrams(self, arch_dir: Path)
```

Create component interaction diagrams

**Parameters**:
- `self` (Any): TODO: Add parameter description
- `arch_dir` (Path): TODO: Add parameter description

#### `_create_system_design_docs`

```python
def _create_system_design_docs(self, arch_dir: Path)
```

Create system design documentation

**Parameters**:
- `self` (Any): TODO: Add parameter description
- `arch_dir` (Path): TODO: Add parameter description

#### `_generate_troubleshooting_guides`

```python
def _generate_troubleshooting_guides(self)
```

Generate troubleshooting guides

**Parameters**:
- `self` (Any): TODO: Add parameter description

#### `_create_common_issues_guide`

```python
def _create_common_issues_guide(self, trouble_dir: Path)
```

Create common issues troubleshooting guide

**Parameters**:
- `self` (Any): TODO: Add parameter description
- `trouble_dir` (Path): TODO: Add parameter description

#### `_create_debugging_guide`

```python
def _create_debugging_guide(self, trouble_dir: Path)
```

Create debugging guide

**Parameters**:
- `self` (Any): TODO: Add parameter description
- `trouble_dir` (Path): TODO: Add parameter description

#### `_create_performance_guide`

```python
def _create_performance_guide(self, trouble_dir: Path)
```

Create performance troubleshooting guide

**Parameters**:
- `self` (Any): TODO: Add parameter description
- `trouble_dir` (Path): TODO: Add parameter description

#### `_create_documentation_index`

```python
def _create_documentation_index(self)
```

Create master documentation index

**Parameters**:
- `self` (Any): TODO: Add parameter description

#### `_count_documentation_files`

```python
def _count_documentation_files(self) -> int
```

Count generated documentation files

**Parameters**:
- `self` (Any): TODO: Add parameter description

**Returns**: `int` - TODO: Add return description

#### `_calculate_documentation_coverage`

```python
def _calculate_documentation_coverage(self) -> Dict[str, float]
```

Calculate documentation coverage statistics

**Parameters**:
- `self` (Any): TODO: Add parameter description

**Returns**: `Dict[str, float]` - TODO: Add return description

⚠️ **Complexity**: 11 (consider refactoring)

---

## Functions

### `main`

```python
def main()
```

Main execution for documentation generation

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
```

