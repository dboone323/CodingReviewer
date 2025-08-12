"""
CodingReviewer Testing Framework

Modular testing framework for CodingReviewer project.
Provides comprehensive test execution, reporting, and visualization.

Usage:
    from testing_framework import CodingReviewerTestFramework
    
    framework = CodingReviewerTestFramework()
    report = await framework.run_all_tests()
"""

# Core framework exports
from .core_framework import CodingReviewerTestFramework

# Data models
from .models import CodingTestResult, CodingTestSuite

# Specialized components (available for advanced usage)
from .swift_integration import SwiftTestIntegration
from .python_integration import PythonTestIntegration
from .report_generator import TestReportGenerator
from .visualization import TestVisualization

# MCP Integration
from .mcp_integration import MCPIntegration, MCPArchitectureValidator

# Utilities
from .utilities import mock_swift_service, create_sample_test_data

# Version info
__version__ = "2.0.0"
__author__ = "CodingReviewer Team"

# Public API - what gets imported with "from testing_framework import *"
__all__ = [
    # Main framework
    "CodingReviewerTestFramework",
    
    # Data models
    "CodingTestResult",
    "CodingTestSuite",
    
    # Advanced components
    "SwiftTestIntegration",
    "PythonTestIntegration", 
    "TestReportGenerator",
    "TestVisualization",
    
    # MCP Integration
    "MCPIntegration",
    "MCPArchitectureValidator",
    
    # Utilities
    "mock_swift_service",
    "create_sample_test_data",
    
    # Version
    "__version__",
]
