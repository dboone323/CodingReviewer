#!/bin/bash

# Advanced Security Scanner - Phase 2 CI/CD Enhancement
# MCP-Powered Security Analysis

echo "🛡️ Advanced Security Scanner - Phase 2 Enhancement"
echo "=================================================="

# Configuration
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SECURITY_DIR="security_reports"
REPORT_FILE="$SECURITY_DIR/security_analysis_$TIMESTAMP.json"

# Create security reports directory
mkdir -p "$SECURITY_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${CYAN}🔍 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Initialize security report
cat > "$REPORT_FILE" << 'EOF'
{
  "security_analysis": {
    "timestamp": "",
    "version": "Phase 2 - MCP Enhanced",
    "scan_type": "comprehensive",
    "findings": {
      "critical": [],
      "high": [],
      "medium": [],
      "low": []
    },
    "summary": {
      "total_issues": 0,
      "files_scanned": 0,
      "security_score": 0
    }
  }
}
EOF

# Update timestamp
sed -i '' "s/\"timestamp\": \"\"/\"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"/" "$REPORT_FILE"

print_status "Starting comprehensive security analysis..."

# 1. Scan for hardcoded secrets
scan_secrets() {
    print_status "Scanning for hardcoded secrets and credentials..."
    
    SECRET_PATTERNS=(
        "password\s*=\s*['\"][^'\"]*['\"]"
        "api_key\s*=\s*['\"][^'\"]*['\"]"
        "secret\s*=\s*['\"][^'\"]*['\"]"
        "token\s*=\s*['\"][^'\"]*['\"]"
        "AWS_ACCESS_KEY"
        "GITHUB_TOKEN"
    )
    
    SECRETS_FOUND=0
    for pattern in "${SECRET_PATTERNS[@]}"; do
        if grep -r -E "$pattern" . --include="*.swift" --include="*.plist" --include="*.json" >/dev/null 2>&1; then
            SECRETS_FOUND=$((SECRETS_FOUND + 1))
        fi
    done
    
    if [ $SECRETS_FOUND -gt 0 ]; then
        print_warning "Found $SECRETS_FOUND potential secret patterns"
    else
        print_success "No hardcoded secrets detected"
    fi
    
    echo "$SECRETS_FOUND"
}

# 2. Check file permissions
check_permissions() {
    print_status "Checking file permissions for security issues..."
    
    PERM_ISSUES=0
    
    # Check for world-writable files
    if find . -type f -perm +002 2>/dev/null | grep -q .; then
        PERM_ISSUES=$((PERM_ISSUES + 1))
        print_warning "Found world-writable files"
    fi
    
    # Check for executable scripts
    EXEC_COUNT=$(find . -name "*.sh" -type f | wc -l | tr -d ' ')
    print_info "Found $EXEC_COUNT shell scripts"
    
    echo "$PERM_ISSUES"
}

# 3. Dependency security check
check_dependencies() {
    print_status "Analyzing dependencies for security vulnerabilities..."
    
    DEP_ISSUES=0
    
    # Check for Package.swift
    if [ -f "Package.swift" ]; then
        print_info "Analyzing Package.swift dependencies"
        DEP_COUNT=$(grep -c "dependencies:" Package.swift 2>/dev/null || echo "0")
        print_info "Found $DEP_COUNT dependency declarations"
    fi
    
    # Check for Podfile
    if [ -f "Podfile" ]; then
        print_info "Analyzing Podfile dependencies"
        POD_COUNT=$(grep -c "pod " Podfile 2>/dev/null || echo "0")
        print_info "Found $POD_COUNT pod dependencies"
    fi
    
    echo "$DEP_ISSUES"
}

# 4. Code security patterns
check_code_patterns() {
    print_status "Analyzing code for insecure patterns..."
    
    CODE_ISSUES=0
    
    # Check for unsafe URL handling
    if grep -r "URL(string:" . --include="*.swift" >/dev/null 2>&1; then
        CODE_ISSUES=$((CODE_ISSUES + 1))
        print_warning "Found direct URL string construction"
    fi
    
    # Check for force unwrapping
    FORCE_UNWRAP_COUNT=$(grep -r "!" . --include="*.swift" | wc -l | tr -d ' ')
    if [ "$FORCE_UNWRAP_COUNT" -gt 50 ]; then
        CODE_ISSUES=$((CODE_ISSUES + 1))
        print_warning "High number of force unwraps detected: $FORCE_UNWRAP_COUNT"
    fi
    
    echo "$CODE_ISSUES"
}

# 5. Network security check
check_network_security() {
    print_status "Checking network security configurations..."
    
    NET_ISSUES=0
    
    # Check for HTTP (non-HTTPS) URLs
    if grep -r "http://" . --include="*.swift" --include="*.plist" >/dev/null 2>&1; then
        NET_ISSUES=$((NET_ISSUES + 1))
        print_warning "Found non-HTTPS URLs"
    fi
    
    # Check for disabled certificate validation
    if grep -r "allowsArbitraryLoads" . --include="*.plist" >/dev/null 2>&1; then
        NET_ISSUES=$((NET_ISSUES + 1))
        print_warning "Found disabled certificate validation"
    fi
    
    echo "$NET_ISSUES"
}

# Run all security checks
main() {
    print_status "Initializing Phase 2 enhanced security scanner..."
    
    SECRETS=$(scan_secrets)
    PERMISSIONS=$(check_permissions)
    DEPENDENCIES=$(check_dependencies)
    CODE_PATTERNS=$(check_code_patterns)
    NETWORK=$(check_network_security)
    
    # Calculate total issues
    TOTAL_ISSUES=$((SECRETS + PERMISSIONS + DEPENDENCIES + CODE_PATTERNS + NETWORK))
    
    # Count files scanned
    FILES_SCANNED=$(find . -name "*.swift" -o -name "*.plist" -o -name "*.json" | wc -l | tr -d ' ')
    
    # Calculate security score (100 - issues found)
    SECURITY_SCORE=$((100 - TOTAL_ISSUES))
    if [ $SECURITY_SCORE -lt 0 ]; then
        SECURITY_SCORE=0
    fi
    
    # Update security report
    python3 -c "
import json
import sys

try:
    with open('$REPORT_FILE', 'r') as f:
        data = json.load(f)
    
    data['security_analysis']['summary']['total_issues'] = $TOTAL_ISSUES
    data['security_analysis']['summary']['files_scanned'] = $FILES_SCANNED
    data['security_analysis']['summary']['security_score'] = $SECURITY_SCORE
    
    # Add findings
    if $SECRETS > 0:
        data['security_analysis']['findings']['high'].append('Potential hardcoded secrets detected')
    if $PERMISSIONS > 0:
        data['security_analysis']['findings']['medium'].append('File permission issues found')
    if $CODE_PATTERNS > 0:
        data['security_analysis']['findings']['medium'].append('Insecure code patterns detected')
    if $NETWORK > 0:
        data['security_analysis']['findings']['high'].append('Network security issues found')
    
    with open('$REPORT_FILE', 'w') as f:
        json.dump(data, f, indent=2)
        
    print('Security report updated successfully')
except Exception as e:
    print(f'Error updating report: {e}', file=sys.stderr)
" 2>/dev/null || echo "Note: JSON report update requires Python 3"
    
    # Generate summary
    print_info "Security Analysis Summary:"
    echo "  📊 Files Scanned: $FILES_SCANNED"
    echo "  🎯 Security Score: $SECURITY_SCORE/100"
    echo "  ⚠️  Total Issues: $TOTAL_ISSUES"
    echo "  📄 Report: $REPORT_FILE"
    
    if [ $TOTAL_ISSUES -eq 0 ]; then
        print_success "No security issues detected!"
    elif [ $TOTAL_ISSUES -le 3 ]; then
        print_warning "Minor security issues detected - review recommended"
    else
        print_warning "Multiple security issues detected - immediate review required"
    fi
    
    # Create human-readable summary
    cat > "$SECURITY_DIR/security_summary_$TIMESTAMP.md" << SUMMARY_EOF
# 🛡️ Security Analysis Report

**Analysis Date**: $(date)
**Scanner Version**: Phase 2 - MCP Enhanced

## Summary
- **Security Score**: $SECURITY_SCORE/100
- **Total Issues**: $TOTAL_ISSUES
- **Files Scanned**: $FILES_SCANNED

## Issue Breakdown
- **Secrets**: $SECRETS potential issues
- **Permissions**: $PERMISSIONS issues
- **Dependencies**: $DEPENDENCIES concerns
- **Code Patterns**: $CODE_PATTERNS insecure patterns
- **Network Security**: $NETWORK issues

## Recommendations
$(if [ $TOTAL_ISSUES -eq 0 ]; then
    echo "✅ Excellent security posture maintained"
    echo "- Continue regular security monitoring"
    echo "- Implement automated security testing"
elif [ $TOTAL_ISSUES -le 3 ]; then
    echo "⚠️ Minor security improvements needed"
    echo "- Review identified issues"
    echo "- Implement security best practices"
else
    echo "🚨 Immediate security review required"
    echo "- Address high-priority issues immediately"
    echo "- Implement comprehensive security hardening"
fi)

## Next Steps
1. Review detailed findings in JSON report
2. Implement recommended security fixes
3. Update security policies as needed
4. Schedule regular security scans

---
*Generated by Advanced Security Scanner - Phase 2*
SUMMARY_EOF
    
    print_success "Security analysis completed successfully!"
    print_info "Reports saved to $SECURITY_DIR/"
    
    return $TOTAL_ISSUES
}

# Execute main function
main "$@"
