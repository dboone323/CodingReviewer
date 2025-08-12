#!/usr/bin/env python3
"""
Advanced Type Annotation and Import Fixer
Fixes the remaining type annotation issues and import problems
"""

import ast
import re
from pathlib import Path
from typing import Dict, List, Tuple, Set, Any, Optional

class AdvancedTypeFixer:
    """Advanced fixer for type annotations and import issues"""
    
    def __init__(self, workspace_root: str):
        self.workspace_root = Path(workspace_root)
        
    def fix_enhanced_error_logging_types(self, content: str) -> Tuple[str, List[str]]:
        """Fix issues with enhanced_error_logging module"""
        fixes = []
        
        # Replace AI_PROCESSING with SYSTEM_INTEGRATION
        if "ErrorCategory.AI_PROCESSING" in content:
            content = content.replace("ErrorCategory.AI_PROCESSING", "ErrorCategory.SYSTEM_INTEGRATION")
            fixes.append("Replaced ErrorCategory.AI_PROCESSING with SYSTEM_INTEGRATION")
            
        return content, fixes
    
    def add_type_annotations_to_functions(self, content: str) -> Tuple[str, List[str]]:
        """Add comprehensive type annotations"""
        fixes = []
        lines = content.split('\n')
        
        # Add return type annotations for common patterns
        for i, line in enumerate(lines):
            # Functions that return Dict[str, Any]
            if re.match(r'^\s*def\s+.*_results?\s*\([^)]*\)\s*:\s*$', line):
                lines[i] = line.replace(':', ' -> Dict[str, Any]:')
                fixes.append(f"Line {i+1}: Added Dict[str, Any] return type")
                
            # Functions that return List[str]  
            elif re.match(r'^\s*def\s+.*(_duplicates|_issues|_patterns)\s*\([^)]*\)\s*:\s*$', line):
                lines[i] = line.replace(':', ' -> List[str]:')
                fixes.append(f"Line {i+1}: Added List[str] return type")
                
            # Functions that return List[Dict[str, Any]]
            elif re.match(r'^\s*def\s+.*(_recommendations|_quick_wins)\s*\([^)]*\)\s*:\s*$', line):
                lines[i] = line.replace(':', ' -> List[Dict[str, Any]]:')
                fixes.append(f"Line {i+1}: Added List[Dict[str, Any]] return type")
                
        return '\n'.join(lines), fixes
    
    def add_typing_imports(self, content: str) -> Tuple[str, List[str]]:
        """Add comprehensive typing imports"""
        fixes = []
        
        # Check what typing imports are needed
        needed_types = set()
        
        if 'Dict[' in content or 'dict[' in content:
            needed_types.add('Dict')
        if 'List[' in content or 'list[' in content:
            needed_types.add('List')
        if 'Optional[' in content:
            needed_types.add('Optional')
        if 'Any' in content:
            needed_types.add('Any')
        if 'Tuple[' in content:
            needed_types.add('Tuple')
        if 'Set[' in content:
            needed_types.add('Set')
        if 'Union[' in content:
            needed_types.add('Union')
            
        if needed_types:
            lines = content.split('\n')
            
            # Find existing typing import line
            typing_line_idx = None
            for i, line in enumerate(lines):
                if 'from typing import' in line:
                    typing_line_idx = i
                    break
                    
            if typing_line_idx is not None:
                # Update existing typing import
                existing_imports = set()
                match = re.search(r'from typing import (.+)', lines[typing_line_idx])
                if match:
                    existing_imports = {imp.strip() for imp in match.group(1).split(',')}
                    
                all_imports = existing_imports.union(needed_types)
                new_import_line = f"from typing import {', '.join(sorted(all_imports))}"
                lines[typing_line_idx] = new_import_line
                fixes.append(f"Updated typing imports: {', '.join(sorted(needed_types - existing_imports))}")
            else:
                # Add new typing import after other imports
                import_end = 0
                for i, line in enumerate(lines):
                    if line.strip().startswith('import ') or line.strip().startswith('from '):
                        import_end = i + 1
                        
                new_import_line = f"from typing import {', '.join(sorted(needed_types))}"
                lines.insert(import_end, new_import_line)
                fixes.append(f"Added typing imports: {', '.join(sorted(needed_types))}")
                
            content = '\n'.join(lines)
            
        return content, fixes
    
    def fix_ast_str_issues(self, content: str) -> Tuple[str, List[str]]:
        """Fix remaining ast.Str issues that weren't caught before"""
        fixes = []
        
        # More comprehensive ast.Str replacement
        patterns = [
            (r'isinstance\([^,]+,\s*ast\.Str\)', lambda m: m.group(0).replace('ast.Str', 'ast.Constant')),
            (r'ast\.Str\b', 'ast.Constant'),
        ]
        
        for pattern, replacement in patterns:
            if isinstance(replacement, str):
                if re.search(pattern, content):
                    content = re.sub(pattern, replacement, content)
                    fixes.append(f"Replaced ast.Str pattern: {pattern}")
            else:
                content = re.sub(pattern, replacement, content)
                if re.search(pattern, content):
                    fixes.append(f"Fixed ast.Str isinstance pattern")
                    
        return content, fixes
    
    def fix_dict_type_annotations(self, content: str) -> Tuple[str, List[str]]:
        """Fix dict type annotation issues"""
        fixes = []
        lines = content.split('\n')
        
        for i, line in enumerate(lines):
            # Add type annotations to dict assignments
            if re.match(r'^\s*\w+\s*=\s*\{\s*$', line):
                var_name = re.match(r'^\s*(\w+)', line).group(1)
                if any(hint in var_name.lower() for hint in ['result', 'analysis', 'pattern', 'metric']):
                    # Look ahead to see if we can infer the type
                    next_lines = lines[i+1:i+5] if i+1 < len(lines) else []
                    if any('"' in nl and ':' in nl for nl in next_lines):
                        lines[i] = line.replace(' = {', ': Dict[str, Any] = {')
                        fixes.append(f"Line {i+1}: Added Dict[str, Any] type annotation")
                        
        return '\n'.join(lines), fixes
    
    def apply_advanced_fixes(self, file_path: Path) -> Dict[str, Any]:
        """Apply all advanced fixes to a file"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                original_content = f.read()
                
            content = original_content
            all_fixes = []
            
            # Apply fixes in order
            content, fixes1 = self.fix_enhanced_error_logging_types(content)
            all_fixes.extend(fixes1)
            
            content, fixes2 = self.add_typing_imports(content)
            all_fixes.extend(fixes2)
            
            content, fixes3 = self.add_type_annotations_to_functions(content)
            all_fixes.extend(fixes3)
            
            content, fixes4 = self.fix_ast_str_issues(content)
            all_fixes.extend(fixes4)
            
            content, fixes5 = self.fix_dict_type_annotations(content)
            all_fixes.extend(fixes5)
            
            # Write changes if any
            if content != original_content:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                    
            return {
                "file_path": str(file_path),
                "fixes_applied": all_fixes,
                "success": True,
                "changes_made": content != original_content
            }
            
        except Exception as e:
            return {
                "file_path": str(file_path),
                "fixes_applied": [],
                "success": False,
                "error": str(e)
            }
    
    def fix_remaining_issues(self) -> Dict[str, Any]:
        """Fix remaining issues in priority files"""
        
        # Files that still have type annotation issues
        target_files = [
            "technical_debt_analyzer.py",
            "advanced_refactoring_optimizer.py", 
            "ai_operations_dashboard.py",
            "python_src/testing_framework.py",
            "automated_debt_fixer.py",
            "ai_code_review_automation.py"
        ]
        
        results = []
        total_fixes = 0
        
        print("🔧 Advanced Type Annotation Fixer")
        print("=" * 50)
        
        for file_name in target_files:
            file_path = self.workspace_root / file_name
            if file_path.exists():
                print(f"Processing: {file_name}")
                result = self.apply_advanced_fixes(file_path)
                results.append(result)
                
                if result["success"] and result["changes_made"]:
                    print(f"  ✅ Applied {len(result['fixes_applied'])} fixes")
                    for fix in result["fixes_applied"]:
                        print(f"    • {fix}")
                    total_fixes += len(result["fixes_applied"])
                elif result["success"]:
                    print(f"  ℹ️  No changes needed")
                else:
                    print(f"  ❌ Error: {result['error']}")
                    
                print()
            else:
                print(f"  ⚠️  File not found: {file_name}")
                
        print("=" * 50)
        print(f"🎉 Total advanced fixes applied: {total_fixes}")
        
        return {
            "total_files_processed": len(results),
            "total_fixes_applied": total_fixes,
            "results": results
        }

def main():
    """Run the advanced type fixer"""
    workspace_root = "/Users/danielstevens/Desktop/CodingReviewer"
    
    fixer = AdvancedTypeFixer(workspace_root)
    results = fixer.fix_remaining_issues()
    
    return results

if __name__ == "__main__":
    main()
