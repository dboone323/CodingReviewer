"""
CodingReviewer Testing Framework - Data Models

Contains the core data structures for test results and test suites.
Following ARCHITECTURE.md - pure data models with no UI dependencies.
"""

from dataclasses import dataclass
from datetime import datetime
from typing import List, Optional


@dataclass
class CodingTestResult:
    """Represents a single test result."""
    name: str
    status: str  # "passed", "failed", "skipped", "error"
    duration: float
    error_message: Optional[str] = None
    file_path: Optional[str] = None
    line_number: Optional[int] = None
    timestamp: Optional[datetime] = None
    output: Optional[str] = None  # Additional test output/logs
    
    def __post_init__(self):
        if self.timestamp is None:
            self.timestamp = datetime.now()


@dataclass
class CodingTestSuite:
    """Represents a collection of test results."""
    name: str
    results: List[CodingTestResult]
    total_duration: float
    started_at: datetime
    completed_at: Optional[datetime] = None
    
    @property
    def passed_count(self) -> int:
        return len([r for r in self.results if r.status == "passed"])
    
    @property
    def failed_count(self) -> int:
        return len([r for r in self.results if r.status == "failed"])
    
    @property
    def skipped_count(self) -> int:
        return len([r for r in self.results if r.status == "skipped"])
    
    @property
    def error_count(self) -> int:
        return len([r for r in self.results if r.status == "error"])
    
    @property
    def total_count(self) -> int:
        return len(self.results)
    
    @property
    def success_rate(self) -> float:
        if self.total_count == 0:
            return 0.0
        return (self.passed_count / self.total_count) * 100.0
