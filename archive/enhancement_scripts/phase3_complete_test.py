#!/usr/bin/env python3
"""
Complete Phase 3 Component Testing
"""

import sys
import time
import json
from datetime import datetime

def test_automation_engine():
    print("🔧 Testing Automation Engine...")
    try:
        from working_automation_engine import get_engine
        engine = get_engine()
        status = engine.get_status()
        print(f"✅ Automation Engine: Found {status['total_scripts']} scripts")
        return True
    except Exception as e:
        print(f"❌ Automation Engine failed: {e}")
        return False

def test_jwt_auth():
    print("🔐 Testing JWT Authentication...")
    try:
        from working_jwt_auth import get_auth_manager
        auth = get_auth_manager()
        
        # Test login
        token = auth.login("admin", "admin")
        if not token:
            print("❌ JWT Auth: Login failed")
            return False
        
        # Test verification
        payload = auth.verify_token(token)
        if not payload or payload.get("username") != "admin":
            print("❌ JWT Auth: Token verification failed")
            return False
        
        print("✅ JWT Authentication: Login and verification successful")
        return True
    except Exception as e:
        print(f"❌ JWT Authentication failed: {e}")
        return False

def test_performance_optimizer():
    print("⚡ Testing Performance Optimizer...")
    try:
        from working_performance_optimizer import get_optimizer
        optimizer = get_optimizer()
        
        # Collect metrics
        metrics = optimizer.collect_metrics()
        if not hasattr(metrics, 'cpu_percent'):
            print("❌ Performance Optimizer: Metrics collection failed")
            return False
        
        # Test cache
        optimizer.optimize_cache("test", "value", 60)
        cached = optimizer.get_cached("test")
        if cached != "value":
            print("❌ Performance Optimizer: Cache test failed")
            return False
        
        print(f"✅ Performance Optimizer: CPU {metrics.cpu_percent}%, Memory {metrics.memory_percent}%")
        return True
    except Exception as e:
        print(f"❌ Performance Optimizer failed: {e}")
        return False

def test_integration_components():
    print("🌉 Testing Integration Components...")
    try:
        # Test if integration bridge exists
        import os
        bridge_path = "phase3_integration_bridge.py"
        testing_path = "phase3_comprehensive_testing.py"
        
        bridge_exists = os.path.exists(bridge_path)
        testing_exists = os.path.exists(testing_path)
        
        if bridge_exists and testing_exists:
            print("✅ Integration Components: Bridge and testing framework present")
            return True
        else:
            print(f"❌ Integration Components: Missing files (Bridge: {bridge_exists}, Testing: {testing_exists})")
            return False
    except Exception as e:
        print(f"❌ Integration Components failed: {e}")
        return False

def run_comprehensive_test():
    print("=" * 60)
    print("🚀 PHASE 3 COMPREHENSIVE TESTING")
    print("=" * 60)
    
    test_results = []
    test_results.append(test_automation_engine())
    test_results.append(test_jwt_auth())
    test_results.append(test_performance_optimizer())
    test_results.append(test_integration_components())
    
    passed = sum(test_results)
    total = len(test_results)
    
    print("\n" + "=" * 60)
    print(f"📊 TEST RESULTS: {passed}/{total} PASSED")
    print("=" * 60)
    
    if passed == total:
        print("🎉 ALL TESTS PASSED! Phase 3 is ready for Phase 4!")
        print("\n🔄 Phase 3 Component Status:")
        print("   ✅ Automation Engine: Operational")
        print("   ✅ JWT Authentication: Operational") 
        print("   ✅ Performance Optimizer: Operational")
        print("   ✅ Integration Bridge: Present")
        print("   ✅ Testing Framework: Present")
        
        # Generate readiness report
        report = {
            "phase": 3,
            "status": "READY_FOR_PHASE_4",
            "timestamp": datetime.now().isoformat(),
            "components": {
                "automation_engine": "operational",
                "jwt_auth": "operational",
                "performance_optimizer": "operational",
                "integration_bridge": "present",
                "testing_framework": "present"
            },
            "tests_passed": passed,
            "tests_total": total,
            "next_phase": "Phase 4 - Production Deployment"
        }
        
        with open("phase3_readiness_report.json", "w") as f:
            json.dump(report, f, indent=2)
        
        print(f"\n📄 Readiness report saved to: phase3_readiness_report.json")
        return True
    else:
        print("❌ Some tests failed. Please fix issues before proceeding to Phase 4.")
        return False

if __name__ == "__main__":
    success = run_comprehensive_test()
    sys.exit(0 if success else 1)
