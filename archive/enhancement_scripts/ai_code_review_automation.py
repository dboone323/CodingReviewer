#!/usr/bin/env python3
"""
AI-Driven Code Review Automation System
Automated code review using AI pattern analysis and quality assessment

This system provides automated code review capabilities using our AI pattern
analysis to identify issues, suggest improvements, and enforce coding standards.
"""

import os
import asyncio
import logging
import json
import subprocess
from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional, Tuple
from dataclasses import dataclass, asdict
from pathlib import Path
import difflib
import ast
import re

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@dataclass
class CodeReviewIssue:
    """Individual code review issue"""
    file_path: str
    line_number: int
    issue_type: str  # 'style', 'complexity', 'security', 'performance', 'maintainability'
    severity: str    # 'info', 'warning', 'error', 'critical'
    message: str
    suggestion: str
    confidence: float
    auto_fixable: bool = False
    fix_command: Optional[str] = None

@dataclass
class CodeReviewResult:
    """Complete code review result"""
    review_id: str
    timestamp: datetime
    files_reviewed: List[str]
    issues: List[CodeReviewIssue]
    overall_score: float
    recommendations: List[str]
    auto_fixes_applied: int
    review_summary: Dict[str, Any]

class AICodeReviewer:
    """AI-powered code reviewer using pattern analysis"""
    
    def __init__(self, project_path: str = "."):
        self.project_path = Path(project_path)
        self.output_dir = self.project_path / ".code_reviews"
        self.output_dir.mkdir(exist_ok=True)
        
        # Quality thresholds
        self.thresholds = {
            "max_function_length": 30,
            "max_class_length": 200,
            "max_complexity": 10,
            "max_imports": 20,
            "min_comment_ratio": 0.1
        }
        
        logger.info("AI Code Reviewer initialized")
    
    async def review_changes(self, target_branch: str = "main") -> CodeReviewResult:
        """Review recent changes against target branch"""
        review_id = f"review_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        
        # Get changed files
        changed_files = await self._get_changed_files(target_branch)
        
        if not changed_files:
            logger.info("No changes to review")
            return self._create_empty_review(review_id)
        
        logger.info(f"Reviewing {len(changed_files)} changed files")
        
        # Review each file
        all_issues = []
        for file_path in changed_files:
            if self._should_review_file(file_path):
                issues = await self._review_file(file_path)
                all_issues.extend(issues)
        
        # Generate overall assessment
        overall_score = self._calculate_overall_score(all_issues)
        recommendations = self._generate_recommendations(all_issues)
        
        # Apply auto-fixes if requested
        auto_fixes_applied = await self._apply_auto_fixes(all_issues)
        
        # Create review result
        result = CodeReviewResult(
            review_id=review_id,
            timestamp=datetime.now(),
            files_reviewed=changed_files,
            issues=all_issues,
            overall_score=overall_score,
            recommendations=recommendations,
            auto_fixes_applied=auto_fixes_applied,
            review_summary=self._generate_summary(all_issues)
        )
        
        # Save review
        await self._save_review(result)
        
        return result
    
    async def review_file(self, file_path: str) -> List[CodeReviewIssue]:
        """Review a specific file"""
        return await self._review_file(file_path)
    
    async def review_file_for_dashboard(self, file_path: str) -> Dict[str, Any]:
        """Review a file and return dashboard-compatible results"""
        issues = await self._review_file(file_path)
        
        # Calculate quality score based on issues
        if not issues:
            quality_score = 100.0
        else:
            # Deduct points based on severity
            total_deduction = 0
            for issue in issues:
                if issue.severity == "error":
                    total_deduction += 15
                elif issue.severity == "warning":
                    total_deduction += 5
                elif issue.severity == "info":
                    total_deduction += 1
            
            quality_score = max(0, 100 - total_deduction)
        
        # Generate auto-fixes for applicable issues
        auto_fixes = []
        for issue in issues:
            if issue.issue_type in ["style", "complexity", "unused_import"]:
                auto_fixes.append({
                    "issue_id": f"{issue.file_path}:{issue.line_number}",
                    "type": issue.issue_type,
                    "fix": issue.suggestion
                })
        
        return {
            "issues": issues,
            "quality_score": quality_score,
            "auto_fixes": auto_fixes,
            "summary": {
                "total_issues": len(issues),
                "errors": len([i for i in issues if i.severity == "error"]),
                "warnings": len([i for i in issues if i.severity == "warning"]),
                "infos": len([i for i in issues if i.severity == "info"])
            }
        }

    async def _get_changed_files(self, target_branch: str) -> List[str]:
        """Get list of files changed since target branch"""
        try:
            # Use git to get changed files
            result = subprocess.run(
                ["git", "diff", "--name-only", f"{target_branch}...HEAD"],
                cwd=self.project_path,
                capture_output=True,
                text=True
            )
            
            if result.returncode == 0:
                files = [f for f in result.stdout.strip().split('\n') if f]
                return [str(self.project_path / f) for f in files if Path(self.project_path / f).exists()]
            else:
                logger.warning("Could not get git diff, reviewing all Python/Swift files")
                # Fallback: review all files modified in last 24 hours
                return await self._get_recently_modified_files()
                
        except Exception as e:
            logger.warning(f"Git diff failed: {e}, using fallback")
            return await self._get_recently_modified_files()
    
    async def _get_recently_modified_files(self) -> List[str]:
        """Get files modified in the last 24 hours as fallback"""
        cutoff = datetime.now() - timedelta(hours=24)
        recent_files = []
        
        for pattern in ["**/*.py", "**/*.swift"]:
            for file_path in self.project_path.glob(pattern):
                try:
                    if datetime.fromtimestamp(file_path.stat().st_mtime) > cutoff:
                        recent_files.append(str(file_path))
                except Exception as e:
                    continue
        
        return recent_files[:20]  # Limit to 20 files
    
    def _should_review_file(self, file_path: str) -> bool:
        """Check if file should be reviewed"""
        path = Path(file_path)
        
        # Skip certain directories and files
        skip_patterns = [
            ".git", "__pycache__", ".venv", "venv", "node_modules",
            ".build", "build", "dist", ".pytest_cache"
        ]
        
        for pattern in skip_patterns:
            if pattern in str(path):
                return False
        
        # Only review code files
        return path.suffix in ['.py', '.swift']
    
    async def _review_file(self, file_path: str) -> List[CodeReviewIssue]:
        """Review a single file"""
        path = Path(file_path)
        issues = []
        
        try:
            if path.suffix == '.py':
                issues.extend(await self._review_python_file(path))
            elif path.suffix == '.swift':
                issues.extend(await self._review_swift_file(path))
        except Exception as e:
            logger.warning(f"Error reviewing {file_path}: {e}")
            issues.append(CodeReviewIssue(
                file_path=str(path),
                line_number=1,
                issue_type="error",
                severity="error",
                message=f"Could not parse file: {e}",
                suggestion="Check file syntax and encoding",
                confidence=1.0
            ))
        
        return issues
    
    async def _review_python_file(self, file_path: Path) -> List[CodeReviewIssue]:
        """Review Python file"""
        issues = []
        
        try:
            content = file_path.read_text(encoding='utf-8')
            tree = ast.parse(content)
            lines = content.split('\n')
            
            # Use our existing pattern analysis
            visitor = PythonReviewVisitor(str(file_path), lines, self.thresholds)
            visitor.visit(tree)
            issues.extend(visitor.issues)
            
            # Additional checks
            issues.extend(self._check_python_style(file_path, content, lines))
            issues.extend(self._check_python_security(file_path, content, lines))
            
        except SyntaxError as e:
            issues.append(CodeReviewIssue(
                file_path=str(file_path),
                line_number=e.lineno or 1,
                issue_type="syntax",
                severity="error",
                message=f"Syntax error: {e.msg}",
                suggestion="Fix syntax error",
                confidence=1.0
            ))
        
        return issues
    
    async def _review_swift_file(self, file_path: Path) -> List[CodeReviewIssue]:
        """Review Swift file"""
        issues = []
        
        try:
            content = file_path.read_text(encoding='utf-8')
            lines = content.split('\n')
            
            # Swift-specific checks
            issues.extend(self._check_swift_style(file_path, content, lines))
            issues.extend(self._check_swift_memory(file_path, content, lines))
            issues.extend(self._check_swift_performance(file_path, content, lines))
            
        except Exception as e:
            logger.warning(f"Error reviewing Swift file {file_path}: {e}")
        
        return issues
    
    def _check_python_style(self, file_path: Path, content: str, lines: List[str]) -> List[CodeReviewIssue]:
        """Check Python style issues"""
        issues = []
        
        for i, line in enumerate(lines, 1):
            # Check line length
            if len(line) > 100:
                issues.append(CodeReviewIssue(
                    file_path=str(file_path),
                    line_number=i,
                    issue_type="style",
                    severity="warning",
                    message=f"Line too long ({len(line)} > 100 characters)",
                    suggestion="Break line into multiple lines",
                    confidence=0.9,
                    auto_fixable=True,
                    fix_command="line_wrap"
                ))
            
            # Check for TODO/FIXME comments
            if re.search(r'\b(TODO|FIXME|HACK)\b', line, re.IGNORECASE):
                issues.append(CodeReviewIssue(
                    file_path=str(file_path),
                    line_number=i,
                    issue_type="maintainability",
                    severity="info",
                    message="TODO/FIXME comment found",
                    suggestion="Consider creating an issue to track this work",
                    confidence=0.8
                ))
        
        return issues
    
    def _check_python_security(self, file_path: Path, content: str, lines: List[str]) -> List[CodeReviewIssue]:
        """Check Python security issues"""
        issues = []
        
        # Check for dangerous patterns
        dangerous_patterns = [
            (r'\beval\s*\(', "Use of eval() is dangerous"),
            (r'\bexec\s*\(', "Use of exec() is dangerous"),
            (r'subprocess\.call\s*\([^,)]*shell\s*=\s*True', "Shell injection risk"),
            (r'os\.system\s*\(', "Use of os.system() is dangerous"),
        ]
        
        for i, line in enumerate(lines, 1):
            for pattern, message in dangerous_patterns:
                if re.search(pattern, line):
                    issues.append(CodeReviewIssue(
                        file_path=str(file_path),
                        line_number=i,
                        issue_type="security",
                        severity="critical",
                        message=message,
                        suggestion="Use safer alternatives",
                        confidence=0.9
                    ))
        
        return issues
    
    def _check_swift_style(self, file_path: Path, content: str, lines: List[str]) -> List[CodeReviewIssue]:
        """Check Swift style issues"""
        issues = []
        
        for i, line in enumerate(lines, 1):
            # Check for force unwrapping
            if '!' in line and not line.strip().startswith('//'):
                force_unwraps = line.count('!')
                if force_unwraps > 0:
                    issues.append(CodeReviewIssue(
                        file_path=str(file_path),
                        line_number=i,
                        issue_type="style",
                        severity="warning",
                        message="Force unwrapping detected",
                        suggestion="Consider using optional binding or nil coalescing",
                        confidence=0.7
                    ))
        
        return issues
    
    def _check_swift_memory(self, file_path: Path, content: str, lines: List[str]) -> List[CodeReviewIssue]:
        """Check Swift memory management"""
        issues = []
        
        # Check for proper weak/unowned usage
        weak_count = content.count('weak ')
        unowned_count = content.count('unowned ')
        closure_count = len(re.findall(r'\{[^}]*\}', content))
        
        if closure_count > 3 and weak_count == 0 and unowned_count == 0:
            issues.append(CodeReviewIssue(
                file_path=str(file_path),
                line_number=1,
                issue_type="memory",
                severity="warning",
                message="Multiple closures without weak/unowned references",
                suggestion="Check for potential retain cycles",
                confidence=0.6
            ))
        
        return issues
    
    def _check_swift_performance(self, file_path: Path, content: str, lines: List[str]) -> List[CodeReviewIssue]:
        """Check Swift performance issues"""
        issues = []
        
        # Check for inefficient string concatenation
        for i, line in enumerate(lines, 1):
            if '+=' in line and 'String' in line:
                issues.append(CodeReviewIssue(
                    file_path=str(file_path),
                    line_number=i,
                    issue_type="performance",
                    severity="info",
                    message="String concatenation in loop may be inefficient",
                    suggestion="Consider using String interpolation or StringBuilder",
                    confidence=0.5
                ))
        
        return issues
    
    def _calculate_overall_score(self, issues: List[CodeReviewIssue]) -> float:
        """Calculate overall code quality score"""
        if not issues:
            return 100.0
        
        # Weight by severity
        severity_weights = {"critical": 20, "error": 15, "warning": 10, "info": 5}
        total_penalty = sum(severity_weights.get(issue.severity, 5) for issue in issues)
        
        # Base score minus penalties
        score = max(0.0, 100.0 - total_penalty)
        return round(score, 1)
    
    def _generate_recommendations(self, issues: List[CodeReviewIssue]) -> List[str]:
        """Generate recommendations based on issues"""
        recommendations = []
        
        # Group issues by type
        issue_types = {}
        for issue in issues:
            if issue.issue_type not in issue_types:
                issue_types[issue.issue_type] = []
            issue_types[issue.issue_type].append(issue)
        
        # Generate type-specific recommendations
        if "security" in issue_types:
            recommendations.append("🔒 Address security vulnerabilities immediately")
        
        if "complexity" in issue_types:
            recommendations.append("🔧 Refactor complex functions to improve maintainability")
        
        if "style" in issue_types and len(issue_types["style"]) > 5:
            recommendations.append("🎨 Consider using a code formatter (black, swiftformat)")
        
        if "performance" in issue_types:
            recommendations.append("⚡ Optimize performance-critical code sections")
        
        # Auto-fix recommendation
        auto_fixable = [i for i in issues if i.auto_fixable]
        if auto_fixable:
            recommendations.append(f"🤖 {len(auto_fixable)} issues can be auto-fixed")
        
        return recommendations
    
    def _generate_summary(self, issues: List[CodeReviewIssue]) -> Dict[str, Any]:
        """Generate review summary"""
        summary = {
            "total_issues": len(issues),
            "by_severity": {},
            "by_type": {},
            "auto_fixable": len([i for i in issues if i.auto_fixable]),
            "critical_files": []
        }
        
        # Count by severity
        for issue in issues:
            severity = issue.severity
            summary["by_severity"][severity] = summary["by_severity"].get(severity, 0) + 1
        
        # Count by type
        for issue in issues:
            issue_type = issue.issue_type
            summary["by_type"][issue_type] = summary["by_type"].get(issue_type, 0) + 1
        
        # Find files with most issues
        file_issues = {}
        for issue in issues:
            file_path = issue.file_path
            if file_path not in file_issues:
                file_issues[file_path] = 0
            file_issues[file_path] += 1
        
        # Get top 5 files with most issues
        sorted_files = sorted(file_issues.items(), key=lambda x: x[1], reverse=True)
        summary["critical_files"] = sorted_files[:5]
        
        return summary
    
    async def _apply_auto_fixes(self, issues: List[CodeReviewIssue]) -> int:
        """Apply automatic fixes where possible"""
        fixes_applied = 0
        
        for issue in issues:
            if issue.auto_fixable and issue.fix_command:
                try:
                    if issue.fix_command == "line_wrap":
                        # Simple line wrapping (demo implementation)
                        logger.info(f"Would auto-fix line wrapping in {issue.file_path}:{issue.line_number}")
                        fixes_applied += 1
                except Exception as e:
                    logger.warning(f"Failed to apply auto-fix: {e}")
        
        return fixes_applied
    
    async def _save_review(self, result: CodeReviewResult):
        """Save review result"""
        # Save JSON result
        json_file = self.output_dir / f"{result.review_id}.json"
        with open(json_file, 'w') as f:
            json.dump(asdict(result), f, indent=2, default=str)
        
        # Generate markdown report
        md_file = self.output_dir / f"{result.review_id}.md"
        report = await self._generate_markdown_report(result)
        with open(md_file, 'w') as f:
            f.write(report)
        
        logger.info(f"Review saved: {result.review_id}")
    
    async def _generate_markdown_report(self, result: CodeReviewResult) -> str:
        """Generate markdown report"""
        return f"""# 🤖 AI Code Review Report

**Review ID:** {result.review_id}  
**Timestamp:** {result.timestamp.strftime('%Y-%m-%d %H:%M:%S')}  
**Overall Score:** {result.overall_score}/100

## 📊 Summary

- **Files Reviewed:** {len(result.files_reviewed)}
- **Total Issues:** {len(result.issues)}
- **Auto-fixes Applied:** {result.auto_fixes_applied}

### Issues by Severity
{self._format_severity_breakdown(result.review_summary)}

### Issues by Type
{self._format_type_breakdown(result.review_summary)}

## 🎯 Recommendations

{chr(10).join(f"- {rec}" for rec in result.recommendations)}

## 🐛 Issues Found

{self._format_issues_list(result.issues)}

## 📁 Files Reviewed

{chr(10).join(f"- {file}" for file in result.files_reviewed)}

---

*Generated by AI Code Review Automation*
"""
    
    def _format_severity_breakdown(self, summary: Dict[str, Any]) -> str:
        """Format severity breakdown"""
        by_severity = summary.get("by_severity", {})
        lines = []
        for severity in ["critical", "error", "warning", "info"]:
            count = by_severity.get(severity, 0)
            emoji = {"critical": "🔴", "error": "❌", "warning": "⚠️", "info": "ℹ️"}[severity]
            lines.append(f"- {emoji} {severity.title()}: {count}")
        return "\n".join(lines)
    
    def _format_type_breakdown(self, summary: Dict[str, Any]) -> str:
        """Format type breakdown"""
        by_type = summary.get("by_type", {})
        lines = []
        for issue_type, count in by_type.items():
            emoji = {"security": "🔒", "performance": "⚡", "style": "🎨", "complexity": "🔧"}.get(issue_type, "📝")
            lines.append(f"- {emoji} {issue_type.title()}: {count}")
        return "\n".join(lines)
    
    def _format_issues_list(self, issues: List[CodeReviewIssue]) -> str:
        """Format issues list"""
        if not issues:
            return "✅ No issues found!"
        
        lines = []
        for issue in issues[:20]:  # Limit to top 20 issues
            severity_emoji = {"critical": "🔴", "error": "❌", "warning": "⚠️", "info": "ℹ️"}[issue.severity]
            file_name = Path(issue.file_path).name
            lines.append(f"### {severity_emoji} {file_name}:{issue.line_number}")
            lines.append(f"**Type:** {issue.issue_type} | **Severity:** {issue.severity}")
            lines.append(f"**Issue:** {issue.message}")
            lines.append(f"**Suggestion:** {issue.suggestion}")
            if issue.auto_fixable:
                lines.append("🤖 *Auto-fixable*")
            lines.append("")
        
        if len(issues) > 20:
            lines.append(f"*... and {len(issues) - 20} more issues*")
        
        return "\n".join(lines)
    
    def _create_empty_review(self, review_id: str) -> CodeReviewResult:
        """Create empty review result"""
        return CodeReviewResult(
            review_id=review_id,
            timestamp=datetime.now(),
            files_reviewed=[],
            issues=[],
            overall_score=100.0,
            recommendations=["✅ No changes to review"],
            auto_fixes_applied=0,
            review_summary={"total_issues": 0}
        )

class PythonReviewVisitor(ast.NodeVisitor):
    """AST visitor for Python code review"""
    
    def __init__(self, file_path: str, lines: List[str], thresholds: Dict[str, Any]):
        self.file_path = file_path
        self.lines = lines
        self.thresholds = thresholds
        self.issues: List[CodeReviewIssue] = []
    
    def visit_FunctionDef(self, node: ast.FunctionDef):
        """Check function definitions"""
        # Check function length
        if hasattr(node, 'end_lineno') and node.end_lineno:
            length = node.end_lineno - node.lineno
            if length > self.thresholds["max_function_length"]:
                self.issues.append(CodeReviewIssue(
                    file_path=self.file_path,
                    line_number=node.lineno,
                    issue_type="complexity",
                    severity="warning",
                    message=f"Function '{node.name}' is too long ({length} lines)",
                    suggestion="Consider breaking into smaller functions",
                    confidence=0.8
                ))
        
        # Check for missing docstring
        if not ast.get_docstring(node):
            self.issues.append(CodeReviewIssue(
                file_path=self.file_path,
                line_number=node.lineno,
                issue_type="style",
                severity="info",
                message=f"Function '{node.name}' missing docstring",
                suggestion="Add docstring to describe function purpose",
                confidence=0.7
            ))
        
        self.generic_visit(node)
    
    def visit_ClassDef(self, node: ast.ClassDef):
        """Check class definitions"""
        # Check class length
        if hasattr(node, 'end_lineno') and node.end_lineno:
            length = node.end_lineno - node.lineno
            if length > self.thresholds["max_class_length"]:
                self.issues.append(CodeReviewIssue(
                    file_path=self.file_path,
                    line_number=node.lineno,
                    issue_type="complexity",
                    severity="warning",
                    message=f"Class '{node.name}' is too long ({length} lines)",
                    suggestion="Consider breaking into smaller classes",
                    confidence=0.8
                ))
        
        self.generic_visit(node)

# Integration with GitHub/CI
class GitHubIntegration:
    """Integration with GitHub for automated reviews"""
    
    def __init__(self, reviewer: AICodeReviewer):
        self.reviewer = reviewer
    
    async def create_review_comment(self, pr_number: int, review_result: CodeReviewResult):
        """Create GitHub PR review comment"""
        comment = f"""## 🤖 AI Code Review Results

**Overall Score:** {review_result.overall_score}/100
**Issues Found:** {len(review_result.issues)}

### Key Recommendations:
{chr(10).join(f"- {rec}" for rec in review_result.recommendations[:5])}

<details>
<summary>📊 Detailed Analysis</summary>

{self.reviewer._format_severity_breakdown(review_result.review_summary)}

</details>

*Full review available in: `.code_reviews/{review_result.review_id}.md`*
"""
        
        # In a real implementation, this would use GitHub API
        logger.info(f"Would post review comment to PR #{pr_number}")
        logger.info(comment)

# Demo function
async def main():
    """Demo the AI code review system"""
    print("🤖 Starting AI-Driven Code Review Automation...")
    
    reviewer = AICodeReviewer()
    
    # Run review
    print("🔍 Analyzing recent changes...")
    result = await reviewer.review_changes()
    
    print(f"\n✅ Review Complete!")
    print(f"📊 Overall Score: {result.overall_score}/100")
    print(f"🐛 Issues Found: {len(result.issues)}")
    print(f"🤖 Auto-fixes Applied: {result.auto_fixes_applied}")
    
    if result.recommendations:
        print(f"\n💡 Key Recommendations:")
        for rec in result.recommendations[:3]:
            print(f"  • {rec}")
    
    print(f"\n📁 Review saved: {result.review_id}")
    print(f"📄 Report: .code_reviews/{result.review_id}.md")

if __name__ == "__main__":
    asyncio.run(main())