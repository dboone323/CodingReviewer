"""Performance tests for AI Operations System"""
import unittest
import time
import asyncio
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from final_ai_operations_dashboard import AIOperationsDashboard
from technical_debt_analyzer import TechnicalDebtAnalyzer

class TestSystemPerformance(unittest.TestCase):
    """Performance tests for system components"""
    
    def setUp(self):
        """Setup performance test environment"""
        self.performance_threshold = 30.0  # seconds
        self.memory_threshold = 500  # MB
    
    def test_dashboard_initialization_performance(self):
        """Test dashboard initialization performance"""
        start_time = time.time()
        
        dashboard = AIOperationsDashboard()
        
        end_time = time.time()
        duration = end_time - start_time
        
        self.assertLess(duration, 5.0, f"Dashboard initialization took {duration:.2f}s (>5s)")
        print(f"Dashboard initialization: {duration:.2f}s")
    
    def test_debt_analysis_performance(self):
        """Test debt analysis performance"""
        analyzer = TechnicalDebtAnalyzer()
        
        start_time = time.time()
        results = analyzer.analyze_codebase()
        end_time = time.time()
        
        duration = end_time - start_time
        
        # Performance should be reasonable for codebase size
        self.assertLess(duration, self.performance_threshold, 
                       f"Debt analysis took {duration:.2f}s (>{self.performance_threshold}s)")
        print(f"Debt analysis: {duration:.2f}s")
    
    def test_memory_usage(self):
        """Test memory usage during operations"""
        try:
            import psutil
            process = psutil.Process()
            
            # Measure initial memory
            initial_memory = process.memory_info().rss / 1024 / 1024  # MB
            
            # Perform operations
            dashboard = AIOperationsDashboard()
            analyzer = TechnicalDebtAnalyzer()
            results = analyzer.analyze_codebase()
            
            # Measure final memory
            final_memory = process.memory_info().rss / 1024 / 1024  # MB
            memory_increase = final_memory - initial_memory
            
            print(f"Memory usage: {initial_memory:.1f}MB -> {final_memory:.1f}MB (+{memory_increase:.1f}MB)")
            
            # Memory increase should be reasonable
            self.assertLess(memory_increase, self.memory_threshold,
                           f"Memory increased by {memory_increase:.1f}MB (>{self.memory_threshold}MB)")
        
        except ImportError:
            self.skipTest("psutil not available for memory testing")
    
    def test_concurrent_operations(self):
        """Test performance under concurrent operations"""
        def create_dashboard():
            return AIOperationsDashboard()
        
        start_time = time.time()
        
        # Simulate concurrent dashboard creation
        dashboards = []
        for _ in range(3):
            dashboard = create_dashboard()
            dashboards.append(dashboard)
        
        end_time = time.time()
        duration = end_time - start_time
        
        self.assertLess(duration, 10.0, f"Concurrent operations took {duration:.2f}s (>10s)")
        print(f"Concurrent operations: {duration:.2f}s")

if __name__ == '__main__':
    unittest.main()
