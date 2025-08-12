"""
CodingReviewer Testing Framework - Core Framework

Main testing framework class with configuration management.
Central orchestrator for test execution and coordination.
"""

from pathlib import Path
from typing import Dict, Any, Optional, List
from datetime import datetime

from .models import CodingTestSuite, CodingTestResult
from .swift_integration import SwiftTestIntegration
from .python_integration import PythonTestIntegration
from .report_generator import TestReportGenerator
from .mcp_integration import MCPIntegration, MCPArchitectureValidator
from .security_integration import MCPSecurityIntegration


class CodingReviewerTestFramework:
    """Main testing framework for CodingReviewer project."""
    
    def __init__(self, project_root: Optional[Path] = None):
        self.project_root = project_root or Path.cwd()
        self.config = self._load_config()
        
        # Initialize specialized components
        self.swift_integration = SwiftTestIntegration(self.project_root, self.config)
        self.python_integration = PythonTestIntegration(self.project_root, self.config)
        self.report_generator = TestReportGenerator(self.project_root, self.config)
        
        # Initialize MCP integration
        self.mcp_integration = MCPIntegration(self.project_root, self.config)
        self.architecture_validator = MCPArchitectureValidator(self.project_root)
        
        # Initialize security integration
        self.security_integration = MCPSecurityIntegration(self.project_root, self.mcp_integration)
        
        # Initialize advanced MCP integration (Phase 4)
        try:
            import sys
            sys.path.append(str(self.project_root))
            from advanced_mcp_integration import AdvancedMCPIntegration
            self.advanced_integration = AdvancedMCPIntegration(str(self.project_root))
        except ImportError:
            print("Advanced MCP Integration not available - skipping Phase 4 features")
            self.advanced_integration = None
        
        # Backward compatibility - expose test_results from report_generator
        self.test_results = self.report_generator.test_results
    
    def _load_config(self) -> Dict[str, Any]:
        """Load testing configuration."""
        config: Dict[str, Any] = {
            "swift_project_path": self.project_root / "CodingReviewer.xcodeproj",
            "swift_scheme": "CodingReviewer",
            "python_test_path": self.project_root / "python_tests",
            "reports_path": self.project_root / "test_reports",
            "jupyter_path": self.project_root / "jupyter_notebooks"
        }
        
        # Ensure directories exist
        for path_key in ["python_test_path", "reports_path", "jupyter_path"]:
            path = config[path_key]
            if isinstance(path, Path):
                path.mkdir(exist_ok=True)
        
        return config
    
    async def run_swift_tests(self) -> CodingTestSuite:
        """Execute Swift tests."""
        suite = await self.swift_integration.run_swift_tests()
        self.report_generator.add_test_suite(suite)
        return suite
    
    async def run_python_tests(self) -> CodingTestSuite:
        """Execute Python tests."""
        suite = await self.python_integration.run_python_tests()
        self.report_generator.add_test_suite(suite)
        return suite
    
    async def run_all_tests(self) -> Dict[str, Any]:
        """Execute all test suites and generate comprehensive report with MCP integration."""
        # Clear previous results
        self.report_generator.clear_results()
        
        # Run all test suites
        print("🧪 Running Swift tests...")
        await self.run_swift_tests()
        
        print("🐍 Running Python tests...")
        await self.run_python_tests()
        
        # Generate comprehensive report
        print("📊 Generating test report...")
        report = self.report_generator.generate_test_report()
        
        # Save report to file
        report_file = self.report_generator.save_report(report)
        print(f"✅ Report saved to: {report_file}")
        
        # MCP Integration: Handle test results
        await self._handle_test_results_with_mcp(report)
        
        # Print summary
        print("\n" + self.report_generator.generate_summary_text())
        
        return report
    
    async def _handle_test_results_with_mcp(self, report: Dict[str, Any]) -> None:
        """Handle test results using MCP integration."""
        try:
            # Check for test failures and create issues if needed
            summary = report.get("summary", {})
            failed_tests = []
            
            # Collect failed tests from all suites
            for suite_name, suite_data in report.get("test_suites", {}).items():
                if isinstance(suite_data, dict) and "results" in suite_data:
                    for result in suite_data["results"]:
                        if isinstance(result, dict) and result.get("status") == "failed":
                            # Convert dict to CodingTestResult for MCP
                            from .models import CodingTestResult
                            failed_test = CodingTestResult(
                                name=result.get("name", "Unknown Test"),
                                status="failed",
                                duration=result.get("duration", 0.0),
                                error_message=result.get("error_message"),
                                file_path=result.get("file_path"),
                                output=result.get("output")
                            )
                            failed_tests.append(failed_test)
            
            # Create GitHub issue for failures
            if failed_tests:
                issue_number = await self.mcp_integration.create_test_failure_issue(failed_tests)
                if issue_number:
                    print(f"🔗 [MCP] Created GitHub issue: {issue_number}")
            
            # Trigger workflow completion
            workflow_triggered = await self.mcp_integration.trigger_workflow_on_test_completion(report)
            if workflow_triggered:
                print("🔄 [MCP] Triggered post-test workflow")
                
            # Setup monitoring if not already configured
            await self.mcp_integration.setup_automated_monitoring()
            
        except Exception as e:
            print(f"⚠️ [MCP] Error in MCP integration: {e}")
    
    async def validate_architecture(self) -> Dict[str, Any]:
        """Validate project architecture using MCP tools."""
        print("🏗️ [MCP] Validating project architecture...")
        
        # Validate the testing framework module structure
        framework_path = self.project_root / "python_src" / "testing_framework"
        validation_results = await self.architecture_validator.validate_modular_structure(framework_path)
        
        # Enforce architecture rules
        actions = await self.architecture_validator.enforce_architecture_rules()
        validation_results["enforcement_actions"] = actions
        
        return validation_results
    
    async def get_mcp_status(self) -> Dict[str, Any]:
        """Get comprehensive MCP integration status."""
        status = self.mcp_integration.get_mcp_status()
        integration_health = await self.mcp_integration.validate_mcp_integration()
        
        return {
            "mcp_status": status,
            "integration_health": integration_health,
            "architecture_compliance": await self.validate_architecture(),
            "security_status": self.security_integration.get_security_status()
        }
    
    async def run_security_scan(self) -> Dict[str, Any]:
        """Run comprehensive security scan using MCP security integration."""
        print("🔒 [Security] Starting comprehensive security scan...")
        
        # Run security scan
        scan_results = await self.security_integration.run_comprehensive_security_scan()
        
        # Enable GitHub security features
        github_features = await self.security_integration.enable_github_security_features()
        
        # Setup monitoring
        monitoring_enabled = await self.security_integration.setup_automated_security_monitoring()
        
        return {
            "scan_results": scan_results,
            "github_security_features": github_features,
            "monitoring_enabled": monitoring_enabled,
            "timestamp": datetime.now().isoformat()
        }
    
    async def run_advanced_analysis(self) -> Optional[Dict[str, Any]]:
        """Run advanced MCP integration analysis (Phase 4)."""
        if self.advanced_integration:
            print("🚀 [Advanced] Starting comprehensive AI-driven analysis...")
            return await self.advanced_integration.run_comprehensive_analysis()
        else:
            print("⚠️ Advanced MCP Integration not available - skipping Phase 4 features")
            return None
    
    def get_config(self) -> Dict[str, Any]:
        """Get current configuration."""
        return self.config.copy()
    
    def update_config(self, updates: Dict[str, Any]) -> None:
        """Update configuration."""
        self.config.update(updates)
        
        # Update component configurations
        self.swift_integration.config = self.config
        self.python_integration.config = self.config
        self.report_generator.config = self.config
    
    # Backward compatibility methods
    def _parse_swift_test_output(self, stdout: str, stderr: str) -> List[Any]:
        """Backward compatibility: delegate to SwiftTestIntegration."""
        return self.swift_integration._parse_swift_test_output(stdout, stderr)  # type: ignore  # protected access for compatibility
    
    def generate_test_report(self) -> Dict[str, Any]:
        """Backward compatibility: delegate to TestReportGenerator."""
        return self.report_generator.generate_test_report()
    
    def save_report(self, report: Dict[str, Any], filename: Optional[str] = None):
        """Backward compatibility: delegate to TestReportGenerator."""
        return self.report_generator.save_report(report, filename)
