#!/bin/bash

# 🔬 ML Health Monitoring & Data Refresh Automation
# Ensures ML integration stays healthy with fresh data

set -eo pipefail

PROJECT_PATH="/Users/danielstevens/Desktop/CodingReviewer"
ML_HEALTH_DIR="$PROJECT_PATH/.ml_health"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="$ML_HEALTH_DIR/ml_health_$TIMESTAMP.log"

mkdir -p "$ML_HEALTH_DIR"

echo "🔬 ML Health Monitoring & Data Refresh v1.0" | tee "$LOG_FILE"
echo "============================================" | tee -a "$LOG_FILE"
echo "Started: $(date)" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}❌ $1${NC}" | tee -a "$LOG_FILE"
}

# Health check counters
HEALTH_SCORE=0
TOTAL_CHECKS=0

check_ml_data_freshness() {
    log_info "Checking ML data freshness..."
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    # Check .ml_automation/data/
    if [[ -d ".ml_automation/data" ]]; then
        LATEST_ML=$(find .ml_automation/data -name "code_analysis_*.json" -type f -exec stat -f "%m %N" {} \; | sort -nr | head -1 | cut -d' ' -f2-)
        if [[ -n "$LATEST_ML" ]]; then
            AGE=$((($(date +%s) - $(stat -f "%m" "$LATEST_ML")) / 3600))
            if [[ $AGE -lt 24 ]]; then
                log_success "ML automation data is fresh (${AGE}h old)"
                HEALTH_SCORE=$((HEALTH_SCORE + 1))
            else
                log_warning "ML automation data is stale (${AGE}h old)"
            fi
        else
            log_error "No ML automation data found"
        fi
    else
        log_error "ML automation directory missing"
    fi
}

check_predictive_analytics() {
    log_info "Checking predictive analytics..."
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    if [[ -d ".predictive_analytics" ]]; then
        LATEST_PRED=$(find .predictive_analytics -name "dashboard_*.html" -type f -exec stat -f "%m %N" {} \; | sort -nr | head -1 | cut -d' ' -f2-)
        if [[ -n "$LATEST_PRED" ]]; then
            AGE=$((($(date +%s) - $(stat -f "%m" "$LATEST_PRED")) / 3600))
            if [[ $AGE -lt 24 ]]; then
                log_success "Predictive analytics data is fresh (${AGE}h old)"
                HEALTH_SCORE=$((HEALTH_SCORE + 1))
            else
                log_warning "Predictive analytics data is stale (${AGE}h old)"
            fi
        else
            log_error "No predictive analytics data found"
        fi
    else
        log_error "Predictive analytics directory missing"
    fi
}

check_cross_project_learning() {
    log_info "Checking cross-project learning..."
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    if [[ -d ".cross_project_learning/insights" ]]; then
        LATEST_CPL=$(find .cross_project_learning/insights -name "cross_patterns_*.md" -type f -exec stat -f "%m %N" {} \; | sort -nr | head -1 | cut -d' ' -f2-)
        if [[ -n "$LATEST_CPL" ]]; then
            AGE=$((($(date +%s) - $(stat -f "%m" "$LATEST_CPL")) / 3600))
            if [[ $AGE -lt 24 ]]; then
                log_success "Cross-project learning data is fresh (${AGE}h old)"
                HEALTH_SCORE=$((HEALTH_SCORE + 1))
            else
                log_warning "Cross-project learning data is stale (${AGE}h old)"
            fi
        else
            log_error "No cross-project learning data found"
        fi
    else
        log_error "Cross-project learning directory missing"
    fi
}

check_app_build() {
    log_info "Checking app build status..."
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    if xcodebuild -project CodingReviewer.xcodeproj -scheme CodingReviewer -destination 'platform=macOS' build -quiet > /dev/null 2>&1; then
        log_success "App builds successfully"
        HEALTH_SCORE=$((HEALTH_SCORE + 1))
    else
        log_error "App build failed"
    fi
}

refresh_ml_data() {
    log_info "Refreshing ML data..."
    
    # Run ML automation scripts if data is stale
    if [[ -x "./ai_learning_accelerator.sh" ]]; then
        log_info "Running AI learning accelerator..."
        ./ai_learning_accelerator.sh >> "$LOG_FILE" 2>&1 && log_success "AI learning accelerator completed" || log_warning "AI learning accelerator had issues"
    fi
    
    if [[ -x "./advanced_ai_integration.sh" ]]; then
        log_info "Running advanced AI integration..."
        ./advanced_ai_integration.sh >> "$LOG_FILE" 2>&1 && log_success "Advanced AI integration completed" || log_warning "Advanced AI integration had issues"
    fi
    
    if [[ -x "./cross_project_learning.sh" ]]; then
        log_info "Running cross-project learning..."
        ./cross_project_learning.sh >> "$LOG_FILE" 2>&1 && log_success "Cross-project learning completed" || log_warning "Cross-project learning had issues"
    fi
}

generate_health_report() {
    local health_percentage=$((HEALTH_SCORE * 100 / TOTAL_CHECKS))
    local status="UNKNOWN"
    
    if [[ $health_percentage -ge 80 ]]; then
        status="HEALTHY"
    elif [[ $health_percentage -ge 60 ]]; then
        status="WARNING"
    else
        status="CRITICAL"
    fi
    
    cat > "$ML_HEALTH_DIR/health_status.json" << EOF
{
    "timestamp": "$(date -Iseconds)",
    "health_score": $health_percentage,
    "status": "$status",
    "total_checks": $TOTAL_CHECKS,
    "passed_checks": $HEALTH_SCORE,
    "last_refresh": "$(date -Iseconds)"
}
EOF
    
    log_info "Health Report Generated:"
    echo "  📊 Health Score: ${health_percentage}%" | tee -a "$LOG_FILE"
    echo "  🔍 Status: $status" | tee -a "$LOG_FILE"
    echo "  ✓ Passed Checks: $HEALTH_SCORE/$TOTAL_CHECKS" | tee -a "$LOG_FILE"
}

# Main execution
log_info "Starting ML health monitoring..."

check_ml_data_freshness
check_predictive_analytics
check_cross_project_learning
check_app_build

# If health score is low, refresh data
if [[ $HEALTH_SCORE -lt $((TOTAL_CHECKS * 3 / 4)) ]]; then
    log_warning "Health score below threshold, refreshing ML data..."
    refresh_ml_data
    
    # Re-check after refresh
    HEALTH_SCORE=0
    TOTAL_CHECKS=0
    check_ml_data_freshness
    check_predictive_analytics
    check_cross_project_learning
fi

generate_health_report

echo "" | tee -a "$LOG_FILE"
echo "🔬 ML Health Monitoring completed at $(date)" | tee -a "$LOG_FILE"
echo "📋 Report saved to: $ML_HEALTH_DIR/health_status.json" | tee -a "$LOG_FILE"

# Set up cron job for automated monitoring (optional)
if [[ "$1" == "--setup-cron" ]]; then
    log_info "Setting up automated ML health monitoring..."
    
    # Create wrapper script for cron
    cat > "$ML_HEALTH_DIR/cron_ml_health.sh" << 'EOF'
#!/bin/bash
cd /Users/danielstevens/Desktop/CodingReviewer
./ml_health_monitor.sh >> .ml_health/cron.log 2>&1
EOF
    
    chmod +x "$ML_HEALTH_DIR/cron_ml_health.sh"
    
    # Suggest cron entry
    echo ""
    echo "To set up automated monitoring, add this to your crontab (crontab -e):"
    echo "# ML Health Monitoring - every 4 hours"
    echo "0 */4 * * * $ML_HEALTH_DIR/cron_ml_health.sh"
    echo ""
fi
