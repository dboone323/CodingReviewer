"""Unit tests for Enhanced Error Logging"""
import unittest
from unittest.mock import patch, mock_open
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from enhanced_error_logging import EnhancedErrorLogger, ErrorCategory, log_info, log_error

class TestEnhancedErrorLogging(unittest.TestCase):
    """Test cases for Enhanced Error Logging"""
    
    def setUp(self):
        """Setup test fixtures"""
        self.logger = EnhancedErrorLogger()
    
    def test_error_logger_initialization(self):
        """Test error logger initialization"""
        self.assertIsNotNone(self.logger)
        self.assertEqual(len(self.logger.error_events), 0)
    
    def test_log_info_function(self):
        """Test log_info function"""
        with patch.object(self.logger, 'log_event') as mock_log:
            log_info("TestComponent", "Test message")
            mock_log.assert_called_once()
    
    def test_log_error_function(self):
        """Test log_error function"""
        with patch.object(self.logger, 'log_event') as mock_log:
            log_error("TestComponent", "Test error", category=ErrorCategory.SYSTEM_INTEGRATION)
            mock_log.assert_called_once()
    
    def test_error_categories(self):
        """Test error category enumeration"""
        self.assertTrue(hasattr(ErrorCategory, 'SYSTEM_INTEGRATION'))
        self.assertTrue(hasattr(ErrorCategory, 'AI_PROCESSING'))
    
    def test_error_report_generation(self):
        """Test error report generation"""
        # Add some test errors
        self.logger.log_event("TestComponent", "Test error", "ERROR", ErrorCategory.SYSTEM_INTEGRATION)
        report = self.logger.get_error_report()
        
        self.assertIsInstance(report, dict)
        self.assertIn('total_errors', report)
        self.assertGreaterEqual(report['total_errors'], 1)

if __name__ == '__main__':
    unittest.main()
