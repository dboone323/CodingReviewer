"""
CodingReviewer Testing Framework - Swift Integration

Handles Swift/Xcode test execution and result parsing.
Specialized module for Swift-specific testing operations.
"""

import asyncio
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Any

from .models import CodingTestResult, CodingTestSuite


class SwiftTestIntegration:
    """Handles Swift test execution and parsing."""
    
    def __init__(self, project_root: Path, config: Dict[str, Any]):
        self.project_root = project_root
        self.config = config
    
    async def run_swift_tests(self) -> CodingTestSuite:
        """Execute Swift tests using xcodebuild."""
        started_at = datetime.now()
        test_results: List[CodingTestResult] = []
        
        try:
            # Run xcodebuild test command
            cmd: List[str] = [
                "xcodebuild",
                "test",
                "-project", str(self.config["swift_project_path"]),
                "-scheme", self.config["swift_scheme"],
                "-destination", "platform=macOS,arch=x86_64",
                "-resultBundlePath", str(self.config["reports_path"] / "TestResults.xcresult")
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
            test_results = self._parse_swift_test_output(stdout_str, stderr_str)
            
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
        
        return suite
    
    def _parse_swift_test_output(self, stdout: str, stderr: str) -> List[CodingTestResult]:
        """Parse Swift test output into CodingTestResult objects."""
        results: List[CodingTestResult] = []
        
        # Simple parsing - look for test completion indicators
        lines = stdout.split('\n') + stderr.split('\n')
        
        for line in lines:
            line = line.strip()
            
            # Look for test result patterns
            if "Test Case" in line and ("passed" in line or "failed" in line):
                parts = line.split()
                if len(parts) >= 4:
                    # Extract test name - it's usually in parts[2] and possibly [3]
                    if len(parts) >= 4 and parts[2].startswith("'"):
                        # Format: Test Case '[-Class testMethod]' passed
                        test_name_parts = [parts[2]]
                        if len(parts) > 3 and not parts[3] in ["passed", "failed"]:
                            test_name_parts.append(parts[3])
                        test_name = " ".join(test_name_parts).replace("'", "").replace("-[", "").replace("]", "")
                    else:
                        # Fallback
                        test_name = parts[2].replace("'", "").replace("-[", "").replace("]", "")
                    
                    status = "passed" if "passed" in line else "failed"
                    
                    # Extract duration if available
                    duration = 0.0
                    for part in parts:
                        if "seconds" in part:
                            try:
                                duration = float(part.replace("(", "").replace(")", ""))
                            except ValueError:
                                pass
                    
                    results.append(CodingTestResult(
                        name=test_name,
                        status=status,
                        duration=duration,
                        error_message=line if status == "failed" else None
                    ))
        
        # If no specific test results found, create a summary result
        if not results:
            if "BUILD SUCCEEDED" in stdout:
                results.append(CodingTestResult(
                    name="swift_build_and_test",
                    status="passed",
                    duration=1.0
                ))
            else:
                results.append(CodingTestResult(
                    name="swift_build_and_test",
                    status="failed",
                    duration=1.0,
                    error_message="Swift tests failed - see output for details"
                ))
        
        return results
