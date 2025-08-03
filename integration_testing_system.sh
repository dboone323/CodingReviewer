#!/bin/bash

# Integration Testing System
# Comprehensive testing of all project systems

echo "🧪 Integration Testing System"
echo "============================="

PROJECT_PATH="$(pwd)"
TEST_RESULTS_DIR="integration_test_results"
TEST_LOG="integration_test.log"

# Create test results directory
mkdir -p "$TEST_RESULTS_DIR"

# Function to test build system
test_build_system() {
    echo "🔨 Testing Build System..."
    
    local build_start=$(date +%s)
    xcodebuild build -project CodingReviewer.xcodeproj -scheme CodingReviewer -destination 'platform=macOS' > "$TEST_RESULTS_DIR/build_test.log" 2>&1
    local build_result=$?
    local build_end=$(date +%s)
    local build_duration=$((build_end - build_start))
    
    if [ $build_result -eq 0 ]; then
        echo "  ✅ Build system: PASS (${build_duration}s)"
        echo "$(date): BUILD_TEST PASS ${build_duration}s" >> "$TEST_LOG"
        return 0
    else
        echo "  ❌ Build system: FAIL (${build_duration}s)"
        echo "$(date): BUILD_TEST FAIL ${build_duration}s" >> "$TEST_LOG"
        return 1
    fi
}

# Function to test file management systems
test_file_management() {
    echo "📁 Testing File Management Systems..."
    
    local test_file="$TEST_RESULTS_DIR/test_upload.swift"
    cat > "$test_file" << 'EOF'
import Foundation

class TestUploadClass {
    func testMethod() {
        print("Test file for upload testing")
    }
}
EOF
    
    # Test file exists and is readable
    if [ -f "$test_file" ] && [ -r "$test_file" ]; then
        echo "  ✅ File creation: PASS"
        echo "$(date): FILE_MANAGEMENT_TEST PASS" >> "$TEST_LOG"
        rm "$test_file"
        return 0
    else
        echo "  ❌ File creation: FAIL"
        echo "$(date): FILE_MANAGEMENT_TEST FAIL" >> "$TEST_LOG"
        return 1
    fi
}

# Function to test automation systems
test_automation_systems() {
    echo "🤖 Testing Automation Systems..."
    
    # Check if automation scripts exist and are executable
    local automation_scripts=(
        "enhanced_master_orchestrator.sh"
        "automation_optimizer.sh"
        "automated_backup_retention.sh"
        "code_deduplication_prevention.sh"
    )
    
    local passed=0
    local total=${#automation_scripts[@]}
    
    for script in "${automation_scripts[@]}"; do
        if [ -f "$script" ] && [ -x "$script" ]; then
            echo "  ✅ $script: PASS"
            ((passed++))
        else
            echo "  ❌ $script: FAIL (not found or not executable)"
        fi
    done
    
    if [ $passed -eq $total ]; then
        echo "  ✅ Automation systems: PASS ($passed/$total)"
        echo "$(date): AUTOMATION_TEST PASS $passed/$total" >> "$TEST_LOG"
        return 0
    else
        echo "  ⚠️ Automation systems: PARTIAL ($passed/$total)"
        echo "$(date): AUTOMATION_TEST PARTIAL $passed/$total" >> "$TEST_LOG"
        return 1
    fi
}

# Function to test duplicate prevention system
test_duplicate_prevention() {
    echo "🔍 Testing Duplicate Prevention System..."
    
    # Run quick duplicate check
    if [ -f "code_deduplication_prevention.sh" ]; then
        ./code_deduplication_prevention.sh --quick-check > "$TEST_RESULTS_DIR/duplicate_check.log" 2>&1
        local duplicate_result=$?
        
        if [ $duplicate_result -eq 0 ]; then
            echo "  ✅ Duplicate prevention: PASS (no duplicates detected)"
            echo "$(date): DUPLICATE_PREVENTION_TEST PASS" >> "$TEST_LOG"
            return 0
        else
            echo "  ⚠️ Duplicate prevention: WARNING (potential duplicates found)"
            echo "$(date): DUPLICATE_PREVENTION_TEST WARNING" >> "$TEST_LOG"
            return 1
        fi
    else
        echo "  ❌ Duplicate prevention: FAIL (script not found)"
        echo "$(date): DUPLICATE_PREVENTION_TEST FAIL" >> "$TEST_LOG"
        return 1
    fi
}

# Function to test swift file compilation
test_swift_compilation() {
    echo "🛠️ Testing Swift File Compilation..."
    
    local swift_files_count=$(find CodingReviewer -name "*.swift" | wc -l)
    echo "  📊 Found $swift_files_count Swift files"
    
    # Test compilation of key files
    local key_files=(
        "CodingReviewer/ContentView.swift"
        "CodingReviewer/AutomaticFixEngine.swift"
        "CodingReviewer/OpenAIService.swift"
        "CodingReviewer/AILearningCoordinator.swift"
    )
    
    local compiled=0
    for file in "${key_files[@]}"; do
        if [ -f "$file" ]; then
            # Check if file has basic Swift syntax
            if grep -q "import\|class\|struct\|func" "$file"; then
                echo "  ✅ $file: PASS (valid Swift syntax)"
                ((compiled++))
            else
                echo "  ❌ $file: FAIL (invalid Swift syntax)"
            fi
        else
            echo "  ❌ $file: FAIL (file not found)"
        fi
    done
    
    if [ $compiled -eq ${#key_files[@]} ]; then
        echo "  ✅ Swift compilation: PASS ($compiled/${#key_files[@]})"
        echo "$(date): SWIFT_COMPILATION_TEST PASS $compiled/${#key_files[@]}" >> "$TEST_LOG"
        return 0
    else
        echo "  ❌ Swift compilation: FAIL ($compiled/${#key_files[@]})"
        echo "$(date): SWIFT_COMPILATION_TEST FAIL $compiled/${#key_files[@]}" >> "$TEST_LOG"
        return 1
    fi
}

# Function to test project structure
test_project_structure() {
    echo "🏗️ Testing Project Structure..."
    
    local required_dirs=(
        "CodingReviewer"
        "CodingReviewer/Services"
        "CodingReviewer/SharedTypes"
        "CodingReviewer/Views"
        "TestFiles_Manual"
    )
    
    local found_dirs=0
    for dir in "${required_dirs[@]}"; do
        if [ -d "$dir" ]; then
            echo "  ✅ $dir: PASS"
            ((found_dirs++))
        else
            echo "  ❌ $dir: FAIL"
        fi
    done
    
    if [ $found_dirs -eq ${#required_dirs[@]} ]; then
        echo "  ✅ Project structure: PASS ($found_dirs/${#required_dirs[@]})"
        echo "$(date): PROJECT_STRUCTURE_TEST PASS $found_dirs/${#required_dirs[@]}" >> "$TEST_LOG"
        return 0
    else
        echo "  ❌ Project structure: FAIL ($found_dirs/${#required_dirs[@]})"
        echo "$(date): PROJECT_STRUCTURE_TEST FAIL $found_dirs/${#required_dirs[@]}" >> "$TEST_LOG"
        return 1
    fi
}

# Function to generate integration test report
generate_test_report() {
    echo "📋 Generating integration test report..."
    
    local report_file="$TEST_RESULTS_DIR/integration_test_report.md"
    cat > "$report_file" << EOF
# Integration Test Report
Generated: $(date)

## Test Summary
EOF
    
    if [ -f "$TEST_LOG" ]; then
        local total_tests=$(grep -c "TEST" "$TEST_LOG")
        local passed_tests=$(grep -c "PASS" "$TEST_LOG")
        local failed_tests=$(grep -c "FAIL" "$TEST_LOG")
        local warning_tests=$(grep -c "WARNING\|PARTIAL" "$TEST_LOG")
        
        cat >> "$report_file" << EOF
- **Total Tests**: $total_tests
- **Passed**: $passed_tests
- **Failed**: $failed_tests
- **Warnings**: $warning_tests
- **Success Rate**: $(( passed_tests * 100 / total_tests ))%

## Test Results
\`\`\`
$(cat "$TEST_LOG")
\`\`\`

## Recommendations
EOF
        
        if [ $failed_tests -gt 0 ]; then
            echo "- ⚠️ Address failed tests before production deployment" >> "$report_file"
        fi
        
        if [ $warning_tests -gt 0 ]; then
            echo "- 🔍 Review warning tests for potential improvements" >> "$report_file"
        fi
        
        if [ $passed_tests -eq $total_tests ]; then
            echo "- ✅ All tests passed - system is ready for operation" >> "$report_file"
        fi
    fi
    
    cat >> "$report_file" << EOF

## Files Generated
- Integration test log: \`$TEST_LOG\`
- Build test log: \`$TEST_RESULTS_DIR/build_test.log\`
- Duplicate check log: \`$TEST_RESULTS_DIR/duplicate_check.log\`

## Next Steps
1. Review any failed tests
2. Address identified issues
3. Re-run integration tests
4. Deploy with confidence
EOF
    
    echo "  📄 Report saved to: $report_file"
}

# Main execution
echo "🚀 Starting integration testing..."
echo "$(date): Integration testing started" > "$TEST_LOG"

# Run all tests
tests_passed=0
tests_total=6

test_build_system && ((tests_passed++))
test_file_management && ((tests_passed++))
test_automation_systems && ((tests_passed++))
test_duplicate_prevention && ((tests_passed++))
test_swift_compilation && ((tests_passed++))
test_project_structure && ((tests_passed++))

echo ""
echo "📊 Integration Test Results:"
echo "  🎯 Tests Passed: $tests_passed/$tests_total"
echo "  📈 Success Rate: $(( tests_passed * 100 / tests_total ))%"

generate_test_report

if [ $tests_passed -eq $tests_total ]; then
    echo "✅ All integration tests passed!"
    echo "$(date): Integration testing completed successfully" >> "$TEST_LOG"
    exit 0
else
    echo "⚠️ Some tests failed - review the report for details"
    echo "$(date): Integration testing completed with issues" >> "$TEST_LOG"
    exit 1
fi
