"""
CodingReviewer Python Testing Framework

This module provides comprehensive testing utilities for the CodingReviewer project,
integrating with both Swift/Xcode testing and Jupyter notebook analysis.
"""

import asyncio
import json
import os
import subprocess
import sys
import time
from dataclasses import dataclass, asdict
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Any, Union
from unittest.mock import Mock, patch

import pytest
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import plotly.express as px
import plotly.graph_objects as go
from plotly.subplots import make_subplots


@dataclass
class CodingTestResult:
    """Represents a single test result."""
    name: str
    status: str  # "passed", "failed", "skipped", "error"
    duration: float
    error_message: Optional[str] = None
    file_path: Optional[str] = None
    line_number: Optional[int] = None
    timestamp: Optional[datetime] = None
    
    def __post_init__(self):
        if self.timestamp is None:
            self.timestamp = datetime.now()


@dataclass
class CodingTestSuite:
    """Represents a collection of test results."""
    name: str
    results: List[CodingTestResult]
    total_duration: float
    started_at: datetime
    completed_at: Optional[datetime] = None
    
    @property
    def passed_count(self) -> int:
        return len([r for r in self.results if r.status == "passed"])
    
    @property
    def failed_count(self) -> int:
        return len([r for r in self.results if r.status == "failed"])
    
    @property
    def skipped_count(self) -> int:
        return len([r for r in self.results if r.status == "skipped"])
    
    @property
    def error_count(self) -> int:
        return len([r for r in self.results if r.status == "error"])
    
    @property
    def total_count(self) -> int:
        return len(self.results)
    
    @property
    def success_rate(self) -> float:
        if self.total_count == 0:
            return 0.0
        return (self.passed_count / self.total_count) * 100


class CodingReviewerTestFramework:
    """Main testing framework for CodingReviewer project."""
    
    def __init__(self, project_root: Optional[Path] = None):
        self.project_root = project_root or Path.cwd()
        self.test_results: List[CodingTestSuite] = []
        self.config = self._load_config()
        
    def _load_config(self) -> Dict[str, Any]:
        """Load test configuration from various sources."""
        config = {
            "swift_project_path": self.project_root / "CodingReviewer.xcodeproj",
            "python_test_path": self.project_root / "python_tests",
            "reports_path": self.project_root / "test_reports",
            "jupyter_path": self.project_root / "jupyter_notebooks"
        }
        
        # Create directories if they don't exist
        for path in [config["python_test_path"], config["reports_path"], config["jupyter_path"]]:
            path.mkdir(exist_ok=True)
            
        return config
    
    async def run_swift_tests(self) -> CodingTestSuite:
        """Run Swift/Xcode tests and capture results."""
        print("🚀 Running Swift/Xcode tests...")
        started_at = datetime.now()
        
        try:
            # Run xcodebuild test command
            result = subprocess.run([
                "xcodebuild",
                "test",
                "-project", str(self.config["swift_project_path"]),
                "-scheme", "CodingReviewer",
                "-destination", "platform=macOS,arch=arm64"
            ], capture_output=True, text=True, cwd=self.project_root)
            
            test_results = self._parse_swift_test_output(result.stdout, result.stderr)
            
        except Exception as e:
            test_results = [CodingTestResult(
                name="swift_test_execution",
                status="error",
                duration=0.0,
                error_message=str(e)
            )]
        
        completed_at = datetime.now()
        duration = (completed_at - started_at).total_seconds()
        
        suite = CodingTestSuite(
            name="Swift Tests",
            results=test_results,
            total_duration=duration,
            started_at=started_at,
            completed_at=completed_at
        )
        
        self.test_results.append(suite)
        return suite
    
    def _parse_swift_test_output(self, stdout: str, stderr: str) -> List[CodingTestResult]:
        """Parse Swift test output into CodingTestResult objects."""
        results = []
        
        # Parse test results from output
        lines = stdout.split('\n') + stderr.split('\n')
        
        for line in lines:
            if 'Test Case' in line and ('passed' in line or 'failed' in line):
                parts = line.split()
                if len(parts) >= 4:
                    name = parts[2].strip("'")
                    status = "passed" if "passed" in line else "failed"
                    duration = 0.0
                    
                    # Try to extract duration
                    for part in parts:
                        if part.endswith('s)'):
                            try:
                                duration = float(part[1:-2])  # Remove '(' and 's)'
                                break
                            except ValueError:
                                pass
                    
                    results.append(CodingTestResult(
                        name=name,
                        status=status,
                        duration=duration
                    ))
        
        # If no specific test results found, create a summary result
        if not results:
            if "BUILD SUCCEEDED" in stdout or "Test session results" in stdout:
                results.append(CodingTestResult(
                    name="swift_build_and_test",
                    status="passed",
                    duration=0.0
                ))
            else:
                results.append(CodingTestResult(
                    name="swift_build_and_test",
                    status="failed",
                    duration=0.0,
                    error_message=stderr[:500] if stderr else "Unknown error"
                ))
        
        return results
    
    async def run_python_tests(self) -> CodingTestSuite:
        """Run Python tests using pytest."""
        print("🐍 Running Python tests...")
        started_at = datetime.now()
        
        try:
            # Run pytest with JSON report
            result = subprocess.run([
                sys.executable, "-m", "pytest",
                str(self.config["python_test_path"]),
                "--json-report",
                "--json-report-file=" + str(self.config["reports_path"] / "pytest_report.json"),
                "-v"
            ], capture_output=True, text=True, cwd=self.project_root)
            
            test_results = self._parse_pytest_output(result.stdout, result.stderr)
            
        except Exception as e:
            test_results = [CodingTestResult(
                name="python_test_execution",
                status="error", 
                duration=0.0,
                error_message=str(e)
            )]
        
        completed_at = datetime.now()
        duration = (completed_at - started_at).total_seconds()
        
        suite = CodingTestSuite(
            name="Python Tests",
            results=test_results,
            total_duration=duration,
            started_at=started_at,
            completed_at=completed_at
        )
        
        self.test_results.append(suite)
        return suite
    
    def _parse_pytest_output(self, stdout: str, stderr: str) -> List[CodingTestResult]:
        """Parse pytest output into CodingTestResult objects."""
        results = []
        
        # Try to load JSON report if available
        json_report_path = self.config["reports_path"] / "pytest_report.json"
        if json_report_path.exists():
            try:
                with open(json_report_path) as f:
                    report_data = json.load(f)
                
                for test in report_data.get("tests", []):
                    results.append(CodingTestResult(
                        name=test["nodeid"],
                        status=test["outcome"],
                        duration=test.get("duration", 0.0),
                        error_message=test.get("call", {}).get("longrepr") if test["outcome"] == "failed" else None,
                        file_path=test.get("file"),
                        line_number=test.get("line")
                    ))
                    
            except Exception as e:
                print(f"Warning: Could not parse JSON report: {e}")
        
        # Fallback to parsing stdout
        if not results:
            lines = stdout.split('\n')
            for line in lines:
                if " PASSED " in line or " FAILED " in line or " SKIPPED " in line:
                    parts = line.split()
                    if len(parts) >= 2:
                        name = parts[0]
                        status = "passed" if "PASSED" in line else ("failed" if "FAILED" in line else "skipped")
                        results.append(CodingTestResult(
                            name=name,
                            status=status,
                            duration=0.0
                        ))
        
        return results
    
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
            report["suites"].append(suite_data)
            
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
            "overall_success_rate": (total_passed / total_tests * 100) if total_tests > 0 else 0.0,
            "total_duration": total_duration
        }
        
        return report
    
    def save_report(self, report: Dict[str, Any], filename: Optional[str] = None) -> Path:
        """Save test report to file."""
        if filename is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"test_report_{timestamp}.json"
        
        report_path = self.config["reports_path"] / filename
        with open(report_path, 'w') as f:
            json.dump(report, f, indent=2, default=str)
        
        print(f"📊 Test report saved to: {report_path}")
        return report_path
    
    async def run_all_tests(self) -> Dict[str, Any]:
        """Run all tests (Swift and Python) and generate report."""
        print("🧪 Running comprehensive test suite...")
        
        # Run Swift tests
        await self.run_swift_tests()
        
        # Run Python tests
        await self.run_python_tests()
        
        # Generate and save report
        report = self.generate_test_report()
        self.save_report(report)
        
        return report


class TestVisualization:
    """Visualization utilities for test results."""
    
    @staticmethod
    def create_test_dashboard(report: Dict[str, Any]) -> go.Figure:
        """Create interactive test dashboard using Plotly."""
        fig = make_subplots(
            rows=2, cols=2,
            subplot_titles=("Test Results Summary", "Success Rate by Suite", 
                          "Test Duration", "Test Status Distribution"),
            specs=[[{"type": "bar"}, {"type": "bar"}],
                   [{"type": "scatter"}, {"type": "pie"}]]
        )
        
        # Extract data
        suites = report["suites"]
        suite_names = [s["name"] for s in suites]
        passed_counts = [s["passed_count"] for s in suites]
        failed_counts = [s["failed_count"] for s in suites]
        success_rates = [s["success_rate"] for s in suites]
        durations = [s["duration"] for s in suites]
        
        # Test Results Summary (Stacked Bar)
        fig.add_trace(
            go.Bar(name="Passed", x=suite_names, y=passed_counts, marker_color="green"),
            row=1, col=1
        )
        fig.add_trace(
            go.Bar(name="Failed", x=suite_names, y=failed_counts, marker_color="red"),
            row=1, col=1
        )
        
        # Success Rate by Suite
        fig.add_trace(
            go.Bar(x=suite_names, y=success_rates, marker_color="blue", showlegend=False),
            row=1, col=2
        )
        
        # Test Duration
        fig.add_trace(
            go.Scatter(x=suite_names, y=durations, mode="markers+lines", 
                      marker_size=10, marker_color="orange", showlegend=False),
            row=2, col=1
        )
        
        # Overall Status Distribution
        summary = report["summary"]
        labels = ["Passed", "Failed", "Skipped", "Errors"]
        values = [summary["total_passed"], summary["total_failed"], 
                 summary["total_skipped"], summary["total_errors"]]
        colors = ["green", "red", "yellow", "purple"]
        
        fig.add_trace(
            go.Pie(labels=labels, values=values, marker_colors=colors, showlegend=False),
            row=2, col=2
        )
        
        # Update layout
        fig.update_layout(
            title_text="CodingReviewer Test Dashboard",
            showlegend=True,
            height=800
        )
        
        return fig


# Utility functions for common testing patterns
def mock_swift_service():
    """Create a mock Swift service for testing."""
    mock = Mock()
    mock.analyze_code.return_value = {"status": "success", "issues": []}
    mock.generate_tests.return_value = {"tests": ["test1", "test2"]}
    return mock


def create_sample_test_data() -> List[CodingTestResult]:
    """Create sample test data for visualization testing."""
    return [
        CodingTestResult("test_swift_analyzer", "passed", 0.123),
        CodingTestResult("test_ml_model", "failed", 0.456, "AssertionError: Model accuracy below threshold"),
        CodingTestResult("test_ui_components", "passed", 0.789),
        CodingTestResult("test_data_processing", "skipped", 0.0, "Test data not available"),
        CodingTestResult("test_api_integration", "passed", 1.234),
        CodingTestResult("test_performance", "failed", 2.345, "Timeout after 2 seconds"),
        CodingTestResult("test_security_checks", "passed", 0.567),
        CodingTestResult("test_documentation", "passed", 0.098),
    ]


if __name__ == "__main__":
    # Example usage
    async def main():
        framework = CodingReviewerTestFramework()
        report = await framework.run_all_tests()
        
        # Create visualization
        viz = TestVisualization()
        fig = viz.create_test_dashboard(report)
        fig.show()
    
    asyncio.run(main())
