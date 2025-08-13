#!/usr/bin/env python3
"""
Comprehensive System Verification

This script verifies that all major components of the CodingReviewer system
are working correctly after the complete strategic roadmap implementation.
"""

import sys
import os
import subprocess
import json
from pathlib import Path
import time

def print_header(title):
    """Print a formatted header"""
    print(f"\n{'='*60}")
    print(f"🔍 {title}")
    print(f"{'='*60}")

def print_success(message):
    """Print success message"""
    print(f"✅ {message}")

def print_error(message):
    """Print error message"""
    print(f"❌ {message}")

def print_info(message):
    """Print info message"""
    print(f"ℹ️  {message}")

def run_command(command, description):
    """Run a command and return the result"""
    print(f"\n🧪 Testing: {description}")
    try:
        result = subprocess.run(
            command,
            shell=True,
            capture_output=True,
            text=True,
            timeout=30
        )
        if result.returncode == 0:
            print_success(f"{description}: PASS")
            return True, result.stdout
        else:
            print_error(f"{description}: FAIL")
            if result.stderr:
                print(f"Error: {result.stderr[:200]}")
            return False, result.stderr
    except subprocess.TimeoutExpired:
        print_error(f"{description}: TIMEOUT")
        return False, "Command timed out"
    except Exception as e:
        print_error(f"{description}: ERROR - {e}")
        return False, str(e)

def check_file_exists(file_path, description):
    """Check if a file exists"""
    if Path(file_path).exists():
        print_success(f"{description}: EXISTS")
        return True
    else:
        print_error(f"{description}: MISSING")
        return False

def main():
    """Main verification function"""
    print_header("COMPREHENSIVE SYSTEM VERIFICATION")
    print("Verifying all components of the CodingReviewer enterprise platform...")
    
    verification_results = {
        'timestamp': time.strftime('%Y-%m-%d %H:%M:%S'),
        'tests': {},
        'summary': {}
    }
    
    # Test 1: Python Environment
    print_header("1. Python Environment Verification")
    success, output = run_command("python --version", "Python Version")
    verification_results['tests']['python_version'] = success
    
    success, output = run_command("python -c 'import ast, json, pathlib; print(\"Core modules available\")'", "Core Python Modules")
    verification_results['tests']['python_modules'] = success
    
    # Test 2: Core Python Components
    print_header("2. Core Python Components")
    
    # Technical Debt Analyzer
    success, output = run_command("timeout 10 python technical_debt_analyzer.py", "Technical Debt Analyzer")
    verification_results['tests']['technical_debt_analyzer'] = success
    
    # Documentation Generator
    success, output = run_command("timeout 15 python documentation_generator.py", "Documentation Generator")
    verification_results['tests']['documentation_generator'] = success
    
    # System Validation
    success, output = run_command("timeout 10 python final_system_validation.py", "System Validation")
    verification_results['tests']['system_validation'] = success
    
    # Advanced Refactoring Optimizer
    success, output = run_command("timeout 10 python advanced_refactoring_optimizer.py", "Advanced Refactoring Optimizer")
    verification_results['tests']['refactoring_optimizer'] = success
    
    # Automated Fix Applicator
    success, output = run_command("timeout 10 python automated_fix_applicator.py", "Automated Fix Applicator")
    verification_results['tests']['fix_applicator'] = success
    
    # Test 3: Testing Infrastructure
    print_header("3. Testing Infrastructure")
    
    # Python Tests
    success, output = run_command("python -m pytest python_tests/ -v --tb=short", "Python Test Suite")
    verification_results['tests']['pytest_suite'] = success
    
    # Test 4: Documentation Verification
    print_header("4. Documentation Verification")
    
    docs_exist = check_file_exists("docs/", "Documentation Directory")
    verification_results['tests']['docs_directory'] = docs_exist
    
    api_docs = check_file_exists("docs/api/", "API Documentation")
    verification_results['tests']['api_docs'] = api_docs
    
    user_guides = check_file_exists("docs/user_guides/", "User Guides")
    verification_results['tests']['user_guides'] = user_guides
    
    # Test 5: Analysis Results
    print_header("5. Analysis Results Verification")
    
    analysis_dir = check_file_exists("analysis_results/", "Analysis Results Directory")
    verification_results['tests']['analysis_results'] = analysis_dir
    
    refactoring_report = check_file_exists("analysis_results/refactoring_analysis.json", "Refactoring Analysis Report")
    verification_results['tests']['refactoring_report'] = refactoring_report
    
    completion_report = check_file_exists("STRATEGIC_ROADMAP_COMPLETION_REPORT.md", "Completion Report")
    verification_results['tests']['completion_report'] = completion_report
    
    # Test 6: Swift/Xcode Project
    print_header("6. Swift/Xcode Project Verification")
    
    xcode_project = check_file_exists("CodingReviewer.xcodeproj", "Xcode Project")
    verification_results['tests']['xcode_project'] = xcode_project
    
    # Try building without code signing
    success, output = run_command("timeout 60 xcodebuild -project CodingReviewer.xcodeproj -scheme CodingReviewer -destination 'platform=macOS' build CODE_SIGNING_ALLOWED=NO", "Xcode Build (No Code Signing)")
    verification_results['tests']['xcode_build'] = success
    
    # Test 7: Configuration Files
    print_header("7. Configuration Files Verification")
    
    pytest_ini = check_file_exists("pytest.ini", "Pytest Configuration")
    verification_results['tests']['pytest_config'] = pytest_ini
    
    pyproject_toml = check_file_exists("pyproject.toml", "Python Project Configuration")
    verification_results['tests']['pyproject_config'] = pyproject_toml
    
    gitignore = check_file_exists(".gitignore", "Git Ignore File")
    verification_results['tests']['gitignore'] = gitignore
    
    # Test 8: CI/CD Workflows
    print_header("8. CI/CD Workflows Verification")
    
    github_workflows = check_file_exists(".github/", "GitHub Workflows Directory")
    verification_results['tests']['github_workflows'] = github_workflows
    
    gitlab_ci = check_file_exists(".gitlab-ci.yml", "GitLab CI Configuration")
    verification_results['tests']['gitlab_ci'] = gitlab_ci
    
    # Calculate summary
    total_tests = len(verification_results['tests'])
    passed_tests = sum(1 for result in verification_results['tests'].values() if result)
    success_rate = (passed_tests / total_tests) * 100 if total_tests > 0 else 0
    
    verification_results['summary'] = {
        'total_tests': total_tests,
        'passed_tests': passed_tests,
        'failed_tests': total_tests - passed_tests,
        'success_rate': success_rate,
        'overall_status': 'PASS' if success_rate >= 80 else 'FAIL'
    }
    
    # Print final summary
    print_header("VERIFICATION SUMMARY")
    print(f"📊 Total Tests: {total_tests}")
    print(f"✅ Passed: {passed_tests}")
    print(f"❌ Failed: {total_tests - passed_tests}")
    print(f"📈 Success Rate: {success_rate:.1f}%")
    
    if success_rate >= 90:
        print_success("EXCELLENT: System is fully operational! 🎉")
        status = "EXCELLENT"
    elif success_rate >= 80:
        print_success("GOOD: System is mostly operational with minor issues")
        status = "GOOD"
    elif success_rate >= 60:
        print_info("FAIR: System has some issues that need attention")
        status = "FAIR"
    else:
        print_error("POOR: System has significant issues requiring immediate attention")
        status = "POOR"
    
    # Save verification report
    with open('comprehensive_verification_report.json', 'w') as f:
        json.dump(verification_results, f, indent=2)
    
    print(f"\n📋 Detailed verification report saved to: comprehensive_verification_report.json")
    
    # Print component status
    print_header("COMPONENT STATUS SUMMARY")
    
    component_groups = {
        'Core Python Systems': ['python_version', 'python_modules', 'technical_debt_analyzer', 'documentation_generator', 'system_validation'],
        'Advanced Features': ['refactoring_optimizer', 'fix_applicator'],
        'Testing & Quality': ['pytest_suite', 'pytest_config'],
        'Documentation': ['docs_directory', 'api_docs', 'user_guides', 'completion_report'],
        'Analysis & Reports': ['analysis_results', 'refactoring_report'],
        'Swift/Xcode': ['xcode_project', 'xcode_build'],
        'DevOps & CI/CD': ['github_workflows', 'gitlab_ci', 'pyproject_config', 'gitignore']
    }
    
    for group_name, tests in component_groups.items():
        group_passed = sum(1 for test in tests if verification_results['tests'].get(test, False))
        group_total = len(tests)
        group_rate = (group_passed / group_total) * 100 if group_total > 0 else 0
        
        status_icon = "✅" if group_rate >= 80 else "⚠️" if group_rate >= 50 else "❌"
        print(f"{status_icon} {group_name}: {group_passed}/{group_total} ({group_rate:.0f}%)")
    
    print_header("NEXT STEPS")
    if success_rate >= 90:
        print("🚀 System is ready for production deployment!")
        print("🎯 All major components are operational")
        print("💼 Enterprise-grade quality achieved")
    elif success_rate >= 80:
        print("🔧 Address minor issues for optimal performance")
        print("📋 Review failed tests and apply fixes")
        print("🎯 System is suitable for development use")
    else:
        print("⚠️  Significant issues detected - review and fix failed components")
        print("🔍 Check logs and error messages for specific problems")
        print("🛠️  Apply necessary fixes before deployment")
    
    print("\n🏁 Comprehensive verification complete!")
    return verification_results['summary']['overall_status'] == 'PASS'

if __name__ == "__main__":
    try:
        success = main()
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\n\n⚠️  Verification interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n\n❌ Verification failed with error: {e}")
        sys.exit(1)
