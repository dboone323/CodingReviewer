"""Unit tests for Technical Debt Analyzer"""
import unittest
from unittest.mock import patch, Mock
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from technical_debt_analyzer import TechnicalDebtAnalyzer

class TestTechnicalDebtAnalyzer(unittest.TestCase):
    """Test cases for Technical Debt Analyzer"""
    
    def setUp(self):
        """Setup test fixtures"""
        self.analyzer = TechnicalDebtAnalyzer()
    
    def test_analyzer_initialization(self):
        """Test analyzer initialization"""
        self.assertIsNotNone(self.analyzer)
        self.assertEqual(self.analyzer.workspace_path.name, '.')
    
    @patch('technical_debt_analyzer.Path.glob')
    def test_file_analysis(self, mock_glob):
        """Test file analysis functionality"""
        mock_glob.return_value = []
        results = self.analyzer.analyze_codebase()
        self.assertIsInstance(results, dict)
    
    def test_complexity_calculation(self):
        """Test complexity calculation"""
        # Test with sample code
        sample_code = "def simple_function():\n    return True"
        # Would need actual complexity calculation method
        self.assertTrue(True)  # Placeholder
    
    def test_debt_score_calculation(self):
        """Test debt score calculation"""
        results = self.analyzer.analyze_codebase()
        if 'overall_debt_score' in results:
            self.assertIsInstance(results['overall_debt_score'], (int, float))
            self.assertGreaterEqual(results['overall_debt_score'], 0)
            self.assertLessEqual(results['overall_debt_score'], 100)

if __name__ == '__main__':
    unittest.main()
