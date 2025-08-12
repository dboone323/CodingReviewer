"""
CodingReviewer Testing Framework - Utilities

Utility functions, mock services, and sample data creation.
Helper functions for testing and development.
"""

import asyncio
from typing import List
from unittest.mock import Mock

from .models import CodingTestResult


def mock_swift_service():
    """Create a mock Swift service for testing."""
    mock = Mock()
    mock.run_tests.return_value = [
        CodingTestResult(name="test_example", status="passed", duration=1.0)
    ]
    return mock


def create_sample_test_data() -> List[CodingTestResult]:
    """Create sample test data for development and testing."""
    return [
        CodingTestResult(
            name="test_authentication",
            status="passed",
            duration=0.5,
            file_path="tests/test_auth.py",
            line_number=42
        ),
        CodingTestResult(
            name="test_data_processing",
            status="failed",
            duration=2.1,
            error_message="AssertionError: Expected 5, got 3",
            file_path="tests/test_data.py",
            line_number=78
        ),
        CodingTestResult(
            name="test_ui_components",
            status="skipped",
            duration=0.0,
            file_path="tests/test_ui.py",
            line_number=15
        )
    ]


async def run_framework_demo():
    """Demo function showing framework usage."""
    from .core_framework import CodingReviewerTestFramework
    
    print("🚀 CodingReviewer Testing Framework Demo")
    print("=" * 50)
    
    framework = CodingReviewerTestFramework()
    
    try:
        # Run all tests
        report = await framework.run_all_tests()
        
        print("\n📊 Demo completed successfully!")
        print(f"Total suites: {report['total_suites']}")
        
    except Exception as e:
        print(f"❌ Demo failed: {e}")


if __name__ == "__main__":
    asyncio.run(run_framework_demo())
