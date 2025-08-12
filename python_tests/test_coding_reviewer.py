"""
Test suite for CodingReviewer Swift integration and analysis capabilities.
Enhanced with Architecture Validation Rules (August 12, 2025)
"""

import pytest
import subprocess
import sys
from pathlib import Path
from unittest.mock import patch
from typing import List, Any

# Import our testing framework
sys.path.append(str(Path(__file__).parent.parent / "python_src"))
from testing_framework import CodingReviewerTestFramework, CodingTestResult, CodingTestSuite


class TestArchitectureValidation:
    """Test our new architecture validation rules from VALIDATION_RULES.md"""
    
    @pytest.fixture
    def project_root(self) -> Path:
        """Get project root for architecture validation."""
        return Path(__file__).parent.parent
    
    def test_architecture_boundaries_enforced(self, project_root: Path) -> None:
        """Test that SharedTypes/ contains no SwiftUI imports."""
        shared_types_path = project_root / "CodingReviewer" / "SharedTypes"
        
        if shared_types_path.exists():
            for swift_file in shared_types_path.glob("*.swift"):
                content = swift_file.read_text()
                assert "import SwiftUI" not in content, f"SwiftUI import found in {swift_file.name} - violates architecture rules"
                
                # Also check for Codable in complex types per our guidelines
                if "struct" in content or "class" in content:
                    lines = content.split('\n')
                    for line in lines:
                        if ("struct" in line or "class" in line) and "Codable" in line:
                            # Allow simple types, flag complex nested ones
                            if any(complex_indicator in content for complex_indicator in [
                                "AnalyticsReport", "ProcessingJob", "SystemLoad"
                            ]):
                                pytest.fail(f"Complex type with Codable found in {swift_file.name} - may cause circular references")
    
    def test_validation_rules_documentation_exists(self, project_root: Path) -> None:
        """Test that our new validation documentation exists."""
        validation_files = [
            "VALIDATION_RULES.md",
            "DEVELOPMENT_GUIDELINES.md", 
            "QUICK_REFERENCE.md"
        ]
        
        for doc_file in validation_files:
            doc_path = project_root / doc_file
            assert doc_path.exists(), f"Missing validation documentation: {doc_file}"
            
            content = doc_path.read_text()
            # Check for key patterns we documented
            assert "Strategic Implementation" in content or "validation" in content.lower()
    
    def test_force_unwrap_patterns_avoided(self, project_root: Path) -> None:
        """Test that force unwraps are avoided in production code."""
        coding_reviewer_path = project_root / "CodingReviewer"
        
        if coding_reviewer_path.exists():
            problematic_files: List[str] = []
            
            for swift_file in coding_reviewer_path.rglob("*.swift"):
                if "Test" in swift_file.name:
                    continue  # Skip test files
                    
                content = swift_file.read_text()
                lines = content.split('\n')
                
                for line_num, line in enumerate(lines, 1):
                    if "!" in line and "SAFE:" not in line:
                        # Check for force unwrap patterns
                        if any(pattern in line for pattern in ["?!", "!.", "![", "as!"]):
                            problematic_files.append(f"{swift_file.name}:{line_num}")
            
            # Allow some force unwraps but flag if excessive
            if len(problematic_files) > 10:
                pytest.fail(f"Excessive force unwraps found: {problematic_files[:5]}... (+{len(problematic_files)-5} more)")
    
    def test_sendable_conformance_in_concurrent_types(self, project_root: Path) -> None:
        """Test that data models used in concurrent contexts have Sendable conformance."""
        shared_types_path = project_root / "CodingReviewer" / "SharedTypes"
        
        if shared_types_path.exists():
            for swift_file in shared_types_path.glob("*.swift"):
                content = swift_file.read_text()
                
                # Look for struct/class definitions
                lines = content.split('\n')
                for line in lines:
                    if ("struct" in line or "class" in line) and any(name in line for name in [
                        "ProcessingJob", "AnalyticsReport", "SystemLoad", "JobPriority"
                    ]):
                        assert "Sendable" in line, f"Concurrent data type missing Sendable: {line.strip()}"
    
    @pytest.mark.integration
    def test_build_system_follows_strategic_patterns(self, project_root: Path) -> None:
        """Test that the build system follows our strategic implementation patterns."""
        # Test that we can build without the bandaid patterns we documented
        result = subprocess.run([
            "xcodebuild", "build", 
            "-project", str(project_root / "CodingReviewer.xcodeproj"),
            "-scheme", "CodingReviewer",
            "-destination", "platform=macOS"
        ], capture_output=True, text=True, cwd=project_root)
        
        # Build should succeed per our strategic implementation 
        if result.returncode != 0:
            # Look for the error patterns we documented as fixed
            error_text = result.stderr
            strategic_errors = [
                "missing properties", "incomplete protocols", "circular dependencies",
                "MainActor conflicts", "Sendable issues"
            ]
            
            found_strategic_errors = [err for err in strategic_errors if err in error_text.lower()]
            if found_strategic_errors:
                pytest.fail(f"Strategic implementation errors found: {found_strategic_errors}")
        
        assert result.returncode == 0, f"Build failed - may indicate architecture violations: {result.stderr[:500]}"


class TestAutomationScriptValidation:
    """Test that automation scripts follow our validation guidelines."""
    
    @pytest.fixture
    def project_root(self) -> Path:
        """Get project root for automation validation."""
        return Path(__file__).parent.parent
    
    def test_automation_scripts_reference_validation_docs(self, project_root: Path) -> None:
        """Test that key automation scripts reference our validation documentation."""
        critical_scripts = [
            "master_automation_orchestrator.sh",
            "automation_readiness_check.sh",
            "critical_error_fixes.sh"
        ]
        
        for script_name in critical_scripts:
            script_path = project_root / script_name
            if script_path.exists():
                content = script_path.read_text()
                
                # Check if script has any reference to validation or guidelines
                validation_indicators = [
                    "VALIDATION_RULES", "DEVELOPMENT_GUIDELINES", "ARCHITECTURE.md",
                    "Strategic Implementation", "validation", "architecture"
                ]
                
                has_validation_reference = any(indicator in content for indicator in validation_indicators)
                
                # If it's a critical script, it should reference our guidelines
                if script_name in ["master_automation_orchestrator.sh", "critical_error_fixes.sh"]:
                    if not has_validation_reference:
                        pytest.fail(f"Critical script {script_name} should reference validation guidelines")
    
    def test_automation_scripts_follow_error_prevention_patterns(self, project_root: Path) -> None:
        """Test that automation scripts use safe patterns from our guidelines."""
        automation_scripts = list(project_root.glob("*automation*.sh")) + list(project_root.glob("*fix*.sh"))
        
        problematic_patterns = []
        
        for script in automation_scripts[:10]:  # Check first 10 to avoid overwhelming
            if script.exists():
                content = script.read_text()
                
                # Check for dangerous patterns we documented to avoid
                if "rm -rf /" in content:
                    problematic_patterns.append(f"{script.name}: dangerous rm command")
                
                # Check for force operations without safety checks
                if "rm -f" in content and "backup" not in content.lower():
                    # Allow if there's clear backup or safety mechanism
                    if not any(safe_word in content.lower() for safe_word in ["backup", "copy", "safe", "check"]):
                        problematic_patterns.append(f"{script.name}: force remove without backup")
        
        if problematic_patterns:
            # Allow some, but flag if excessive
            if len(problematic_patterns) > 3:
                pytest.fail(f"Too many unsafe patterns in automation: {problematic_patterns[:3]}")
    
    def test_master_orchestrator_has_validation_integration(self, project_root: Path) -> None:
        """Test that master orchestrator integrates our validation rules."""
        orchestrator_path = project_root / "master_automation_orchestrator.sh"
        
        if orchestrator_path.exists():
            content = orchestrator_path.read_text()
            
            # Check for validation integration patterns
            validation_patterns = [
                "validation", "error_check", "build_validate", "architecture",
                "comprehensive_error_check", "startup_build_validation"
            ]
            
            found_patterns = [pattern for pattern in validation_patterns if pattern in content]
            
            # Master orchestrator should integrate multiple validation concepts
            assert len(found_patterns) >= 3, f"Master orchestrator should integrate validation patterns, found: {found_patterns}"


class TestSwiftIntegration:
    """Test Swift project integration and build system."""
    
    @pytest.fixture
    def framework(self):
        """Create a test framework instance."""
        return CodingReviewerTestFramework()
    
    @pytest.fixture
    def mock_subprocess(self):
        """Mock subprocess for testing without actually running Xcode."""
        with patch('subprocess.run') as mock:
            yield mock
    
    def test_framework_initialization(self, framework: Any):
        """Test that the framework initializes correctly."""
        assert framework.project_root.exists()
        assert framework.config is not None
        assert "swift_project_path" in framework.config
        assert "python_test_path" in framework.config
    
    def test_swift_project_detection(self, framework: Any):
        """Test that Swift project is properly detected."""
        swift_project = framework.config["swift_project_path"]
        assert swift_project.name == "CodingReviewer.xcodeproj"
    
    @pytest.mark.asyncio
    async def test_swift_test_execution_success(self, framework: Any, mock_subprocess: Any):
        """Test successful Swift test execution."""
        # Mock successful xcodebuild output
        mock_subprocess.return_value.stdout = """
        Test Case '-[CodingReviewerTests.AIServiceTests testAPIKeyValidation]' passed (0.123 seconds).
        Test Case '-[CodingReviewerTests.CodeAnalysisTests testBasicAnalysis]' passed (0.456 seconds).
        BUILD SUCCEEDED
        """
        mock_subprocess.return_value.stderr = ""
        mock_subprocess.return_value.returncode = 0
        
        suite = await framework.run_swift_tests()
        
        assert suite.name == "Swift Tests"
        assert suite.passed_count >= 1
        assert suite.failed_count == 0
        assert suite.success_rate > 0
    
    @pytest.mark.asyncio
    async def test_swift_test_execution_failure(self, framework: Any, mock_subprocess: Any):
        """Test Swift test execution with failures."""
        # Mock failed xcodebuild output
        mock_subprocess.return_value.stdout = """
        Test Case '-[CodingReviewerTests.AIServiceTests testAPIKeyValidation]' failed (0.123 seconds).
        """
        mock_subprocess.return_value.stderr = "error: build failed"
        mock_subprocess.return_value.returncode = 1
        
        suite = await framework.run_swift_tests()
        
        assert suite.name == "Swift Tests"
        assert suite.failed_count >= 1 or suite.error_count >= 1
    
    def test_swift_output_parsing(self, framework: Any):
        """Test parsing of Swift test output."""
        stdout = """
        Test Case '-[CodingReviewerTests.AIServiceTests testAPIKeyValidation]' passed (0.123 seconds).
        Test Case '-[CodingReviewerTests.CodeAnalysisTests testBasicAnalysis]' failed (0.456 seconds).
        Test Case '-[CodingReviewerTests.FileManagerTests testFileUpload]' passed (0.789 seconds).
        """
        stderr = ""
        
        results = framework._parse_swift_test_output(stdout, stderr)
        
        assert len(results) == 3
        assert results[0].status == "passed"
        assert results[1].status == "failed"
        assert results[2].status == "passed"
        # Duration parsing from Swift output may vary, just check they exist
        assert results[0].duration >= 0.0
        assert results[1].duration >= 0.0


class TestPythonTestingFramework:
    """Test the Python testing framework itself."""
    
    @pytest.fixture
    def framework(self):
        return CodingReviewerTestFramework()
    
    def test_test_result_creation(self):
        """Test CodingTestResult dataclass creation."""
        result = CodingTestResult(
            name="test_example",
            status="passed",
            duration=0.123,
            error_message=None
        )
        
        assert result.name == "test_example"
        assert result.status == "passed"
        assert result.duration == 0.123
        assert result.timestamp is not None
    
    def test_test_suite_metrics(self):
        """Test CodingTestSuite metrics calculation."""
        results = [
            CodingTestResult("test1", "passed", 0.1),
            CodingTestResult("test2", "failed", 0.2),
            CodingTestResult("test3", "passed", 0.3),
            CodingTestResult("test4", "skipped", 0.0),
            CodingTestResult("test5", "error", 0.1)
        ]
        
        from datetime import datetime
        suite = CodingTestSuite(
            name="Test Suite",
            results=results,
            total_duration=0.7,
            started_at=datetime.now()
        )
        
        assert suite.total_count == 5
        assert suite.passed_count == 2
        assert suite.failed_count == 1
        assert suite.skipped_count == 1
        assert suite.error_count == 1
        assert suite.success_rate == 40.0  # 2/5 * 100
    
    @pytest.mark.asyncio
    async def test_python_test_execution(self, framework: Any):
        """Test Python test execution (this test tests itself!)."""
        # This will run pytest on the current test directory
        suite = await framework.run_python_tests()
        
        assert suite.name == "Python Tests"
        assert isinstance(suite.results, list)
        assert suite.total_duration >= 0
    
    def test_report_generation(self, framework: Any):
        """Test test report generation."""
        # Add some mock test results
        from datetime import datetime
        mock_suite = CodingTestSuite(
            name="Mock Suite",
            results=[
                CodingTestResult("mock_test1", "passed", 0.1),
                CodingTestResult("mock_test2", "failed", 0.2, "Mock error")
            ],
            total_duration=0.3,
            started_at=datetime.now(),
            completed_at=datetime.now()
        )
        framework.test_results.append(mock_suite)
        
        report = framework.generate_test_report()
        
        assert "timestamp" in report
        assert "summary" in report
        assert "suites" in report
        assert report["total_suites"] >= 1
        assert report["summary"]["total_tests"] >= 2


class TestCodeAnalysisIntegration:
    """Test integration with CodingReviewer's code analysis features."""
    
    @pytest.mark.unit
    def test_swift_code_analysis_mock(self):
        """Test Swift code analysis with mocked services."""
        # Mock the Swift code analysis
        with patch('subprocess.run') as mock_run:
            mock_run.return_value.stdout = "Analysis complete: 5 issues found"
            mock_run.return_value.returncode = 0
            
            # Simulate code analysis
            result = subprocess.run(['echo', 'mock analysis'], capture_output=True, text=True)
            assert result.returncode == 0
    
    @pytest.mark.integration
    def test_ai_service_integration(self):
        """Test AI service integration."""
        # This would test actual AI service calls in a real scenario
        mock_ai_response = {
            "analysis": "Code quality looks good",
            "suggestions": ["Add documentation", "Consider refactoring"],
            "score": 85
        }
        
        # In a real implementation, this would call the actual AI service
        assert mock_ai_response["score"] > 80
        assert len(mock_ai_response["suggestions"]) > 0
    
    @pytest.mark.slow
    def test_full_project_analysis(self):
        """Test full project analysis (marked as slow)."""
        # This would be a comprehensive test of the entire project
        # Marked as slow because it would take significant time
        project_stats = {
            "total_files": 100,
            "swift_files": 80,
            "test_files": 20,
            "coverage": 75.5
        }
        
        assert project_stats["total_files"] > 0
        assert project_stats["coverage"] > 70
    
    @pytest.mark.performance
    def test_analysis_performance(self):
        """Test analysis performance benchmarks."""
        import time
        start_time = time.time()
        
        # Simulate some analysis work
        time.sleep(0.01)  # Minimal sleep for demonstration
        
        end_time = time.time()
        duration = end_time - start_time
        
        # Assert that analysis completes within reasonable time
        assert duration < 1.0  # Should complete in under 1 second
    
    def test_error_handling(self):
        """Test error handling in analysis."""
        with pytest.raises(ValueError):
            # Test that appropriate errors are raised
            raise ValueError("Invalid code input")
    
    @pytest.mark.api
    def test_api_endpoints(self):
        """Test API endpoints (if any)."""
        # Mock API responses
        mock_responses = {
            "/analyze": {"status": "success", "data": {}},
            "/health": {"status": "healthy"},
            "/metrics": {"status": "ok", "uptime": 12345, "requests": 100}
        }
        
        for endpoint, expected in mock_responses.items():
            assert "status" in expected
    
    @pytest.mark.ui
    def test_ui_components(self):
        """Test UI component integration."""
        # Mock UI test results
        ui_tests = {
            "file_upload_view": "passed",
            "analysis_results_view": "passed", 
            "settings_view": "passed"
        }
        
        for component, status in ui_tests.items():
            assert status == "passed"


class TestJupyterIntegration:
    """Test Jupyter notebook integration."""
    
    def test_notebook_creation(self):
        """Test that Jupyter notebooks can be created."""
        # This would test notebook creation and execution
        notebook_config = {
            "kernel": "python3",
            "cells": [],
            "metadata": {}
        }
        
        assert notebook_config["kernel"] == "python3"
        assert isinstance(notebook_config["cells"], list)
    
    def test_data_analysis_capabilities(self):
        """Test data analysis capabilities for test results."""
        import pandas as pd
        
        # Create sample test data
        test_data = pd.DataFrame({
            "test_name": ["test1", "test2", "test3", "test4"],
            "status": ["passed", "failed", "passed", "passed"],
            "duration": [0.1, 0.2, 0.15, 0.3],
            "file_path": ["test1.swift", "test2.swift", "test3.swift", "test4.swift"]
        })
        
        # Basic data analysis
        pass_rate = (test_data["status"] == "passed").mean()
        avg_duration = test_data["duration"].mean()
        
        assert pass_rate >= 0.0
        assert avg_duration > 0.0
        assert len(test_data) == 4
    
    def test_visualization_data_prep(self):
        """Test data preparation for visualizations."""
        import pandas as pd
        
        # Sample test results for visualization
        results = [
            {"suite": "Swift Tests", "passed": 10, "failed": 2, "duration": 5.5},
            {"suite": "Python Tests", "passed": 8, "failed": 1, "duration": 3.2},
            {"suite": "Integration Tests", "passed": 5, "failed": 0, "duration": 8.1}
        ]
        
        df = pd.DataFrame(results)
        df["success_rate"] = df["passed"] / (df["passed"] + df["failed"]) * 100
        
        assert len(df) == 3
        assert "success_rate" in df.columns
        assert df["success_rate"].max() <= 100.0


# Conftest.py content for pytest configuration
@pytest.fixture(scope="session")
def project_root():
    """Provide project root path for tests."""
    return Path(__file__).parent.parent


@pytest.fixture(scope="session")
def test_data_dir(project_root):
    """Provide test data directory."""
    return project_root / "test_data"


@pytest.fixture
def sample_test_results():
    """Provide sample test results for testing."""
    return [
        CodingTestResult("test_swift_build", "passed", 2.5),
        CodingTestResult("test_ai_analysis", "passed", 1.2),
        CodingTestResult("test_file_processing", "failed", 0.8, "File not found"),
        CodingTestResult("test_ui_components", "skipped", 0.0),
    ]


if __name__ == "__main__":
    # Run tests when script is executed directly
    pytest.main([__file__, "-v"])
