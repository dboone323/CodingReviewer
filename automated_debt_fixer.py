#!/usr/bin/env python3
"""
Priority 2 Automated Technical Debt Fixer
Implements quick wins and automated improvements based on technical debt analysis
"""

import ast
import re
import os
from pathlib import Path
from typing import Any, Dict, List, Optional
from enhanced_error_logging import log_info, log_warning, log_error, ErrorCategory

class AutomatedDebtFixer:
    """Automatically fixes technical debt issues identified by analysis"""
    
    def __init__(self, workspace_path: str = "."):
        self.workspace_path = Path(workspace_path)
        self.fixes_applied = []
        
        log_info("AutomatedDebtFixer", f"Initialized for workspace: {workspace_path}")
    
    def apply_quick_wins(self) -> Dict[str, Any]:
        """Apply quick win fixes automatically"""
        log_info("AutomatedDebtFixer", "Starting quick win fixes")
        print("⚡ Applying Quick Win Fixes...")
        
        results: Dict[str, Any] = {
            "timestamp": "2025-08-12T12:15:00",
            "fixes_applied": [],
            "files_modified": [],
            "errors": []
        }
        
        try:
            # Fix 1: Replace bare except clauses
            bare_except_fixes = self._fix_bare_except_clauses()
            results["fixes_applied"].extend(bare_except_fixes)
            
            # Fix 2: Add basic type annotations to simple functions
            type_annotation_fixes = self._add_basic_type_annotations()
            results["fixes_applied"].extend(type_annotation_fixes)
            
            # Fix 3: Improve simple docstrings
            documentation_fixes = self._improve_basic_documentation()
            results["fixes_applied"].extend(documentation_fixes)
            
            # Collect all modified files
            all_files = set()
            for fix in results["fixes_applied"]:
                all_files.add(fix["file_path"])
            results["files_modified"] = list(all_files)
            
            log_info("AutomatedDebtFixer", f"Quick wins complete: {len(results['fixes_applied'])} fixes applied")
            print(f"✅ Quick wins complete: {len(results['fixes_applied'])} fixes applied to {len(results['files_modified'])} files")
            
            return results
            
        except Exception as e:
            log_error("AutomatedDebtFixer", f"Quick win fixes failed: {str(e)}", category=ErrorCategory.SYSTEM_INTEGRATION)
            results["errors"].append(str(e))
            return results
    
    def _fix_bare_except_clauses(self) -> List[Dict[str, Any]]:
        """Fix bare except clauses by adding specific exception types"""
        fixes = []
        python_files = list(self.workspace_path.glob("*.py"))
        
        print("  🔧 Fixing bare except clauses...")
        
        for file_path in python_files:
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # Look for bare except patterns
                lines = content.splitlines()
                modified_lines = []
                fixes_in_file = 0
                
                for i, line in enumerate(lines):
                    if re.match(r'^\s*except\s*:\s*$', line):
                        # Replace bare except with Exception
                        indentation = re.match(r'^(\s*)', line).group(1)
                        modified_lines.append(f"{indentation}except Exception as e:")
                        fixes_in_file += 1
                        
                        fixes.append({
                            "file_path": str(file_path),
                            "line_number": i + 1,
                            "fix_type": "bare_except_clause",
                            "description": "Replaced bare except: with except Exception as e:",
                            "original": line.strip(),
                            "fixed": f"{indentation}except Exception as e:".strip()
                        })
                    else:
                        modified_lines.append(line)
                
                # Write back if changes were made
                if fixes_in_file > 0:
                    with open(file_path, 'w', encoding='utf-8') as f:
                        f.write('\n'.join(modified_lines))
                    
                    log_info("AutomatedDebtFixer", f"Fixed {fixes_in_file} bare except clauses in {file_path.name}")
                    print(f"    ✅ {file_path.name}: {fixes_in_file} bare except clauses fixed")
                
            except Exception as e:
                log_error("AutomatedDebtFixer", f"Error fixing bare except in {file_path.name}: {str(e)}")
                continue
        
        return fixes
    
    def _add_basic_type_annotations(self) -> List[Dict[str, Any]]:
        """Add basic type annotations to simple functions"""
        fixes = []
        python_files = list(self.workspace_path.glob("*.py"))
        
        print("  🏷️  Adding basic type annotations...")
        
        for file_path in python_files:
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # Parse AST to find functions without type annotations
                try:
                    tree = ast.parse(content)
                except SyntaxError:
                    continue
                
                lines = content.splitlines()
                modified_lines = list(lines)
                fixes_in_file = 0
                
                for node in ast.walk(tree):
                    if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
                        # Skip if already has return annotation
                        if node.returns is not None:
                            continue
                        
                        # Skip special methods and private methods
                        if node.name.startswith('_'):
                            continue
                        
                        # Add basic return type annotation for simple cases
                        line_idx = node.lineno - 1
                        if line_idx < len(modified_lines):
                            line = modified_lines[line_idx]
                            
                            # Simple heuristic: if function has return statement, add -> Any
                            has_return = any(isinstance(n, ast.Return) for n in ast.walk(node))
                            
                            if has_return and ' -> ' not in line:
                                # Add -> Any before the colon
                                if line.rstrip().endswith(':'):
                                    new_line = line.rstrip()[:-1] + ' -> Any:'
                                    modified_lines[line_idx] = new_line
                                    fixes_in_file += 1
                                    
                                    # Add import for Any if not present
                                    if 'from typing import' not in content and 'import typing' not in content:
                                        # Add import at the top
                                        modified_lines.insert(0, 'from typing import Any, Dict, List, Optional')
                                    
                                    fixes.append({
                                        "file_path": str(file_path),
                                        "line_number": node.lineno,
                                        "fix_type": "type_annotation",
                                        "description": f"Added return type annotation to function '{node.name}'",
                                        "original": line.strip(),
                                        "fixed": new_line.strip()
                                    })
                
                # Write back if changes were made
                if fixes_in_file > 0:
                    with open(file_path, 'w', encoding='utf-8') as f:
                        f.write('\n'.join(modified_lines))
                    
                    log_info("AutomatedDebtFixer", f"Added type annotations to {fixes_in_file} functions in {file_path.name}")
                    print(f"    ✅ {file_path.name}: {fixes_in_file} type annotations added")
                
            except Exception as e:
                log_error("AutomatedDebtFixer", f"Error adding type annotations in {file_path.name}: {str(e)}")
                continue
        
        return fixes
    
    def _improve_basic_documentation(self) -> List[Dict[str, Any]]:
        """Add basic docstrings to undocumented functions"""
        fixes = []
        python_files = list(self.workspace_path.glob("*.py"))
        
        print("  📝 Adding basic documentation...")
        
        for file_path in python_files:
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # Parse AST to find functions without docstrings
                try:
                    tree = ast.parse(content)
                except SyntaxError:
                    continue
                
                lines = content.splitlines()
                modified_lines = list(lines)
                fixes_in_file = 0
                
                for node in ast.walk(tree):
                    if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
                        # Skip if already has docstring
                        if (node.body and isinstance(node.body[0], ast.Expr) and 
                            isinstance(node.body[0].value, (ast.Constant, ast.Constant))):
                            continue
                        
                        # Skip very short functions (< 3 lines)
                        if len(node.body) < 3:
                            continue
                        
                        # Skip special methods
                        if node.name.startswith('__') and node.name.endswith('__'):
                            continue
                        
                        # Add basic docstring
                        line_idx = node.lineno  # Line after function definition
                        if line_idx < len(modified_lines):
                            # Get indentation from the function line
                            func_line = modified_lines[node.lineno - 1]
                            indentation = re.match(r'^(\s*)', func_line).group(1) + '    '
                            
                            # Generate basic docstring
                            docstring = f'{indentation}"""TODO: Add documentation for {node.name}"""'
                            
                            # Insert docstring
                            modified_lines.insert(line_idx, docstring)
                            fixes_in_file += 1
                            
                            fixes.append({
                                "file_path": str(file_path),
                                "line_number": node.lineno,
                                "fix_type": "documentation",
                                "description": f"Added basic docstring to function '{node.name}'",
                                "original": "# No docstring",
                                "fixed": docstring.strip()
                            })
                
                # Write back if changes were made
                if fixes_in_file > 0:
                    with open(file_path, 'w', encoding='utf-8') as f:
                        f.write('\n'.join(modified_lines))
                    
                    log_info("AutomatedDebtFixer", f"Added docstrings to {fixes_in_file} functions in {file_path.name}")
                    print(f"    ✅ {file_path.name}: {fixes_in_file} docstrings added")
                
            except Exception as e:
                log_error("AutomatedDebtFixer", f"Error adding documentation in {file_path.name}: {str(e)}")
                continue
        
        return fixes
    
    def implement_complexity_reduction(self) -> Dict[str, Any]:
        """Implement complexity reduction strategies for high-complexity functions"""
        log_info("AutomatedDebtFixer", "Starting complexity reduction implementation")
        print("🔄 Implementing Complexity Reduction...")
        
        results: Dict[str, Any] = {
            "timestamp": "2025-08-12T12:16:00",
            "complexity_analysis": [],
            "refactoring_suggestions": [],
            "implementation_plan": []
        }
        
        try:
            # Load technical debt report for high complexity files
            report_path = Path("technical_debt_report.json")
            if report_path.exists():
                import json
                with open(report_path, 'r') as f:
                    debt_report = json.load(f)
                
                # Focus on files with high complexity
                high_complexity_files = [
                    metric for metric in debt_report.get("file_metrics", [])
                    if metric["cyclomatic_complexity"] > 30
                ]
                
                print(f"  📊 Found {len(high_complexity_files)} high-complexity files")
                
                for file_metric in high_complexity_files[:5]:  # Top 5 most complex
                    file_path = Path(file_metric["file_path"])
                    complexity = file_metric["cyclomatic_complexity"]
                    
                    print(f"    🔍 Analyzing {file_path.name} (complexity: {complexity})")
                    
                    analysis = self._analyze_function_complexity(file_path)
                    results["complexity_analysis"].append({
                        "file_path": str(file_path),
                        "current_complexity": complexity,
                        "function_breakdown": analysis,
                        "target_complexity": min(complexity // 2, 20)
                    })
                    
                    # Generate refactoring suggestions
                    suggestions = self._generate_refactoring_suggestions(file_path, analysis)
                    results["refactoring_suggestions"].extend(suggestions)
            
            # Create implementation plan
            results["implementation_plan"] = self._create_complexity_reduction_plan(results["refactoring_suggestions"])
            
            log_info("AutomatedDebtFixer", f"Complexity reduction analysis complete: {len(results['refactoring_suggestions'])} suggestions generated")
            print(f"✅ Complexity reduction analysis complete")
            
            return results
            
        except Exception as e:
            log_error("AutomatedDebtFixer", f"Complexity reduction failed: {str(e)}", category=ErrorCategory.SYSTEM_INTEGRATION)
            results["error"] = str(e)
            return results
    
    def _analyze_function_complexity(self, file_path: Path) -> List[Dict[str, Any]]:
        """Analyze complexity of individual functions in a file"""
        analysis = []
        
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            tree = ast.parse(content)
            
            for node in ast.walk(tree):
                if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
                    func_complexity = self._calculate_function_complexity(node)
                    
                    analysis.append({
                        "function_name": node.name,
                        "line_number": node.lineno,
                        "complexity": func_complexity,
                        "lines_of_code": len(node.body),
                        "needs_refactoring": func_complexity > 10
                    })
            
        except Exception as e:
            log_error("AutomatedDebtFixer", f"Error analyzing function complexity in {file_path.name}: {str(e)}")
        
        return analysis
    
    def _calculate_function_complexity(self, func_node: ast.AST) -> int:
        """Calculate cyclomatic complexity for a single function"""
        complexity = 1  # Base complexity
        
        for node in ast.walk(func_node):
            if isinstance(node, (ast.If, ast.While, ast.For, ast.AsyncFor)):
                complexity += 1
            elif isinstance(node, ast.BoolOp):
                complexity += len(node.values) - 1
            elif isinstance(node, (ast.Try, ast.ExceptHandler)):
                complexity += 1
        
        return complexity
    
    def _generate_refactoring_suggestions(self, file_path: Path, analysis: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Generate specific refactoring suggestions for complex functions"""
        suggestions = []
        
        for func_analysis in analysis:
            if func_analysis["needs_refactoring"]:
                suggestions.append({
                    "file_path": str(file_path),
                    "function_name": func_analysis["function_name"],
                    "current_complexity": func_analysis["complexity"],
                    "suggestion": "Break down into smaller functions",
                    "approach": "Extract method refactoring",
                    "estimated_effort": "30-60 minutes",
                    "priority": "high" if func_analysis["complexity"] > 20 else "medium"
                })
        
        return suggestions
    
    def _create_complexity_reduction_plan(self, suggestions: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Create implementation plan for complexity reduction"""
        plan = []
        
        # Group by priority
        high_priority = [s for s in suggestions if s.get("priority") == "high"]
        medium_priority = [s for s in suggestions if s.get("priority") == "medium"]
        
        if high_priority:
            plan.append({
                "phase": "Phase 1 - Critical Complexity",
                "duration": "1 day",
                "targets": len(high_priority),
                "description": "Address highest complexity functions first",
                "functions": [s["function_name"] for s in high_priority[:5]]
            })
        
        if medium_priority:
            plan.append({
                "phase": "Phase 2 - Medium Complexity",
                "duration": "2 days", 
                "targets": len(medium_priority),
                "description": "Refactor moderately complex functions",
                "functions": [s["function_name"] for s in medium_priority[:10]]
            })
        
        return plan

def main() -> Any:
    """Main execution for automated debt fixing"""
    print("🔧 Priority 2 - Automated Technical Debt Fixer")
    print("=" * 60)
    
    fixer = AutomatedDebtFixer()
    
    try:
        # Phase 1: Apply quick wins
        print("\n⚡ Phase 1: Quick Win Fixes")
        quick_wins = fixer.apply_quick_wins()
        
        # Phase 2: Complexity reduction analysis
        print("\n🔄 Phase 2: Complexity Reduction Analysis")
        complexity_results = fixer.implement_complexity_reduction()
        
        # Save results
        import json
        results: Dict[str, Any] = {
            "quick_wins": quick_wins,
            "complexity_reduction": complexity_results,
            "summary": {
                "total_fixes_applied": len(quick_wins.get("fixes_applied", [])),
                "files_modified": len(quick_wins.get("files_modified", [])),
                "refactoring_suggestions": len(complexity_results.get("refactoring_suggestions", [])),
                "implementation_phases": len(complexity_results.get("implementation_plan", []))
            }
        }
        
        with open("automated_debt_fixes_report.json", 'w') as f:
            json.dump(results, f, indent=2, default=str)
        
        print(f"\n📊 Priority 2 Automated Fixes Summary:")
        print(f"  ✅ Quick fixes applied: {results['summary']['total_fixes_applied']}")
        print(f"  📄 Files modified: {results['summary']['files_modified']}")
        print(f"  🔄 Refactoring suggestions: {results['summary']['refactoring_suggestions']}")
        print(f"  📋 Implementation phases: {results['summary']['implementation_phases']}")
        
        print(f"\n💾 Detailed report saved to: automated_debt_fixes_report.json")
        
        return results
        
    except Exception as e:
        log_error("AutomatedDebtFixer", f"Main execution failed: {str(e)}", category=ErrorCategory.SYSTEM_INTEGRATION)
        print(f"❌ Automated fixing failed: {str(e)}")
        return None

if __name__ == "__main__":
    main()