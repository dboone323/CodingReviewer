#!/usr/bin/env python3
"""
Technical Debt Analyzer - Priority 2 Implementation
Analyzes code quality and provides automated improvements
"""

import ast
import os
import json
import re
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple
from dataclasses import dataclass
from datetime import datetime
from enhanced_error_logging import log_info, log_warning, log_error, ErrorCategory

@dataclass
class TechnicalDebtIssue:
    """Represents a technical debt issue"""
    file_path: str
    line_number: int
    issue_type: str
    severity: str
    description: str
    suggested_fix: str
    complexity_score: int
    impact_score: int

@dataclass
class CodeQualityMetrics:
    """Code quality metrics for a file"""
    file_path: str
    lines_of_code: int
    cyclomatic_complexity: int
    duplicate_blocks: List[str]
    type_annotation_coverage: float
    error_handling_score: float
    documentation_score: float
    overall_score: float

class TechnicalDebtAnalyzer:
    """Analyzes and reports technical debt across the codebase"""
    
    def __init__(self, workspace_path: str = "."):
        self.workspace_path = Path(workspace_path)
        self.issues: List[TechnicalDebtIssue] = []
        self.metrics: List[CodeQualityMetrics] = []
        self.patterns = {
            'duplicate_code': [],
            'high_complexity': [],
            'missing_types': [],
            'poor_error_handling': [],
            'undocumented_functions': []
        }
        
        log_info("TechnicalDebtAnalyzer", f"Initialized for workspace: {workspace_path}")
    
    def analyze_codebase(self) -> Dict[str, Any]:
        """Run comprehensive technical debt analysis"""
        log_info("TechnicalDebtAnalyzer", "Starting comprehensive technical debt analysis")
        
        python_files = list(self.workspace_path.glob("*.py"))
        total_files = len(python_files)
        
        print(f"🔍 Analyzing {total_files} Python files for technical debt...")
        
        analysis_results: Dict[str, Any] = {
            "timestamp": datetime.now().isoformat(),
            "files_analyzed": total_files,
            "total_issues": 0,
            "severity_breakdown": {"critical": 0, "high": 0, "medium": 0, "low": 0},
            "category_breakdown": {},
            "overall_debt_score": 0,
            "recommendations": [],
            "quick_wins": []
        }
        
        try:
            for i, file_path in enumerate(python_files, 1):
                print(f"  📄 Analyzing {file_path.name} ({i}/{total_files})")
                
                try:
                    file_metrics = self._analyze_file(file_path)
                    if file_metrics:
                        self.metrics.append(file_metrics)
                        log_info("TechnicalDebtAnalyzer", f"Analyzed {file_path.name}: {file_metrics.overall_score:.1f}/100")
                except Exception as e:
                    log_error("TechnicalDebtAnalyzer", f"Failed to analyze {file_path.name}: {str(e)}", category=ErrorCategory.SYSTEM_INTEGRATION)
                    continue
            
            # Calculate overall metrics
            analysis_results.update(self._calculate_overall_metrics())
            
            # Generate recommendations
            analysis_results["recommendations"] = self._generate_recommendations()
            analysis_results["quick_wins"] = self._identify_quick_wins()
            
            log_info("TechnicalDebtAnalyzer", f"Analysis complete: {analysis_results['total_issues']} issues found")
            print(f"✅ Analysis complete: {analysis_results['total_issues']} issues identified")
            
            return analysis_results
            
        except Exception as e:
            log_error("TechnicalDebtAnalyzer", f"Critical analysis failure: {str(e)}", category=ErrorCategory.SYSTEM_INTEGRATION)
            raise
    
    def _analyze_file(self, file_path: Path) -> Optional[CodeQualityMetrics]:
        """Analyze a single Python file for technical debt"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Parse AST
            try:
                tree = ast.parse(content)
            except SyntaxError as e:
                log_warning("TechnicalDebtAnalyzer", f"Syntax error in {file_path.name}: {str(e)}")
                return None
            
            # Calculate metrics
            lines_of_code = len([line for line in content.splitlines() if line.strip() and not line.strip().startswith('#')])
            cyclomatic_complexity = self._calculate_complexity(tree)
            duplicate_blocks = self._find_duplicate_code(content)
            type_coverage = self._check_type_annotations(tree)
            error_handling_score = self._assess_error_handling(tree)
            documentation_score = self._assess_documentation(tree)
            
            # Calculate overall score
            overall_score = self._calculate_file_score(
                cyclomatic_complexity, type_coverage, error_handling_score, documentation_score
            )
            
            # Generate issues for this file
            self._generate_file_issues(file_path, tree, content, cyclomatic_complexity, type_coverage)
            
            return CodeQualityMetrics(
                file_path=str(file_path),
                lines_of_code=lines_of_code,
                cyclomatic_complexity=cyclomatic_complexity,
                duplicate_blocks=duplicate_blocks,
                type_annotation_coverage=type_coverage,
                error_handling_score=error_handling_score,
                documentation_score=documentation_score,
                overall_score=overall_score
            )
            
        except Exception as e:
            log_error("TechnicalDebtAnalyzer", f"Error analyzing {file_path.name}: {str(e)}")
            return None
    
    def _calculate_complexity(self, tree: ast.AST) -> int:
        """Calculate cyclomatic complexity"""
        complexity = 1  # Base complexity
        
        for node in ast.walk(tree):
            if isinstance(node, (ast.If, ast.While, ast.For, ast.AsyncFor, ast.With, ast.AsyncWith)):
                complexity += 1
            elif isinstance(node, ast.BoolOp):
                complexity += len(node.values) - 1
            elif isinstance(node, (ast.Try, ast.ExceptHandler)):
                complexity += 1
        
        return complexity
    
    def _find_duplicate_code(self, content: str) -> List[str]:
        """Find potential duplicate code blocks"""
        lines = content.splitlines()
        duplicates = []
        
        # Simple duplicate detection - look for identical function patterns
        function_bodies = {}
        current_function = None
        current_body = []
        
        for line in lines:
            stripped = line.strip()
            if stripped.startswith('def ') or stripped.startswith('async def '):
                if current_function and current_body:
                    body_str = '\n'.join(current_body)
                    if body_str in function_bodies:
                        duplicates.append(f"Duplicate of {function_bodies[body_str]}")
                    else:
                        function_bodies[body_str] = current_function
                
                current_function = stripped
                current_body = []
            elif current_function and stripped:
                current_body.append(stripped)
        
        return duplicates
    
    def _check_type_annotations(self, tree: ast.AST) -> float:
        """Check type annotation coverage"""
        functions = [node for node in ast.walk(tree) if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef))]
        
        if not functions:
            return 100.0
        
        annotated_functions = 0
        for func in functions:
            has_return_annotation = func.returns is not None
            has_arg_annotations = all(arg.annotation is not None for arg in func.args.args)
            
            if has_return_annotation and has_arg_annotations:
                annotated_functions += 1
        
        return (annotated_functions / len(functions)) * 100
    
    def _assess_error_handling(self, tree: ast.AST) -> float:
        """Assess error handling quality"""
        functions = [node for node in ast.walk(tree) if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef))]
        try_blocks = [node for node in ast.walk(tree) if isinstance(node, ast.Try)]
        
        if not functions:
            return 100.0
        
        # Simple heuristic: functions with try/except get higher scores
        functions_with_error_handling = 0
        for func in functions:
            func_try_blocks = [node for node in ast.walk(func) if isinstance(node, ast.Try)]
            if func_try_blocks:
                functions_with_error_handling += 1
        
        base_score = (functions_with_error_handling / len(functions)) * 60
        
        # Bonus for having except handlers with specific exceptions
        specific_handlers = 0
        for try_node in try_blocks:
            for handler in try_node.handlers:
                if handler.type is not None:  # Specific exception type
                    specific_handlers += 1
        
        bonus_score = min(specific_handlers * 5, 40)
        return min(base_score + bonus_score, 100.0)
    
    def _assess_documentation(self, tree: ast.AST) -> float:
        """Assess documentation quality"""
        functions = [node for node in ast.walk(tree) if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef))]
        classes = [node for node in ast.walk(tree) if isinstance(node, ast.ClassDef)]
        
        total_items = len(functions) + len(classes)
        if total_items == 0:
            return 100.0
        
        documented_items = 0
        
        # Check function docstrings
        for func in functions:
            if (func.body and isinstance(func.body[0], ast.Expr) and 
                isinstance(func.body[0].value, ast.Constant)):
                documented_items += 1
        
        # Check class docstrings
        for cls in classes:
            if (cls.body and isinstance(cls.body[0], ast.Expr) and 
                isinstance(cls.body[0].value, ast.Constant)):
                documented_items += 1
        
        return (documented_items / total_items) * 100
    
    def _calculate_file_score(self, complexity: int, type_coverage: float, error_handling: float, documentation: float) -> float:
        """Calculate overall file quality score"""
        # Complexity penalty (higher complexity = lower score)
        complexity_score = max(0, 100 - (complexity - 1) * 2)
        
        # Weighted average
        weights = {
            'complexity': 0.3,
            'types': 0.3,
            'error_handling': 0.25,
            'documentation': 0.15
        }
        
        overall_score = (
            complexity_score * weights['complexity'] +
            type_coverage * weights['types'] +
            error_handling * weights['error_handling'] +
            documentation * weights['documentation']
        )
        
        return round(overall_score, 1)
    
    def _generate_file_issues(self, file_path: Path, tree: ast.AST, content: str, complexity: int, type_coverage: float) -> str:
        """Generate specific issues for a file"""
        
        # High complexity issue
        if complexity > 20:
            self.issues.append(TechnicalDebtIssue(
                file_path=str(file_path),
                line_number=1,
                issue_type="high_complexity",
                severity="high" if complexity > 30 else "medium",
                description=f"High cyclomatic complexity: {complexity}",
                suggested_fix="Consider breaking down complex functions into smaller ones",
                complexity_score=complexity,
                impact_score=min(complexity * 2, 100)
            ))
        
        # Low type coverage issue
        if type_coverage < 50:
            self.issues.append(TechnicalDebtIssue(
                file_path=str(file_path),
                line_number=1,
                issue_type="missing_types",
                severity="medium" if type_coverage < 25 else "low",
                description=f"Low type annotation coverage: {type_coverage:.1f}%",
                suggested_fix="Add type annotations to function parameters and return types",
                complexity_score=5,
                impact_score=int(100 - type_coverage)
            ))
        
        # Check for bare except clauses
        for node in ast.walk(tree):
            if isinstance(node, ast.ExceptHandler) and node.type is None:
                self.issues.append(TechnicalDebtIssue(
                    file_path=str(file_path),
                    line_number=getattr(node, 'lineno', 1),
                    issue_type="poor_error_handling",
                    severity="medium",
                    description="Bare except clause catches all exceptions",
                    suggested_fix="Specify exact exception types to catch",
                    complexity_score=3,
                    impact_score=25
                ))
    
    def _calculate_overall_metrics(self) -> Dict[str, Any]:
        """Calculate overall codebase metrics"""
        if not self.metrics:
            return {"overall_debt_score": 100, "total_issues": 0}
        
        # Calculate average scores
        avg_score = sum(m.overall_score for m in self.metrics) / len(self.metrics)
        overall_debt_score = 100 - avg_score  # Debt is inverse of quality
        
        # Count issues by severity
        severity_counts = {"critical": 0, "high": 0, "medium": 0, "low": 0}
        category_counts = {}
        
        for issue in self.issues:
            severity_counts[issue.severity] += 1
            if issue.issue_type not in category_counts:
                category_counts[issue.issue_type] = 0
            category_counts[issue.issue_type] += 1
        
        return {
            "overall_debt_score": round(overall_debt_score, 1),
            "average_quality_score": round(avg_score, 1),
            "total_issues": len(self.issues),
            "severity_breakdown": severity_counts,
            "category_breakdown": category_counts,
            "files_with_issues": len([m for m in self.metrics if m.overall_score < 70])
        }
    
    def _generate_recommendations(self) -> List[Dict[str, Any]]:
        """Generate improvement recommendations"""
        recommendations = []
        
        # High complexity files
        high_complexity_files = [m for m in self.metrics if m.cyclomatic_complexity > 20]
        if high_complexity_files:
            recommendations.append({
                "category": "Complexity Reduction",
                "priority": "high",
                "description": f"Reduce complexity in {len(high_complexity_files)} files",
                "action": "Break down complex functions into smaller, focused functions",
                "estimated_effort": "1-2 days",
                "impact": "Improves maintainability and readability"
            })
        
        # Type annotation coverage
        low_type_coverage = [m for m in self.metrics if m.type_annotation_coverage < 50]
        if low_type_coverage:
            recommendations.append({
                "category": "Type Safety",
                "priority": "medium",
                "description": f"Improve type annotations in {len(low_type_coverage)} files",
                "action": "Add type hints to function parameters and return types",
                "estimated_effort": "2-3 days",
                "impact": "Better IDE support and error detection"
            })
        
        # Error handling
        poor_error_handling = [i for i in self.issues if i.issue_type == "poor_error_handling"]
        if poor_error_handling:
            recommendations.append({
                "category": "Error Handling",
                "priority": "medium", 
                "description": f"Improve error handling in {len(poor_error_handling)} locations",
                "action": "Replace bare except clauses with specific exception types",
                "estimated_effort": "1 day",
                "impact": "Better error diagnosis and system stability"
            })
        
        return recommendations
    
    def _identify_quick_wins(self) -> List[Dict[str, Any]]:
        """Identify quick wins for immediate improvement"""
        quick_wins = []
        
        # Easy type annotation fixes
        missing_type_issues = [i for i in self.issues if i.issue_type == "missing_types" and i.impact_score < 30]
        if missing_type_issues:
            quick_wins.append({
                "title": "Add Missing Type Annotations",
                "effort": "30 minutes",
                "impact": "Medium",
                "files_affected": len(set(i.file_path for i in missing_type_issues)),
                "description": "Add type hints to simple functions with clear parameter types"
            })
        
        # Fix bare except clauses
        bare_except_issues = [i for i in self.issues if i.issue_type == "poor_error_handling"]
        if bare_except_issues:
            quick_wins.append({
                "title": "Fix Bare Except Clauses",
                "effort": "15 minutes",
                "impact": "High",
                "files_affected": len(set(i.file_path for i in bare_except_issues)),
                "description": "Replace bare except: with specific exception types"
            })
        
        return quick_wins
    
    def generate_report(self, output_file: str = "technical_debt_report.json") -> str:
        """Generate and save detailed technical debt report"""
        log_info("TechnicalDebtAnalyzer", f"Generating report: {output_file}")
        
        analysis_results = self.analyze_codebase()
        
        # Add detailed file metrics
        analysis_results["file_metrics"] = [
            {
                "file_path": m.file_path,
                "lines_of_code": m.lines_of_code,
                "cyclomatic_complexity": m.cyclomatic_complexity,
                "type_annotation_coverage": m.type_annotation_coverage,
                "error_handling_score": m.error_handling_score,
                "documentation_score": m.documentation_score,
                "overall_score": m.overall_score
            }
            for m in self.metrics
        ]
        
        # Add detailed issues
        analysis_results["detailed_issues"] = [
            {
                "file_path": i.file_path,
                "line_number": i.line_number,
                "issue_type": i.issue_type,
                "severity": i.severity,
                "description": i.description,
                "suggested_fix": i.suggested_fix,
                "complexity_score": i.complexity_score,
                "impact_score": i.impact_score
            }
            for i in self.issues
        ]
        
        # Save report
        output_path = Path(output_file)
        with open(output_path, 'w') as f:
            json.dump(analysis_results, f, indent=2, default=str)
        
        log_info("TechnicalDebtAnalyzer", f"Report saved to {output_path}")
        return str(output_path)

def main() -> Any:
    """Main execution for technical debt analysis"""
    print("🔧 Technical Debt Analyzer - Priority 2 Implementation")
    print("=" * 60)
    
    analyzer = TechnicalDebtAnalyzer()
    
    try:
        # Generate comprehensive report
        report_path = analyzer.generate_report()
        
        print(f"\n📊 Technical Debt Analysis Complete!")
        print(f"📄 Report saved to: {report_path}")
        
        # Load and display summary
        with open(report_path, 'r') as f:
            results = json.load(f)
        
        print(f"\n📈 Summary:")
        print(f"  Files Analyzed: {results['files_analyzed']}")
        print(f"  Total Issues: {results['total_issues']}")
        print(f"  Overall Debt Score: {results['overall_debt_score']:.1f}/100")
        print(f"  Average Quality Score: {results.get('average_quality_score', 0):.1f}/100")
        
        print(f"\n🚨 Issue Breakdown:")
        for severity, count in results['severity_breakdown'].items():
            if count > 0:
                print(f"  {severity.title()}: {count}")
        
        print(f"\n💡 Quick Wins Available: {len(results['quick_wins'])}")
        for qw in results['quick_wins']:
            print(f"  ⚡ {qw['title']} ({qw['effort']}) - {qw['files_affected']} files")
        
        print(f"\n🎯 Recommendations: {len(results['recommendations'])}")
        for rec in results['recommendations'][:3]:  # Show top 3
            print(f"  📋 {rec['category']}: {rec['description']}")
        
        return results
        
    except Exception as e:
        log_error("TechnicalDebtAnalyzer", f"Analysis failed: {str(e)}", category=ErrorCategory.SYSTEM_INTEGRATION)
        print(f"❌ Analysis failed: {str(e)}")
        return None

if __name__ == "__main__":
    main()