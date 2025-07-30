#!/bin/bash

# Performance Bottleneck Analyzer
# Predicts performance issues and suggests optimizations

analyze_performance_patterns() {
    local target_file="$1"
    local output_file="$2"
    
    echo "⚡ Analyzing performance patterns in $(basename "$target_file")..."
    
    cat > "$output_file" << REPORT
# Performance Analysis Report
File: $target_file
Generated: $(date)

## Performance Issues Detected

REPORT
    
    # Detect inefficient loops
    detect_inefficient_loops "$target_file" "$output_file"
    
    # Detect memory leaks potential
    detect_memory_issues "$target_file" "$output_file"
    
    # Detect inefficient string operations
    detect_string_performance_issues "$target_file" "$output_file"
    
    # Detect synchronous operations on main thread
    detect_main_thread_issues "$target_file" "$output_file"
    
    # Detect inefficient collections usage
    detect_collection_performance_issues "$target_file" "$output_file"
    
    echo "✅ Performance analysis complete"
}

detect_inefficient_loops() {
    local file="$1"
    local report="$2"
    
    echo "  • Checking for inefficient loops..."
    
    # Nested loops detection
    local nested_loops=$(grep -A 10 "for.*in" "$file" | grep -B 5 -A 5 "for.*in")
    
    if [ -n "$nested_loops" ]; then
        echo "### 🔄 Nested Loops Detected" >> "$report"
        echo "- **Risk**: O(n²) or higher complexity" >> "$report"
        echo "- **Suggestion**: Consider algorithm optimization or data structure changes" >> "$report"
        echo "" >> "$report"
    fi
    
    # Array operations in loops
    local array_ops_in_loops=$(grep -n "for.*in.*{" "$file" | grep -A 5 "\.append\|\.insert")
    
    if [ -n "$array_ops_in_loops" ]; then
        echo "### 📊 Array Operations in Loops" >> "$report"
        echo "- **Risk**: Repeated array operations can be expensive" >> "$report"
        echo "- **Suggestion**: Consider pre-allocating arrays or using more efficient data structures" >> "$report"
        echo "" >> "$report"
    fi
}

detect_memory_issues() {
    local file="$1"
    local report="$2"
    
    echo "  • Checking for potential memory issues..."
    
    # Strong reference cycles potential
    local strong_refs=$(grep -n "self\." "$file" | grep -v "weak\|unowned")
    local closure_count=$(grep -c "{.*in" "$file")
    
    if [ "$closure_count" -gt 0 ] && [ -n "$strong_refs" ]; then
        echo "### 🧠 Potential Memory Leaks" >> "$report"
        echo "- **Risk**: Strong reference cycles in closures" >> "$report"
        echo "- **Suggestion**: Use [weak self] or [unowned self] in closures" >> "$report"
        echo "" >> "$report"
    fi
    
    # Large object allocations
    local large_allocations=$(grep -n "Array\|Dictionary.*repeating\|Data(" "$file")
    
    if [ -n "$large_allocations" ]; then
        echo "### 📦 Large Object Allocations" >> "$report"
        echo "- **Risk**: High memory usage" >> "$report"
        echo "- **Suggestion**: Consider lazy loading or streaming for large data" >> "$report"
        echo "" >> "$report"
    fi
}

detect_string_performance_issues() {
    local file="$1"
    local report="$2"
    
    echo "  • Checking for string performance issues..."
    
    # String concatenation in loops
    local string_concat=$(grep -A 3 "for.*in" "$file" | grep "+=" | grep -v "Int\|Double")
    
    if [ -n "$string_concat" ]; then
        echo "### 🔤 String Concatenation in Loops" >> "$report"
        echo "- **Risk**: O(n²) string building complexity" >> "$report"
        echo "- **Suggestion**: Use StringBuilder or joined() method" >> "$report"
        echo "" >> "$report"
    fi
}

detect_main_thread_issues() {
    local file="$1"
    local report="$2"
    
    echo "  • Checking for main thread blocking operations..."
    
    # Synchronous network operations
    local sync_ops=$(grep -n "URLSession.*dataTask\|NSData.*contentsOf\|String.*contentsOf" "$file")
    
    if [ -n "$sync_ops" ]; then
        echo "### 🚦 Main Thread Blocking Operations" >> "$report"
        echo "- **Risk**: UI freezing and poor user experience" >> "$report"
        echo "- **Suggestion**: Move to background queue or use async/await" >> "$report"
        echo "" >> "$report"
    fi
    
    # Heavy computations without async
    local heavy_ops=$(grep -n "sort()\|filter\|map\|reduce" "$file" | grep -v "async")
    
    if [ -n "$heavy_ops" ]; then
        local line_count=$(echo "$heavy_ops" | wc -l)
        if [ "$line_count" -gt 3 ]; then
            echo "### 🖥️ Heavy Computations on Main Thread" >> "$report"
            echo "- **Risk**: UI responsiveness issues" >> "$report"
            echo "- **Suggestion**: Consider async processing for heavy operations" >> "$report"
            echo "" >> "$report"
        fi
    fi
}

detect_collection_performance_issues() {
    local file="$1"
    local report="$2"
    
    echo "  • Checking for collection performance issues..."
    
    # Inefficient lookups
    local array_contains=$(grep -n "\.contains\|\.firstIndex" "$file")
    
    if [ -n "$array_contains" ]; then
        echo "### 🔍 Potentially Inefficient Lookups" >> "$report"
        echo "- **Risk**: O(n) lookup complexity in arrays" >> "$report"
        echo "- **Suggestion**: Consider using Set or Dictionary for frequent lookups" >> "$report"
        echo "" >> "$report"
    fi
}

# Generate performance optimization suggestions
generate_performance_suggestions() {
    local analysis_file="$1"
    local suggestions_file="$2"
    
    cat > "$suggestions_file" << SUGGESTIONS
# Performance Optimization Suggestions
Generated: $(date)

## Recommended Optimizations

### Immediate Actions
1. **Async/Await**: Convert synchronous operations to asynchronous
2. **Weak References**: Add weak/unowned references in closures
3. **Collection Optimization**: Replace arrays with sets/dictionaries for lookups

### Code Structure Improvements
1. **Algorithm Optimization**: Replace nested loops with more efficient algorithms
2. **Lazy Loading**: Implement lazy loading for heavy resources
3. **Memory Management**: Optimize object lifecycle and caching strategies

### Monitoring Recommendations
1. **Instruments Profiling**: Use Xcode Instruments for detailed analysis
2. **Performance Tests**: Add performance tests for critical paths
3. **Memory Monitoring**: Implement memory usage tracking

## Automated Fixes Available
- Convert to async/await patterns
- Add weak reference annotations
- Replace inefficient collection operations

SUGGESTIONS
}

