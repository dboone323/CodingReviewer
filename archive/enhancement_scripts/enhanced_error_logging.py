#!/usr/bin/env python3
"""
Enhanced Error Logging Framework
Comprehensive error handling and logging system for AI operations

This framework provides structured error logging, monitoring, and alerting
capabilities for all AI-driven development operations.
"""

import logging
import json
import traceback
from datetime import datetime
from typing import Dict, List, Optional, Any, Union
from pathlib import Path
from dataclasses import dataclass, asdict
from enum import Enum
import sys

class ErrorSeverity(Enum):
    """Error severity levels"""
    CRITICAL = "critical"
    ERROR = "error"
    WARNING = "warning"
    INFO = "info"
    DEBUG = "debug"

class ErrorCategory(Enum):
    """Error categories for classification"""
    SYSTEM_INTEGRATION = "system_integration"
    AI_ANALYSIS = "ai_analysis"
    CODE_REVIEW = "code_review"
    CROSS_PROJECT_LEARNING = "cross_project_learning"
    PREDICTIVE_PLANNING = "predictive_planning"
    DATA_PROCESSING = "data_processing"
    CONFIGURATION = "configuration"
    PERFORMANCE = "performance"
    SECURITY = "security"

@dataclass
class ErrorEvent:
    """Structured error event"""
    timestamp: datetime
    severity: ErrorSeverity
    category: ErrorCategory
    component: str
    message: str
    details: Optional[Dict[str, Any]] = None
    traceback_info: Optional[str] = None
    context: Optional[Dict[str, Any]] = None
    resolution_suggested: Optional[str] = None

class EnhancedErrorLogger:
    """Enhanced error logging with structured reporting"""
    
    def __init__(self, log_dir: str = ".error_logs"):
        self.log_dir = Path(log_dir)
        self.log_dir.mkdir(exist_ok=True)
        
        # Setup structured logging
        self.error_log_file = self.log_dir / "ai_operations_errors.jsonl"
        self.summary_log_file = self.log_dir / "error_summary.json"
        
        # Error tracking
        self.error_events: List[ErrorEvent] = []
        self.error_counts = {
            "critical": 0,
            "error": 0,
            "warning": 0,
            "info": 0,
            "debug": 0
        }
        
        # Setup Python logging
        self._setup_python_logging()
        
        # Error patterns for suggestions
        self.error_patterns = {
            "integration": {
                "patterns": ["'list' object has no attribute", "cannot import", "module not found"],
                "suggestion": "Check data types and imports between AI system integrations"
            },
            "data_format": {
                "patterns": ["KeyError", "AttributeError", "TypeError"],
                "suggestion": "Verify data structure consistency across AI components"
            },
            "async_operation": {
                "patterns": ["RuntimeError", "asyncio", "event loop"],
                "suggestion": "Review async/await patterns and event loop handling"
            },
            "file_operation": {
                "patterns": ["FileNotFoundError", "PermissionError", "IsADirectoryError"],
                "suggestion": "Check file paths and permissions for AI system operations"
            }
        }
    
    def _setup_python_logging(self):
        """Setup Python logging configuration"""
        # Create formatters
        console_formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        
        file_formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(funcName)s:%(lineno)d - %(message)s'
        )
        
        # Setup file handler
        file_handler = logging.FileHandler(self.log_dir / "ai_operations.log")
        file_handler.setLevel(logging.DEBUG)
        file_handler.setFormatter(file_formatter)
        
        # Setup console handler
        console_handler = logging.StreamHandler(sys.stdout)
        console_handler.setLevel(logging.INFO)
        console_handler.setFormatter(console_formatter)
        
        # Configure root logger
        root_logger = logging.getLogger()
        root_logger.setLevel(logging.DEBUG)
        root_logger.addHandler(file_handler)
        root_logger.addHandler(console_handler)
    
    def log_error(self, 
                  severity: ErrorSeverity,
                  category: ErrorCategory,
                  component: str,
                  message: str,
                  details: Optional[Dict[str, Any]] = None,
                  exception: Optional[Exception] = None,
                  context: Optional[Dict[str, Any]] = None) -> ErrorEvent:
        """Log a structured error event"""
        
        # Extract traceback if exception provided
        traceback_info = None
        if exception:
            traceback_info = traceback.format_exc()
        
        # Generate resolution suggestion
        resolution_suggested = self._suggest_resolution(message, exception)
        
        # Create error event
        error_event = ErrorEvent(
            timestamp=datetime.now(),
            severity=severity,
            category=category,
            component=component,
            message=message,
            details=details or {},
            traceback_info=traceback_info,
            context=context or {},
            resolution_suggested=resolution_suggested
        )
        
        # Store error event
        self.error_events.append(error_event)
        self.error_counts[severity.value] += 1
        
        # Log to structured file
        self._log_to_structured_file(error_event)
        
        # Log to Python logging system
        self._log_to_python_logger(error_event)
        
        # Update summary
        self._update_error_summary()
        
        return error_event
    
    def _suggest_resolution(self, message: str, exception: Optional[Exception]) -> str:
        """Suggest resolution based on error patterns"""
        error_text = message.lower()
        if exception:
            error_text += f" {str(exception).lower()}"
        
        for pattern_name, pattern_info in self.error_patterns.items():
            for pattern in pattern_info["patterns"]:
                if pattern.lower() in error_text:
                    return pattern_info["suggestion"]
        
        return "Review error details and consult documentation"
    
    def _log_to_structured_file(self, error_event: ErrorEvent):
        """Log to structured JSONL file"""
        try:
            with open(self.error_log_file, 'a') as f:
                event_dict = asdict(error_event)
                # Convert datetime and enum to strings
                event_dict['timestamp'] = error_event.timestamp.isoformat()
                event_dict['severity'] = error_event.severity.value
                event_dict['category'] = error_event.category.value
                
                f.write(json.dumps(event_dict) + '\n')
        except Exception as e:
            print(f"Failed to log to structured file: {e}")
    
    def _log_to_python_logger(self, error_event: ErrorEvent):
        """Log to Python logging system"""
        logger = logging.getLogger(error_event.component)
        
        log_message = f"[{error_event.category.value}] {error_event.message}"
        if error_event.details:
            log_message += f" | Details: {error_event.details}"
        
        # Map severity to logging level
        level_mapping = {
            ErrorSeverity.CRITICAL: logging.CRITICAL,
            ErrorSeverity.ERROR: logging.ERROR,
            ErrorSeverity.WARNING: logging.WARNING,
            ErrorSeverity.INFO: logging.INFO,
            ErrorSeverity.DEBUG: logging.DEBUG
        }
        
        logger.log(level_mapping[error_event.severity], log_message)
        
        # Log traceback separately if available
        if error_event.traceback_info:
            logger.debug(f"Traceback: {error_event.traceback_info}")
    
    def _update_error_summary(self):
        """Update error summary file"""
        try:
            summary = {
                "last_updated": datetime.now().isoformat(),
                "total_errors": len(self.error_events),
                "error_counts": self.error_counts,
                "recent_critical_errors": [
                    asdict(event) for event in self.error_events[-5:]
                    if event.severity == ErrorSeverity.CRITICAL
                ],
                "top_error_categories": self._get_top_error_categories(),
                "resolution_suggestions": self._get_common_suggestions()
            }
            
            with open(self.summary_log_file, 'w') as f:
                json.dump(summary, f, indent=2, default=str)
        except Exception as e:
            print(f"Failed to update error summary: {e}")
    
    def _get_top_error_categories(self) -> Dict[str, int]:
        """Get top error categories by frequency"""
        category_counts = {}
        for event in self.error_events:
            category = event.category.value
            category_counts[category] = category_counts.get(category, 0) + 1
        
        return dict(sorted(category_counts.items(), key=lambda x: x[1], reverse=True)[:5])
    
    def _get_common_suggestions(self) -> List[str]:
        """Get most common resolution suggestions"""
        suggestions = {}
        for event in self.error_events:
            if event.resolution_suggested:
                suggestions[event.resolution_suggested] = suggestions.get(event.resolution_suggested, 0) + 1
        
        return [suggestion for suggestion, _ in sorted(suggestions.items(), key=lambda x: x[1], reverse=True)[:3]]
    
    def get_error_report(self) -> Dict[str, Any]:
        """Generate comprehensive error report"""
        return {
            "report_timestamp": datetime.now().isoformat(),
            "total_errors": len(self.error_events),
            "error_distribution": self.error_counts,
            "critical_errors_last_24h": len([
                e for e in self.error_events 
                if e.severity == ErrorSeverity.CRITICAL and 
                (datetime.now() - e.timestamp).days < 1
            ]),
            "top_error_categories": self._get_top_error_categories(),
            "recent_errors": [
                {
                    "timestamp": event.timestamp.isoformat(),
                    "severity": event.severity.value,
                    "category": event.category.value,
                    "component": event.component,
                    "message": event.message
                }
                for event in self.error_events[-10:]
            ],
            "system_health_impact": self._assess_system_health_impact(),
            "recommended_actions": self._get_recommended_actions()
        }
    
    def _assess_system_health_impact(self) -> Dict[str, Any]:
        """Assess impact on system health"""
        critical_count = self.error_counts["critical"]
        error_count = self.error_counts["error"]
        
        if critical_count > 0:
            health_status = "critical"
            impact_level = "high"
        elif error_count > 5:
            health_status = "degraded"
            impact_level = "medium"
        elif error_count > 0:
            health_status = "stable_with_issues"
            impact_level = "low"
        else:
            health_status = "healthy"
            impact_level = "none"
        
        return {
            "health_status": health_status,
            "impact_level": impact_level,
            "reliability_score": max(0, 100 - (critical_count * 25 + error_count * 5)),
            "trending": "improving" if len(self.error_events) < 10 else "stable"
        }
    
    def _get_recommended_actions(self) -> List[str]:
        """Get recommended actions based on error patterns"""
        actions = []
        
        if self.error_counts["critical"] > 0:
            actions.append("🚨 Address critical errors immediately")
        
        if self.error_counts["error"] > 3:
            actions.append("⚠️ Review and fix recurring error patterns")
        
        # Category-specific recommendations
        category_counts = self._get_top_error_categories()
        
        if "system_integration" in category_counts and category_counts["system_integration"] > 2:
            actions.append("🔧 Improve system integration testing and data validation")
        
        if "ai_analysis" in category_counts and category_counts["ai_analysis"] > 2:
            actions.append("🤖 Review AI analysis pipeline for stability issues")
        
        if not actions:
            actions.append("✅ System operating normally - continue monitoring")
        
        return actions

# Global error logger instance
error_logger = EnhancedErrorLogger()

# Convenience functions for easy logging
def log_critical(component: str, message: str, category: ErrorCategory = ErrorCategory.SYSTEM_INTEGRATION, **kwargs) -> Any:
    """Log critical error"""
    return error_logger.log_error(ErrorSeverity.CRITICAL, category, component, message, **kwargs)

def log_error(component: str, message: str, category: ErrorCategory = ErrorCategory.SYSTEM_INTEGRATION, **kwargs) -> Any:
    """Log error"""
    return error_logger.log_error(ErrorSeverity.ERROR, category, component, message, **kwargs)

def log_warning(component: str, message: str, category: ErrorCategory = ErrorCategory.SYSTEM_INTEGRATION, **kwargs) -> Any:
    """Log warning"""
    return error_logger.log_error(ErrorSeverity.WARNING, category, component, message, **kwargs)

def log_info(component: str, message: str, category: ErrorCategory = ErrorCategory.SYSTEM_INTEGRATION, **kwargs) -> Any:
    """Log info"""
    return error_logger.log_error(ErrorSeverity.INFO, category, component, message, **kwargs)

# Context manager for error handling
class ErrorHandlingContext:
    """Context manager for automatic error logging"""
    
    def __init__(self, component: str, operation: str, category: ErrorCategory = ErrorCategory.SYSTEM_INTEGRATION):
        self.component = component
        self.operation = operation
        self.category = category
    
    def __enter__(self):
        log_info(self.component, f"Starting operation: {self.operation}", self.category)
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        if exc_type is not None:
            log_error(
                self.component, 
                f"Operation failed: {self.operation}",
                self.category,
                exception=exc_val,
                details={"operation": self.operation, "error_type": exc_type.__name__}
            )
            return False  # Don't suppress the exception
        else:
            log_info(self.component, f"Operation completed: {self.operation}", self.category)

# Decorator for automatic error logging
def log_errors(component: str, category: ErrorCategory = ErrorCategory.SYSTEM_INTEGRATION) -> Any:
    """Decorator to automatically log function errors"""
    def decorator(func) -> Any:
        def wrapper(*args, **kwargs) -> Any:
            try:
                return func(*args, **kwargs)
            except Exception as e:
                log_error(
                    component,
                    f"Function {func.__name__} failed: {str(e)}",
                    category,
                    exception=e,
                    details={"function": func.__name__, "args_count": len(args), "kwargs": list(kwargs.keys())}
                )
                raise
        return wrapper
    return decorator

# Demo function
def main():
    """Demo the enhanced error logging framework"""
    print("🔍 Enhanced Error Logging Framework Demo")
    
    # Log some sample errors
    log_info("demo", "Starting error logging demo")
    
    log_warning(
        "ai_dashboard", 
        "Dashboard integration mismatch detected",
        ErrorCategory.SYSTEM_INTEGRATION,
        details={"expected": "dict", "received": "list"}
    )
    
    log_error(
        "code_reviewer",
        "Failed to parse code review results",
        ErrorCategory.CODE_REVIEW,
        details={"file": "example.py", "parser": "ast"}
    )
    
    # Simulate exception logging
    try:
        raise ValueError("Sample integration error for demo")
    except Exception as e:
        log_critical(
            "mcp_integration",
            "Critical integration failure",
            ErrorCategory.AI_ANALYSIS,
            exception=e,
            context={"operation": "comprehensive_analysis", "phase": "data_aggregation"}
        )
    
    # Generate report
    report = error_logger.get_error_report()
    print("\n📊 Error Report:")
    print(f"Total Errors: {report['total_errors']}")
    print(f"System Health: {report['system_health_impact']['health_status']}")
    print(f"Recommended Actions: {report['recommended_actions'][0]}")

if __name__ == "__main__":
    main()