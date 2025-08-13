#!/usr/bin/env python3
"""
Comprehensive Code Quality Fixer
Automatically fixes the most common code quality issues identified in the codebase.

Addresses:
- Bare except clauses
- Missing type annotations
- Deprecated AST usage
- Import organization
- Basic code quality improvements
"""

import ast
import os
import re
import sys
from pathlib import Path
from typing import Dict, List, Set, Optional, Tuple, Any
import json
from dataclasses import dataclass

@dataclass
class FixResult:
    """Result of applying a fix to a file"""
    file_path: str
    fixes_applied: List[str]
    errors_fixed: int
    success: bool
    message: str

class CodeQualityFixer:
    """Comprehensive code quality fixer for Python files"""
    
    def __init__(self, workspace_root: str):
        self.workspace_root = Path(workspace_root)
        self.fixes_applied = []
        self.errors_encountered = []
        
    def fix_bare_except_clauses(self, content: str, file_path: str) -> Tuple[str, List[str]]:
        """Replace bare except clauses with specific exception types"""
        fixes = []
        lines = content.split('\n')
        
        for i, line in enumerate(lines):
            # Look for bare except clauses
            if re.search(r'^\s*except\s*:\s*$', line):
                # Replace with generic Exception
                indent = re.match(r'^(\s*)', line).group(1)
                lines[i] = f"{indent}except Exception:"
                fixes.append(f"Line {i+1}: Replaced bare except with Exception")
                
            elif re.search(r'^\s*except\s*:\s*#', line):
                # Handle except with comment
                indent = re.match(r'^(\s*)', line).group(1)
                comment_part = line.split('#', 1)[1]
                lines[i] = f"{indent}except Exception:  #{comment_part}"
                fixes.append(f"Line {i+1}: Replaced bare except with Exception (preserved comment)")
        
        return '\n'.join(lines), fixes
    
    def fix_deprecated_ast_usage(self, content: str, file_path: str) -> Tuple[str, List[str]]:
        """Replace deprecated ast.Str with ast.Constant"""
        fixes = []
        
        # Replace ast.Str with ast.Constant
        if 'ast.Str' in content:
            content = content.replace('ast.Str', 'ast.Constant')
            fixes.append("Replaced deprecated ast.Str with ast.Constant")
            
        return content, fixes
    
    def add_basic_type_annotations(self, content: str, file_path: str) -> Tuple[str, List[str]]:
        """Add basic type annotations to function definitions"""
        fixes = []
        lines = content.split('\n')
        
        # Look for function definitions without type annotations
        for i, line in enumerate(lines):
            # Match function definitions without return type annotation
            func_match = re.match(r'^(\s*def\s+\w+\s*\([^)]*\))\s*:\s*$', line)
            if func_match:
                # Simple heuristic: if function name suggests it returns bool/str/int
                func_def = func_match.group(1)
                func_name = re.search(r'def\s+(\w+)', line).group(1)
                
                if any(keyword in func_name.lower() for keyword in ['is_', 'has_', 'can_', 'should_']):
                    lines[i] = f"{func_def} -> bool:"
                    fixes.append(f"Line {i+1}: Added bool return type to {func_name}")
                elif 'count' in func_name.lower() or func_name.endswith('_size'):
                    lines[i] = f"{func_def} -> int:"
                    fixes.append(f"Line {i+1}: Added int return type to {func_name}")
                elif any(keyword in func_name.lower() for keyword in ['get_', 'format_', 'generate_']):
                    lines[i] = f"{func_def} -> str:"
                    fixes.append(f"Line {i+1}: Added str return type to {func_name}")
                    
        return '\n'.join(lines), fixes
    
    def fix_common_typing_imports(self, content: str, file_path: str) -> Tuple[str, List[str]]:
        """Add missing typing imports and fix common typing issues"""
        fixes = []
        lines = content.split('\n')
        
        # Check if typing imports are needed
        needs_typing = any(
            pattern in content for pattern in [
                'List[', 'Dict[', 'Optional[', 'Tuple[', 'Set[', 'Any', 'Union['
            ]
        )
        
        if needs_typing:
            # Find existing typing import
            typing_import_line = None
            for i, line in enumerate(lines):
                if line.strip().startswith('from typing import'):
                    typing_import_line = i
                    break
                    
            if typing_import_line is None:
                # Add typing import after other imports
                import_end = 0
                for i, line in enumerate(lines):
                    if line.strip().startswith('import ') or line.strip().startswith('from '):
                        import_end = i + 1
                        
                if import_end > 0:
                    lines.insert(import_end, 'from typing import Dict, List, Optional, Any, Tuple, Set, Union')
                    fixes.append("Added missing typing imports")
                    
        return '\n'.join(lines), fixes
    
    def apply_fixes_to_file(self, file_path: Path) -> FixResult:
        """Apply all fixes to a single file"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                original_content = f.read()
                
            content = original_content
            all_fixes = []
            
            # Apply each fix category
            content, fixes1 = self.fix_bare_except_clauses(content, str(file_path))
            all_fixes.extend(fixes1)
            
            content, fixes2 = self.fix_deprecated_ast_usage(content, str(file_path))
            all_fixes.extend(fixes2)
            
            content, fixes3 = self.add_basic_type_annotations(content, str(file_path))
            all_fixes.extend(fixes3)
            
            content, fixes4 = self.fix_common_typing_imports(content, str(file_path))
            all_fixes.extend(fixes4)
            
            # Only write if changes were made
            if content != original_content:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                    
                return FixResult(
                    file_path=str(file_path),
                    fixes_applied=all_fixes,
                    errors_fixed=len(all_fixes),
                    success=True,
                    message=f"Successfully applied {len(all_fixes)} fixes"
                )
            else:
                return FixResult(
                    file_path=str(file_path),
                    fixes_applied=[],
                    errors_fixed=0,
                    success=True,
                    message="No fixes needed"
                )
                
        except Exception as e:
            return FixResult(
                file_path=str(file_path),
                fixes_applied=[],
                errors_fixed=0,
                success=False,
                message=f"Error processing file: {str(e)}"
            )
    
    def fix_high_priority_files(self) -> Dict[str, Any]:
        """Fix the files with the most critical issues first"""
        
        # High priority files based on error analysis
        high_priority_files = [
            "quality_gates_validator.py",
            "performance_monitor.py", 
            "technical_debt_analyzer.py",
            "advanced_refactoring_optimizer.py",
            "python_src/testing_framework.py",
            "ai_operations_dashboard.py"
        ]
        
        results = []
        total_fixes = 0
        
        print("🔧 Starting Comprehensive Code Quality Fixes")
        print("=" * 60)
        
        for file_name in high_priority_files:
            file_path = self.workspace_root / file_name
            if file_path.exists():
                print(f"Processing: {file_name}")
                result = self.apply_fixes_to_file(file_path)
                results.append(result)
                
                if result.success and result.errors_fixed > 0:
                    print(f"  ✅ Fixed {result.errors_fixed} issues")
                    for fix in result.fixes_applied:
                        print(f"    • {fix}")
                    total_fixes += result.errors_fixed
                elif result.success:
                    print(f"  ℹ️  {result.message}")
                else:
                    print(f"  ❌ {result.message}")
                    
                print()
            else:
                print(f"  ⚠️  File not found: {file_name}")
                
        print("=" * 60)
        print(f"🎉 Completed! Total fixes applied: {total_fixes}")
        
        return {
            "total_files_processed": len(results),
            "total_fixes_applied": total_fixes,
            "successful_files": len([r for r in results if r.success]),
            "results": results
        }

def main():
    """Main execution function"""
    workspace_root = "/Users/danielstevens/Desktop/CodingReviewer"
    
    fixer = CodeQualityFixer(workspace_root)
    results = fixer.fix_high_priority_files()
    
    # Save results for analysis
    results_file = Path(workspace_root) / "code_quality_fixes_report.json"
    with open(results_file, 'w') as f:
        # Convert FixResult objects to dicts for JSON serialization
        json_results = results.copy()
        json_results["results"] = [
            {
                "file_path": r.file_path,
                "fixes_applied": r.fixes_applied,
                "errors_fixed": r.errors_fixed,
                "success": r.success,
                "message": r.message
            }
            for r in results["results"]
        ]
        json.dump(json_results, f, indent=2)
    
    print(f"\n📄 Results saved to: {results_file}")
    
    return results

if __name__ == "__main__":
    main()
