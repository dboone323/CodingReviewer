#!/bin/bash

# Security Vulnerability Analyzer
# Detects potential security issues and suggests fixes

analyze_security_patterns() {
    local target_file="$1"
    local output_file="$2"
    
    echo "🔒 Analyzing security patterns in $(basename "$target_file")..."
    
    cat > "$output_file" << REPORT
# Security Analysis Report
File: $target_file
Generated: $(date)

## Security Issues Detected

REPORT
    
    # Check for hardcoded secrets
    detect_hardcoded_secrets "$target_file" "$output_file"
    
    # Check for unsafe network operations
    detect_unsafe_network_operations "$target_file" "$output_file"
    
    # Check for input validation issues
    detect_input_validation_issues "$target_file" "$output_file"
    
    # Check for unsafe data storage
    detect_unsafe_data_storage "$target_file" "$output_file"
    
    # Check for cryptographic issues
    detect_cryptographic_issues "$target_file" "$output_file"
    
    echo "✅ Security analysis complete"
}

detect_hardcoded_secrets() {
    local file="$1"
    local report="$2"
    
    echo "  • Checking for hardcoded secrets..."
    
    # Common patterns for hardcoded secrets
    local secrets=$(grep -in "password\s*=\|key\s*=\|token\s*=\|secret\s*=" "$file" | grep -v "//")
    
    if [ -n "$secrets" ]; then
        echo "### 🔑 Hardcoded Secrets Detected" >> "$report"
        echo "$secrets" | while IFS= read -r line; do
            local line_num=$(echo "$line" | cut -d: -f1)
            echo "- **Line $line_num**: Potential hardcoded secret" >> "$report"
        done
        echo "- **Risk**: Credentials exposed in source code" >> "$report"
        echo "- **Suggestion**: Use keychain, environment variables, or secure storage" >> "$report"
        echo "" >> "$report"
    fi
    
    # API keys in strings
    local api_keys=$(grep -in "\"[A-Za-z0-9]\{20,\}\"" "$file")
    
    if [ -n "$api_keys" ]; then
        echo "### 🔐 Potential API Keys" >> "$report"
        echo "- **Risk**: API keys in string literals" >> "$report"
        echo "- **Suggestion**: Move to secure configuration or keychain" >> "$report"
        echo "" >> "$report"
    fi
}

detect_unsafe_network_operations() {
    local file="$1"
    local report="$2"
    
    echo "  • Checking for unsafe network operations..."
    
    # HTTP instead of HTTPS
    local http_usage=$(grep -in "http://" "$file")
    
    if [ -n "$http_usage" ]; then
        echo "### 🌐 Insecure Network Communication" >> "$report"
        echo "- **Risk**: Unencrypted HTTP communication" >> "$report"
        echo "- **Suggestion**: Use HTTPS for all network communications" >> "$report"
        echo "" >> "$report"
    fi
    
    # Disabled SSL verification
    local ssl_issues=$(grep -in "allowsArbitraryLoads\|NSExceptionAllowsInsecureHTTPLoads" "$file")
    
    if [ -n "$ssl_issues" ]; then
        echo "### 🚫 Disabled SSL Verification" >> "$report"
        echo "- **Risk**: Man-in-the-middle attacks possible" >> "$report"
        echo "- **Suggestion**: Enable proper SSL/TLS verification" >> "$report"
        echo "" >> "$report"
    fi
}

detect_input_validation_issues() {
    local file="$1"
    local report="$2"
    
    echo "  • Checking for input validation issues..."
    
    # Direct string interpolation without validation
    local string_interp=$(grep -in "\\(.*)\\|String.*format" "$file")
    
    if [ -n "$string_interp" ]; then
        echo "### ⚠️ Potential Input Validation Issues" >> "$report"
        echo "- **Risk**: Unvalidated input in string operations" >> "$report"
        echo "- **Suggestion**: Validate and sanitize all user inputs" >> "$report"
        echo "" >> "$report"
    fi
    
    # SQL-like operations (for Core Data)
    local sql_like=$(grep -in "NSPredicate.*format\|fetch.*predicate" "$file")
    
    if [ -n "$sql_like" ]; then
        echo "### 💉 Potential Injection Vulnerabilities" >> "$report"
        echo "- **Risk**: Unsafe predicate construction" >> "$report"
        echo "- **Suggestion**: Use parameterized queries and input validation" >> "$report"
        echo "" >> "$report"
    fi
}

detect_unsafe_data_storage() {
    local file="$1"
    local report="$2"
    
    echo "  • Checking for unsafe data storage..."
    
    # UserDefaults for sensitive data
    local userdefaults_usage=$(grep -in "UserDefaults\|NSUserDefaults" "$file")
    
    if [ -n "$userdefaults_usage" ]; then
        echo "### 💾 Potentially Unsafe Data Storage" >> "$report"
        echo "- **Risk**: Sensitive data in UserDefaults (unencrypted)" >> "$report"
        echo "- **Suggestion**: Use Keychain for sensitive data storage" >> "$report"
        echo "" >> "$report"
    fi
    
    # File system storage without encryption
    local file_storage=$(grep -in "writeToFile\|contentsOfFile" "$file")
    
    if [ -n "$file_storage" ]; then
        echo "### 📁 Unencrypted File Storage" >> "$report"
        echo "- **Risk**: Sensitive data stored without encryption" >> "$report"
        echo "- **Suggestion**: Encrypt sensitive data before storage" >> "$report"
        echo "" >> "$report"
    fi
}

detect_cryptographic_issues() {
    local file="$1"
    local report="$2"
    
    echo "  • Checking for cryptographic issues..."
    
    # Weak encryption algorithms
    local weak_crypto=$(grep -in "MD5\|SHA1\|DES\|RC4" "$file")
    
    if [ -n "$weak_crypto" ]; then
        echo "### 🔓 Weak Cryptographic Algorithms" >> "$report"
        echo "- **Risk**: Cryptographically weak algorithms detected" >> "$report"
        echo "- **Suggestion**: Use SHA-256, AES, or other modern algorithms" >> "$report"
        echo "" >> "$report"
    fi
    
    # Random number generation
    local random_usage=$(grep -in "arc4random\|random\|rand" "$file")
    
    if [ -n "$random_usage" ]; then
        echo "### 🎲 Random Number Generation" >> "$report"
        echo "- **Info**: Ensure cryptographically secure random numbers for security purposes" >> "$report"
        echo "- **Suggestion**: Use SecRandomCopyBytes for cryptographic randomness" >> "$report"
        echo "" >> "$report"
    fi
}

