"""
CodingReviewer Testing Framework - Visualization

Handles test result visualization and dashboard creation.
Specialized module for creating charts and visual reports.
"""

from typing import Dict, Any

import plotly.graph_objects as go
from plotly.subplots import make_subplots


class TestVisualization:
    """Creates visual representations of test results."""
    
    @staticmethod
    def create_test_dashboard(report: Dict[str, Any]) -> go.Figure:  # type: ignore
        """Create a comprehensive dashboard for test results."""
        
        # Create subplots
        fig = make_subplots(  # type: ignore  # plotly typing
            rows=2, cols=2,
            subplot_titles=("Success Rate by Suite", "Test Duration", "Status Distribution", "Timeline"),
            specs=[[{"type": "bar"}, {"type": "bar"}],
                   [{"type": "pie"}, {"type": "scatter"}]]
        )
        
        # Extract data from report
        suites = report.get("suites", [])
        summary = report.get("summary", {})
        
        if not suites:
            # Create empty dashboard if no data
            fig.add_annotation(  # type: ignore  # plotly typing
                text="No test data available",
                xref="paper", yref="paper",
                x=0.5, y=0.5, showarrow=False
            )
            return fig
        
        # 1. Success Rate by Suite (Bar Chart)
        suite_names = [suite["name"] for suite in suites]
        success_rates = [suite["success_rate"] for suite in suites]
        
        fig.add_trace(  # type: ignore  # plotly typing
            go.Bar(name="Success Rate", x=suite_names, y=success_rates,
                   marker_color='green'),
            row=1, col=1
        )
        
        # 2. Test Duration (Bar Chart)
        durations = [suite["duration"] for suite in suites]
        
        fig.add_trace(  # type: ignore  # plotly typing
            go.Bar(name="Duration (s)", x=suite_names, y=durations,
                   marker_color='blue'),
            row=1, col=2
        )
        
        # 3. Overall Status Distribution (Pie Chart)
        labels = ['Passed', 'Failed', 'Skipped', 'Errors']
        values = [
            summary.get("total_passed", 0),
            summary.get("total_failed", 0),
            summary.get("total_skipped", 0),
            summary.get("total_errors", 0)
        ]
        colors = ['green', 'red', 'orange', 'purple']
        
        fig.add_trace(  # type: ignore  # plotly typing
            go.Pie(labels=labels, values=values, marker=dict(colors=colors)),
            row=2, col=1
        )
        
        # 4. Timeline (Scatter Plot)
        # Simple timeline showing test execution order
        suite_indices = list(range(len(suite_names)))
        fig.add_trace(  # type: ignore  # plotly typing
            go.Scatter(x=suite_indices, y=success_rates, mode='lines+markers',
                      name='Success Rate Timeline', line=dict(color='green')),
            row=2, col=2
        )
        
        # Update layout
        fig.update_layout(  # type: ignore  # plotly typing
            title="CodingReviewer Test Results Dashboard",
            height=700,
            showlegend=True
        )
        
        # Update axes labels
        fig.update_xaxes(title_text="Test Suite", row=1, col=1)  # type: ignore  # plotly typing
        fig.update_yaxes(title_text="Success Rate (%)", row=1, col=1)  # type: ignore  # plotly typing
        
        fig.update_xaxes(title_text="Test Suite", row=1, col=2)  # type: ignore  # plotly typing
        fig.update_yaxes(title_text="Duration (seconds)", row=1, col=2)  # type: ignore  # plotly typing
        
        fig.update_xaxes(title_text="Execution Order", row=2, col=2)  # type: ignore  # plotly typing
        fig.update_yaxes(title_text="Success Rate (%)", row=2, col=2)  # type: ignore  # plotly typing
        
        return fig
    
    @staticmethod
    def create_simple_bar_chart(suite_data: Dict[str, Any]) -> go.Figure:  # type: ignore
        """Create a simple bar chart for a single test suite."""
        
        categories = ['Passed', 'Failed', 'Skipped', 'Errors']
        values = [
            suite_data.get("passed_count", 0),
            suite_data.get("failed_count", 0),
            suite_data.get("skipped_count", 0),
            suite_data.get("error_count", 0)
        ]
        colors = ['green', 'red', 'orange', 'purple']
        
        fig = go.Figure(data=[  # type: ignore  # plotly typing
            go.Bar(x=categories, y=values, marker_color=colors)
        ])
        
        fig.update_layout(  # type: ignore  # plotly typing
            title=f"Test Results: {suite_data.get('name', 'Unknown')}",
            xaxis_title="Test Status",
            yaxis_title="Count"
        )
        
        return fig
    
    @staticmethod
    def save_dashboard(fig: go.Figure, filepath: str) -> None:  # type: ignore
        """Save dashboard to HTML file."""
        fig.write_html(filepath)  # type: ignore  # plotly typing
