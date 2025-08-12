"""
CodingReviewer Testing Framework - Report Generator

Handles test report generation and file operations.
Focused module for creating comprehensive test reports.
"""

import json
from dataclasses import asdict
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Any, Optional

from .models import CodingTestSuite


class TestReportGenerator:
    """Handles test report generation and file operations."""
    
    def __init__(self, project_root: Path, config: Dict[str, Any]):
        self.project_root = project_root
        self.config = config
        self.test_results: List[CodingTestSuite] = []
    
    def add_test_suite(self, suite: CodingTestSuite) -> None:
        """Add a test suite to the report."""
        self.test_results.append(suite)
    
    def generate_test_report(self) -> Dict[str, Any]:
        """Generate comprehensive test report."""
        report = {
            "timestamp": datetime.now().isoformat(),
            "project_root": str(self.project_root),
            "total_suites": len(self.test_results),
            "suites": []
        }
        
        total_tests = 0
        total_passed = 0
        total_failed = 0
        total_duration = 0.0
        
        for suite in self.test_results:
            suite_data = {
                "name": suite.name,
                "total_count": suite.total_count,
                "passed_count": suite.passed_count,
                "failed_count": suite.failed_count,
                "skipped_count": suite.skipped_count,
                "error_count": suite.error_count,
                "success_rate": suite.success_rate,
                "duration": suite.total_duration,
                "started_at": suite.started_at.isoformat(),
                "completed_at": suite.completed_at.isoformat() if suite.completed_at else None,
                "tests": [asdict(result) for result in suite.results]
            }
            report["suites"].append(suite_data)  # type: ignore  # typed dict append
            
            total_tests += suite.total_count
            total_passed += suite.passed_count
            total_failed += suite.failed_count
            total_duration += suite.total_duration
        
        report["summary"] = {
            "total_tests": total_tests,
            "total_passed": total_passed,
            "total_failed": total_failed,
            "total_skipped": sum(s.skipped_count for s in self.test_results),
            "total_errors": sum(s.error_count for s in self.test_results),
            "overall_success_rate": (total_passed / total_tests * 100.0) if total_tests > 0 else 0.0,
            "total_duration": total_duration
        }
        
        return report
    
    def save_report(self, report: Dict[str, Any], filename: Optional[str] = None) -> Path:
        """Save test report to file."""
        if filename is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"test_report_{timestamp}.json"
        
        reports_path = self.config["reports_path"]
        reports_path.mkdir(exist_ok=True)
        
        report_file = reports_path / filename
        with open(report_file, 'w') as f:
            json.dump(report, f, indent=2, default=str)
        
        return report_file
    
    def clear_results(self) -> None:
        """Clear stored test results."""
        self.test_results.clear()
    
    def get_latest_results(self) -> List[CodingTestSuite]:
        """Get the latest test results."""
        return self.test_results.copy()
    
    def generate_summary_text(self) -> str:
        """Generate a human-readable summary of test results."""
        if not self.test_results:
            return "No test results available."
        
        total_tests = sum(suite.total_count for suite in self.test_results)
        total_passed = sum(suite.passed_count for suite in self.test_results)
        total_failed = sum(suite.failed_count for suite in self.test_results)
        total_duration = sum(suite.total_duration for suite in self.test_results)
        
        success_rate = (total_passed / total_tests * 100.0) if total_tests > 0 else 0.0
        
        summary = f"""
Test Execution Summary
=====================

Total Suites: {len(self.test_results)}
Total Tests: {total_tests}
Passed: {total_passed}
Failed: {total_failed}
Success Rate: {success_rate:.1f}%
Total Duration: {total_duration:.2f}s

Suite Details:
"""
        
        for suite in self.test_results:
            summary += f"- {suite.name}: {suite.passed_count}/{suite.total_count} passed ({suite.success_rate:.1f}%)\n"
        
        return summary
