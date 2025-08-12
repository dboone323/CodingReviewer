"""
Pytest configuration for CodingReviewer test suite.
Enhanced with Architecture Validation (August 12, 2025).
"""

import pytest
from pathlib import Path
from typing import List
import subprocess
import sys

# Add the python_src directory to the path for imports
sys.path.insert(0, str(Path(__file__).parent.parent / "python_src"))

from testing_framework import CodingTestResult


@pytest.fixture(scope="session")
def project_root() -> Path:
    """Provide project root path for tests."""
    return Path(__file__).parent.parent


@pytest.fixture(scope="session")
def test_data_dir(project_root: Path) -> Path:
    """Provide test data directory."""
    return project_root / "test_data"


@pytest.fixture
def sample_test_results() -> List[CodingTestResult]:
    """Provide sample test results for testing."""
    return [
        CodingTestResult("test_swift_build", "passed", 2.5),
        CodingTestResult("test_ai_analysis", "passed", 1.2),
        CodingTestResult("test_file_processing", "failed", 0.8, "File not found"),
        CodingTestResult("test_ui_components", "skipped", 0.0),
    ]


@pytest.fixture(scope="session")
def validation_rules_available(project_root: Path) -> bool:
    """Check if our validation rules documentation is available."""
    validation_files = [
        "VALIDATION_RULES.md",
        "DEVELOPMENT_GUIDELINES.md",
        "ARCHITECTURE.md",
        "QUICK_REFERENCE.md"
    ]
    
    return all((project_root / doc).exists() for doc in validation_files)


@pytest.fixture(scope="session")
def validation_script_available(project_root: Path) -> bool:
    """Check if our validation script is available and executable."""
    validation_script = project_root / "validation_script.sh"
    return validation_script.exists() and validation_script.stat().st_mode & 0o111


@pytest.fixture
def architecture_validated(project_root: Path, validation_script_available: bool) -> bool:
    """Run architecture validation if script is available."""
    if not validation_script_available:
        return False
    
    try:
        result = subprocess.run([
            str(project_root / "validation_script.sh"), "--architecture"
        ], capture_output=True, text=True, cwd=project_root)
        return result.returncode == 0
    except Exception:
        return False


# Pytest configuration
def pytest_configure(config):
    """Configure pytest with our custom markers."""
    config.addinivalue_line(
        "markers", "architecture: marks tests as architecture validation tests"
    )
    config.addinivalue_line(
        "markers", "validation: marks tests as validation rule tests"
    )
    config.addinivalue_line(
        "markers", "strategic: marks tests related to strategic implementation patterns"
    )


def pytest_collection_modifyitems(config, items):
    """Modify test collection to add markers based on test names."""
    for item in items:
        # Add architecture marker to architecture-related tests
        if "architecture" in item.name.lower():
            item.add_marker(pytest.mark.architecture)
        
        # Add validation marker to validation-related tests
        if "validation" in item.name.lower():
            item.add_marker(pytest.mark.validation)
        
        # Add strategic marker to strategic implementation tests
        if "strategic" in item.name.lower():
            item.add_marker(pytest.mark.strategic)


def pytest_runtest_setup(item):
    """Setup hook that runs before each test."""
    # Skip validation tests if validation rules are not available
    if item.get_closest_marker("validation"):
        project_root = Path(__file__).parent.parent
        validation_files = [
            "VALIDATION_RULES.md",
            "DEVELOPMENT_GUIDELINES.md",
            "ARCHITECTURE.md"
        ]
        
        missing_files = [f for f in validation_files if not (project_root / f).exists()]
        if missing_files:
            pytest.skip(f"Validation documentation missing: {missing_files}")


@pytest.fixture(autouse=True)
def log_test_info(request):
    """Automatically log test information for all tests."""
    print(f"\n🧪 Running test: {request.node.name}")
    
    # Check if this is a validation-related test
    if hasattr(request.node, 'get_closest_marker'):
        if request.node.get_closest_marker("validation"):
            print("📋 This test validates our architecture rules")
        elif request.node.get_closest_marker("architecture"):
            print("🏗️ This test checks architecture compliance")
        elif request.node.get_closest_marker("strategic"):
            print("🎯 This test validates strategic implementation patterns")


# Performance tracking for validation tests
@pytest.fixture
def performance_tracker():
    """Track performance of validation operations."""
    import time
    
    class PerformanceTracker:
        def __init__(self):
            self.start_time = None
            self.measurements = {}
        
        def start(self, operation: str):
            self.start_time = time.time()
            self.current_operation = operation
        
        def end(self):
            if self.start_time:
                duration = time.time() - self.start_time
                self.measurements[self.current_operation] = duration
                return duration
            return 0
        
        def get_summary(self):
            return self.measurements
    
    return PerformanceTracker()


# Hook to report validation test results
def pytest_terminal_summary(terminalreporter, exitstatus, config):
    """Add validation summary to test report."""
    validation_tests = [
        item for item in terminalreporter.stats.get('passed', [])
        if hasattr(item, 'get_closest_marker') and item.get_closest_marker('validation')
    ]
    
    if validation_tests:
        terminalreporter.write_sep("=", "VALIDATION TEST SUMMARY")
        terminalreporter.write_line(f"✅ {len(validation_tests)} validation tests passed")
        terminalreporter.write_line("🎯 Architecture rules are being enforced")
        terminalreporter.write_line("📚 See VALIDATION_RULES.md for details")


if __name__ == "__main__":
    # Run basic validation if this file is executed directly
    project_root = Path(__file__).parent.parent
    validation_script = project_root / "validation_script.sh"
    
    if validation_script.exists():
        print("🔍 Running validation script...")
        try:
            result = subprocess.run([str(validation_script), "--quick"], 
                                    capture_output=True, text=True, cwd=project_root)
            if result.returncode == 0:
                print("✅ Quick validation passed")
            else:
                print("❌ Validation issues detected")
                print(result.stdout)
        except Exception as e:
            print(f"⚠️ Could not run validation: {e}")
    else:
        print("⚠️ Validation script not found")
