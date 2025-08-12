"""
CodingReviewer Testing Framework - Python Integration

Handles Python/pytest test execution and result parsing.
Specialized module for Python-specific testing operations.
"""

import asyncio
import json
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Any

from .models import CodingTestResult, CodingTestSuite


class PythonTestIntegration:
    """Handles Python/pytest test execution and parsing."""
    
    def __init__(self, project_root: Path, config: Dict[str, Any]):
        self.project_root = project_root
        self.config = config
    
    async def run_python_tests(self) -> CodingTestSuite:
        """Execute Python tests using pytest."""
        started_at = datetime.now()
        test_results: List[CodingTestResult] = []
        
        try:
            # Run pytest with JSON report
            cmd: List[str] = [
                "python", "-m", "pytest",
                str(self.config["python_test_path"]),
                "-v",
                "--json-report",
                "--json-report-file=" + str(self.config["reports_path"] / "pytest_report.json"),
                "--tb=short"
            ]
            
            process = await asyncio.create_subprocess_exec(
                *cmd,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
                cwd=self.project_root
            )
            
            stdout, stderr = await process.communicate()
            stdout_str = stdout.decode() if stdout else ""
            stderr_str = stderr.decode() if stderr else ""
            
            # Parse the test output
            test_results = self._parse_pytest_output(stdout_str, stderr_str)
            
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
        
        return suite
    
    def _parse_pytest_output(self, stdout: str, stderr: str) -> List[CodingTestResult]:
        """Parse pytest output into CodingTestResult objects."""
        results: List[CodingTestResult] = []
        
        # Try to load JSON report if available
        json_report_path = self.config["reports_path"] / "pytest_report.json"
        if json_report_path.exists():
            try:
                with open(json_report_path) as f:
                    report_data = json.load(f)
                
                for test in report_data.get("tests", []):
                    results.append(CodingTestResult(  # type: ignore  # typed append
                        name=test["nodeid"],
                        status=test["outcome"],
                        duration=test.get("duration", 0.0),
                        error_message=test.get("call", {}).get("longrepr") if test["outcome"] == "failed" else None,
                        file_path=test.get("file"),
                        line_number=test.get("lineno")
                    ))
                
                return results
                
            except Exception as e:
                print(f"Warning: Could not parse JSON report: {e}")
        
        # Fallback: Parse text output
        lines = stdout.split('\n')
        for line in lines:
            line = line.strip()
            
            if "::" in line and ("PASSED" in line or "FAILED" in line or "SKIPPED" in line):
                parts = line.split("::")
                if len(parts) >= 2:
                    test_name = "::".join(parts[:-1])
                    result_part = parts[-1]
                    
                    if "PASSED" in result_part:
                        status = "passed"
                    elif "FAILED" in result_part:
                        status = "failed"
                    elif "SKIPPED" in result_part:
                        status = "skipped"
                    else:
                        status = "unknown"
                    
                    results.append(CodingTestResult(
                        name=test_name,
                        status=status,
                        duration=0.1  # Default duration for text parsing
                    ))
        
        # If no results found, create a summary
        if not results:
            if "passed" in stdout.lower():
                results.append(CodingTestResult(
                    name="python_tests_summary",
                    status="passed",
                    duration=1.0
                ))
            else:
                results.append(CodingTestResult(
                    name="python_tests_summary",
                    status="failed",
                    duration=1.0,
                    error_message="Python tests failed - see output for details"
                ))
        
        return results
