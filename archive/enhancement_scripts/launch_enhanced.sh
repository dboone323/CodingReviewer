#!/bin/bash

# 🎯 Enhanced CodingReviewer Launcher
# Quick access to all enhanced automation capabilities

PROJECT_PATH="/Users/danielstevens/Desktop/CodingReviewer"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}${CYAN}🎯 Enhanced CodingReviewer Launcher${NC}"
echo -e "${BOLD}${CYAN}===================================${NC}"
echo ""

cd "$PROJECT_PATH"

show_menu() {
    echo -e "${BOLD}Choose an option:${NC}"
    echo ""
    echo -e "${GREEN}1.${NC} 🚀 Run Full Enhanced Workflow (All phases)"
    echo -e "${GREEN}2.${NC} 🧪 Quick Integration Tests Only"
    echo -e "${GREEN}3.${NC} 🔍 Code Quality Enhancement Only"
    echo -e "${GREEN}4.${NC} 📊 Open Jupyter Analysis Notebook"
    echo -e "${GREEN}5.${NC} 🐍 Python Tests Only"
    echo -e "${GREEN}6.${NC} 🏃‍♂️ Swift Tests Only"
    echo -e "${GREEN}7.${NC} 📈 Performance Monitoring"
    echo -e "${GREEN}8.${NC} 🤖 Run Existing Master Automation"
    echo -e "${GREEN}9.${NC} 📋 View Recent Results"
    echo -e "${GREEN}0.${NC} ❌ Exit"
    echo ""
    echo -ne "${YELLOW}Enter your choice (0-9): ${NC}"
}

run_full_workflow() {
    echo -e "\n${BOLD}${CYAN}🚀 Running Full Enhanced Workflow${NC}"
    echo "=================================="
    ./master_enhanced_workflow.sh
}

run_integration_tests() {
    echo -e "\n${BOLD}${BLUE}🧪 Running Integration Tests${NC}"
    echo "============================="
    ./integration_testing_system.sh
}

run_quality_enhancement() {
    echo -e "\n${BOLD}${PURPLE}🔍 Running Code Quality Enhancement${NC}"
    echo "==================================="
    ./automated_quality_enhancement.sh
}

open_jupyter_notebook() {
    echo -e "\n${BOLD}${GREEN}📊 Opening Jupyter Analysis Notebook${NC}"
    echo "===================================="
    if command -v code &> /dev/null; then
        code jupyter_notebooks/pylance_jupyter_integration.ipynb
    else
        open -a "Visual Studio Code" jupyter_notebooks/pylance_jupyter_integration.ipynb
    fi
}

run_python_tests() {
    echo -e "\n${BOLD}${YELLOW}🐍 Running Python Tests${NC}"
    echo "======================"
    if [[ -d ".venv" ]]; then
        source .venv/bin/activate
        python -m pytest python_tests/ -v --tb=short
    else
        echo -e "${RED}❌ Python environment not found${NC}"
    fi
}

run_swift_tests() {
    echo -e "\n${BOLD}${BLUE}🏃‍♂️ Running Swift Tests${NC}"
    echo "====================="
    xcodebuild test -project CodingReviewer.xcodeproj -scheme CodingReviewer -destination 'platform=macOS'
}

run_performance_monitoring() {
    echo -e "\n${BOLD}${RED}📈 Running Performance Monitoring${NC}"
    echo "================================"
    if [[ -f "advanced_performance_monitor.sh" ]]; then
        ./advanced_performance_monitor.sh
    else
        echo "Running basic performance check..."
        echo "Swift build test:"
        xcodebuild build -project CodingReviewer.xcodeproj -scheme CodingReviewer -destination 'platform=macOS'
        
        if [[ -d ".venv" ]]; then
            echo "Python performance test:"
            source .venv/bin/activate
            python -m pytest python_tests/ -m "performance" -v || echo "No performance tests marked"
        fi
    fi
}

run_master_automation() {
    echo -e "\n${BOLD}${CYAN}🤖 Running Master Automation${NC}"
    echo "==========================="
    if [[ -f "master_automation_orchestrator.sh" ]]; then
        timeout 300s ./master_automation_orchestrator.sh || echo "Master automation completed/timed out"
    else
        echo "Master automation script not found"
    fi
}

view_recent_results() {
    echo -e "\n${BOLD}${GREEN}📋 Recent Results${NC}"
    echo "================="
    
    # Find most recent workflow results
    if [[ -d ".workflow_results" ]]; then
        echo "Workflow results:"
        ls -lt .workflow_results/ | head -10
        echo ""
        
        # Find most recent view script
        recent_script=$(ls -t .workflow_results/view_results_*.sh 2>/dev/null | head -1)
        if [[ -n "$recent_script" ]]; then
            echo "Running most recent results viewer:"
            bash "$recent_script"
        fi
    else
        echo "No workflow results found yet. Run option 1 to generate results."
    fi
}

# Main loop
while true; do
    show_menu
    read -r choice
    
    case $choice in
        1) run_full_workflow ;;
        2) run_integration_tests ;;
        3) run_quality_enhancement ;;
        4) open_jupyter_notebook ;;
        5) run_python_tests ;;
        6) run_swift_tests ;;
        7) run_performance_monitoring ;;
        8) run_master_automation ;;
        9) view_recent_results ;;
        0) echo -e "\n${GREEN}👋 Thanks for using Enhanced CodingReviewer!${NC}"; exit 0 ;;
        *) echo -e "\n${RED}❌ Invalid choice. Please try again.${NC}" ;;
    esac
    
    echo ""
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read -r
    clear
done
