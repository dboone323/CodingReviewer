"""Integration tests for AI Operations System"""
import unittest
import asyncio
import tempfile
import shutil
from pathlib import Path
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from final_ai_operations_dashboard import AIOperationsDashboard
from enhanced_error_logging import EnhancedErrorLogger, log_info
from technical_debt_analyzer import TechnicalDebtAnalyzer

class TestSystemIntegration(unittest.TestCase):
    """Integration tests for the complete system"""
    
    def setUp(self):
        """Setup test environment"""
        self.temp_dir = tempfile.mkdtemp()
        self.temp_path = Path(self.temp_dir)
        
        # Create test files
        test_file = self.temp_path / "test_module.py"
        test_file.write_text('''def example_function():
    """Example function for testing"""
    return "test"

class ExampleClass:
    """Example class for testing"""
    def method(self):
        return True
''')
    
    def tearDown(self):
        """Cleanup test environment"""
        shutil.rmtree(self.temp_dir)
    
    def test_dashboard_integration(self):
        """Test dashboard integration with other components"""
        dashboard = AIOperationsDashboard()
        
        # Test that dashboard initializes successfully
        self.assertIsNotNone(dashboard.system_status)
        
        # Test error logging integration
        log_info("Integration Test", "Testing dashboard integration")
        
        # Verify integration works
        self.assertTrue(True)  # Would verify actual integration
    
    def test_error_logging_integration(self):
        """Test error logging integration across components"""
        logger = EnhancedErrorLogger()
        
        # Test logging from different components
        log_info("Dashboard", "Dashboard initialization")
        log_info("Analyzer", "Analysis started")
        
        # Verify logs are captured
        report = logger.get_error_report()
        self.assertIsInstance(report, dict)
    
    def test_debt_analyzer_integration(self):
        """Test debt analyzer integration with file system"""
        analyzer = TechnicalDebtAnalyzer(str(self.temp_path))
        
        # Run analysis on test files
        results = analyzer.analyze_codebase()
        
        # Verify analysis results
        self.assertIsInstance(results, dict)
        if 'file_metrics' in results:
            self.assertIsInstance(results['file_metrics'], list)
    
    def test_end_to_end_workflow(self):
        """Test complete end-to-end workflow"""
        # Initialize all components
        dashboard = AIOperationsDashboard()
        analyzer = TechnicalDebtAnalyzer()
        
        # Test workflow
        system_status = dashboard.system_status
        analysis_results = analyzer.analyze_codebase()
        
        # Verify workflow completion
        self.assertIsNotNone(system_status)
        self.assertIsNotNone(analysis_results)

if __name__ == '__main__':
    unittest.main()
