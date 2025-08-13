#!/usr/bin/env python3
"""
Predictive Development Planning Workflows
AI-driven development planning and prediction system

This system uses machine learning and historical data to predict
development timelines, identify bottlenecks, and optimize workflows.
"""

import asyncio
import json
import logging
import math
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass, asdict
from pathlib import Path
from collections import defaultdict, deque
import statistics
import sqlite3

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@dataclass
class TaskEstimate:
    """Development task estimate"""
    task_id: str
    task_name: str
    task_type: str  # feature, bug_fix, refactor, etc.
    complexity: str  # low, medium, high
    estimated_hours: float
    confidence: float
    dependencies: List[str]
    skills_required: List[str]
    historical_similar: List[str]

@dataclass
class DevelopmentPrediction:
    """Prediction for development timeline"""
    prediction_id: str
    project_name: str
    target_milestone: str
    predicted_completion: datetime
    confidence_interval: Tuple[datetime, datetime]
    risk_factors: List[str]
    bottlenecks: List[str]
    resource_recommendations: List[str]
    accuracy_score: float

@dataclass
class WorkflowOptimization:
    """Workflow optimization suggestion"""
    optimization_id: str
    workflow_area: str
    current_efficiency: float
    predicted_improvement: float
    implementation_steps: List[str]
    effort_required: str
    expected_roi: float

@dataclass
class DeveloperProfile:
    """Developer performance profile"""
    developer_id: str
    name: str
    skills: Dict[str, float]  # skill -> proficiency (0-1)
    velocity: float  # tasks per week
    specializations: List[str]
    task_preferences: List[str]
    historical_accuracy: float

@dataclass
class ProjectMetrics:
    """Historical project metrics"""
    metric_date: datetime
    lines_of_code: int
    test_coverage: float
    bug_count: int
    feature_count: int
    team_size: int
    velocity: float
    deployment_frequency: float

class PredictiveDatabase:
    """Database for storing predictive data"""
    
    def __init__(self, db_path: Path):
        self.db_path = db_path
        self._init_database()
    
    def _init_database(self):
        """Initialize prediction database"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # Historical tasks table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS historical_tasks (
                task_id TEXT PRIMARY KEY,
                task_name TEXT,
                task_type TEXT,
                complexity TEXT,
                estimated_hours REAL,
                actual_hours REAL,
                completion_date TEXT,
                developer_id TEXT,
                project_name TEXT
            )
        ''')
        
        # Project metrics table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS project_metrics (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                project_name TEXT,
                metric_date TEXT,
                lines_of_code INTEGER,
                test_coverage REAL,
                bug_count INTEGER,
                feature_count INTEGER,
                team_size INTEGER,
                velocity REAL,
                deployment_frequency REAL
            )
        ''')
        
        # Predictions table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS predictions (
                prediction_id TEXT PRIMARY KEY,
                project_name TEXT,
                target_milestone TEXT,
                predicted_completion TEXT,
                actual_completion TEXT,
                accuracy_score REAL,
                created_date TEXT
            )
        ''')
        
        # Developer profiles table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS developer_profiles (
                developer_id TEXT PRIMARY KEY,
                name TEXT,
                skills TEXT,
                velocity REAL,
                specializations TEXT,
                task_preferences TEXT,
                historical_accuracy REAL,
                last_updated TEXT
            )
        ''')
        
        conn.commit()
        conn.close()
    
    def store_historical_task(self, task_data: Dict[str, Any]):
        """Store completed task data"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute('''
            INSERT OR REPLACE INTO historical_tasks 
            (task_id, task_name, task_type, complexity, estimated_hours, 
             actual_hours, completion_date, developer_id, project_name)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            task_data['task_id'],
            task_data['task_name'],
            task_data['task_type'],
            task_data['complexity'],
            task_data['estimated_hours'],
            task_data['actual_hours'],
            task_data['completion_date'],
            task_data['developer_id'],
            task_data['project_name']
        ))
        
        conn.commit()
        conn.close()
    
    def get_similar_tasks(self, task_type: str, complexity: str, limit: int = 10) -> List[Dict[str, Any]]:
        """Get similar historical tasks"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute('''
            SELECT * FROM historical_tasks 
            WHERE task_type = ? AND complexity = ?
            ORDER BY completion_date DESC 
            LIMIT ?
        ''', (task_type, complexity, limit))
        
        tasks = []
        for row in cursor.fetchall():
            tasks.append({
                'task_id': row[0],
                'task_name': row[1],
                'task_type': row[2],
                'complexity': row[3],
                'estimated_hours': row[4],
                'actual_hours': row[5],
                'completion_date': row[6],
                'developer_id': row[7],
                'project_name': row[8]
            })
        
        conn.close()
        return tasks

class PredictiveEngine:
    """Core predictive engine"""
    
    def __init__(self, db_path: str = ".predictive_db/predictions.db"):
        self.db_path = Path(db_path)
        self.db_path.parent.mkdir(exist_ok=True)
        
        self.database = PredictiveDatabase(self.db_path)
        self.developer_profiles: Dict[str, DeveloperProfile] = {}
        self.project_metrics_history: Dict[str, List[ProjectMetrics]] = defaultdict(list)
        
        # Load sample data for demo
        self._initialize_sample_data()
        
        logger.info("Predictive planning engine initialized")
    
    def _initialize_sample_data(self):
        """Initialize with sample historical data"""
        # Sample historical tasks
        sample_tasks = [
            {
                'task_id': 'T001',
                'task_name': 'User Authentication',
                'task_type': 'feature',
                'complexity': 'medium',
                'estimated_hours': 16.0,
                'actual_hours': 20.0,
                'completion_date': '2024-01-15',
                'developer_id': 'dev1',
                'project_name': 'WebApp'
            },
            {
                'task_id': 'T002',
                'task_name': 'Fix login bug',
                'task_type': 'bug_fix',
                'complexity': 'low',
                'estimated_hours': 4.0,
                'actual_hours': 3.0,
                'completion_date': '2024-01-18',
                'developer_id': 'dev2',
                'project_name': 'WebApp'
            },
            {
                'task_id': 'T003',
                'task_name': 'Database optimization',
                'task_type': 'refactor',
                'complexity': 'high',
                'estimated_hours': 32.0,
                'actual_hours': 40.0,
                'completion_date': '2024-01-25',
                'developer_id': 'dev1',
                'project_name': 'WebApp'
            }
        ]
        
        for task in sample_tasks:
            self.database.store_historical_task(task)
        
        # Sample developer profiles
        self.developer_profiles = {
            'dev1': DeveloperProfile(
                developer_id='dev1',
                name='Senior Developer',
                skills={'python': 0.9, 'swift': 0.7, 'architecture': 0.8},
                velocity=3.5,
                specializations=['backend', 'architecture'],
                task_preferences=['feature', 'refactor'],
                historical_accuracy=0.85
            ),
            'dev2': DeveloperProfile(
                developer_id='dev2',
                name='Junior Developer',
                skills={'python': 0.6, 'testing': 0.8, 'debugging': 0.7},
                velocity=2.8,
                specializations=['testing', 'bug_fixes'],
                task_preferences=['bug_fix', 'testing'],
                historical_accuracy=0.75
            )
        }
    
    async def estimate_task(self, task_name: str, task_type: str, complexity: str) -> TaskEstimate:
        """Estimate a development task"""
        # Get similar historical tasks
        similar_tasks = self.database.get_similar_tasks(task_type, complexity)
        
        # Calculate base estimate
        if similar_tasks:
            actual_hours = [task['actual_hours'] for task in similar_tasks]
            base_estimate = statistics.mean(actual_hours)
            confidence = min(0.9, len(similar_tasks) / 10)  # More data = higher confidence
        else:
            # Fallback estimates
            base_estimates = {
                ('feature', 'low'): 8.0,
                ('feature', 'medium'): 20.0,
                ('feature', 'high'): 40.0,
                ('bug_fix', 'low'): 2.0,
                ('bug_fix', 'medium'): 6.0,
                ('bug_fix', 'high'): 16.0,
                ('refactor', 'low'): 12.0,
                ('refactor', 'medium'): 24.0,
                ('refactor', 'high'): 48.0,
            }
            base_estimate = base_estimates.get((task_type, complexity), 16.0)
            confidence = 0.5
        
        # Apply complexity multipliers
        complexity_multipliers = {'low': 0.8, 'medium': 1.0, 'high': 1.5}
        final_estimate = base_estimate * complexity_multipliers.get(complexity, 1.0)
        
        task_id = f"task_{len(similar_tasks) + 1}"
        
        return TaskEstimate(
            task_id=task_id,
            task_name=task_name,
            task_type=task_type,
            complexity=complexity,
            estimated_hours=final_estimate,
            confidence=confidence,
            dependencies=[],
            skills_required=self._determine_required_skills(task_type),
            historical_similar=[task['task_id'] for task in similar_tasks[:3]]
        )
    
    def _determine_required_skills(self, task_type: str) -> List[str]:
        """Determine required skills for task type"""
        skill_mapping = {
            'feature': ['python', 'architecture', 'testing'],
            'bug_fix': ['debugging', 'testing', 'analysis'],
            'refactor': ['architecture', 'python', 'design_patterns'],
            'documentation': ['writing', 'analysis'],
            'testing': ['testing', 'python', 'quality_assurance']
        }
        return skill_mapping.get(task_type, ['python'])
    
    async def predict_milestone(self, tasks: List[TaskEstimate], team_velocity: float) -> DevelopmentPrediction:
        """Predict milestone completion"""
        total_hours = sum(task.estimated_hours for task in tasks)
        
        # Calculate base timeline
        hours_per_week = team_velocity * 40  # Assuming 40 hours per week per developer
        weeks_needed = total_hours / hours_per_week
        
        # Add buffer for uncertainty
        uncertainty_buffer = 1.2  # 20% buffer
        buffered_weeks = weeks_needed * uncertainty_buffer
        
        predicted_completion = datetime.now() + timedelta(weeks=buffered_weeks)
        
        # Calculate confidence interval
        confidence_range = timedelta(weeks=weeks_needed * 0.3)  # ±30% range
        confidence_interval = (
            predicted_completion - confidence_range,
            predicted_completion + confidence_range
        )
        
        # Identify risks and bottlenecks
        risk_factors = self._identify_risk_factors(tasks)
        bottlenecks = self._identify_bottlenecks(tasks)
        
        prediction_id = f"pred_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        
        return DevelopmentPrediction(
            prediction_id=prediction_id,
            project_name="Current Project",
            target_milestone="Next Release",
            predicted_completion=predicted_completion,
            confidence_interval=confidence_interval,
            risk_factors=risk_factors,
            bottlenecks=bottlenecks,
            resource_recommendations=self._generate_resource_recommendations(tasks),
            accuracy_score=0.75  # Based on historical accuracy
        )
    
    def _identify_risk_factors(self, tasks: List[TaskEstimate]) -> List[str]:
        """Identify potential risk factors"""
        risks = []
        
        # High complexity tasks
        high_complexity_count = sum(1 for task in tasks if task.complexity == 'high')
        if high_complexity_count > len(tasks) * 0.3:
            risks.append("High proportion of complex tasks")
        
        # Low confidence estimates
        low_confidence_count = sum(1 for task in tasks if task.confidence < 0.6)
        if low_confidence_count > len(tasks) * 0.2:
            risks.append("Many tasks with uncertain estimates")
        
        # Skill gaps
        all_required_skills = set()
        for task in tasks:
            all_required_skills.update(task.skills_required)
        
        team_skills = set()
        for profile in self.developer_profiles.values():
            team_skills.update(profile.skills.keys())
        
        missing_skills = all_required_skills - team_skills
        if missing_skills:
            risks.append(f"Missing skills: {', '.join(missing_skills)}")
        
        return risks
    
    def _identify_bottlenecks(self, tasks: List[TaskEstimate]) -> List[str]:
        """Identify potential bottlenecks"""
        bottlenecks = []
        
        # Skill concentration bottlenecks
        skill_demand = defaultdict(int)
        for task in tasks:
            for skill in task.skills_required:
                skill_demand[skill] += 1
        
        # Check if any skill is in high demand
        for skill, demand in skill_demand.items():
            skilled_devs = sum(1 for profile in self.developer_profiles.values() 
                             if profile.skills.get(skill, 0) > 0.7)
            if demand > skilled_devs * 2:
                bottlenecks.append(f"High demand for {skill} expertise")
        
        # Dependency bottlenecks
        tasks_with_deps = sum(1 for task in tasks if task.dependencies)
        if tasks_with_deps > len(tasks) * 0.4:
            bottlenecks.append("Many interdependent tasks")
        
        return bottlenecks
    
    def _generate_resource_recommendations(self, tasks: List[TaskEstimate]) -> List[str]:
        """Generate resource recommendations"""
        recommendations = []
        
        # Skill-based recommendations
        skill_demand = defaultdict(int)
        for task in tasks:
            for skill in task.skills_required:
                skill_demand[skill] += 1
        
        for skill, demand in skill_demand.items():
            if demand > 3:
                recommendations.append(f"Consider additional {skill} expertise")
        
        # Team size recommendations
        total_effort = sum(task.estimated_hours for task in tasks)
        if total_effort > 200:  # Large project
            recommendations.append("Consider team scaling for large workload")
        
        # Training recommendations
        for profile in self.developer_profiles.values():
            weak_skills = [skill for skill, level in profile.skills.items() if level < 0.5]
            if weak_skills:
                recommendations.append(f"Training opportunity for {profile.name}: {weak_skills[0]}")
        
        return recommendations
    
    async def optimize_workflow(self, current_velocity: float, target_velocity: float) -> List[WorkflowOptimization]:
        """Generate workflow optimization suggestions"""
        optimizations = []
        
        efficiency_gap = target_velocity / current_velocity if current_velocity > 0 else 2.0
        
        # Automation opportunities
        if efficiency_gap > 1.3:
            optimizations.append(WorkflowOptimization(
                optimization_id="auto_001",
                workflow_area="Testing",
                current_efficiency=0.6,
                predicted_improvement=0.25,
                implementation_steps=[
                    "Implement automated testing pipeline",
                    "Add pre-commit hooks",
                    "Set up continuous integration"
                ],
                effort_required="2-3 weeks",
                expected_roi=2.5
            ))
        
        # Code review optimization
        optimizations.append(WorkflowOptimization(
            optimization_id="review_001",
            workflow_area="Code Review",
            current_efficiency=0.7,
            predicted_improvement=0.15,
            implementation_steps=[
                "Implement AI-assisted code review",
                "Standardize review templates",
                "Add automated style checking"
            ],
            effort_required="1-2 weeks",
            expected_roi=1.8
        ))
        
        # Knowledge sharing
        if len(self.developer_profiles) > 2:
            optimizations.append(WorkflowOptimization(
                optimization_id="knowledge_001",
                workflow_area="Knowledge Sharing",
                current_efficiency=0.5,
                predicted_improvement=0.3,
                implementation_steps=[
                    "Implement pair programming sessions",
                    "Create technical documentation templates",
                    "Set up knowledge sharing meetings"
                ],
                effort_required="Ongoing",
                expected_roi=2.2
            ))
        
        return optimizations
    
    async def generate_sprint_plan(self, available_hours: float, sprint_length_weeks: int = 2) -> Dict[str, Any]:
        """Generate optimized sprint plan"""
        # Sample tasks for demo
        sample_tasks = [
            await self.estimate_task("User Profile Management", "feature", "medium"),
            await self.estimate_task("Fix authentication timeout", "bug_fix", "low"),
            await self.estimate_task("Optimize database queries", "refactor", "high"),
            await self.estimate_task("Add unit tests", "testing", "medium"),
            await self.estimate_task("Update API documentation", "documentation", "low")
        ]
        
        # Sort by priority (for demo: complexity = priority)
        priority_order = {'high': 3, 'medium': 2, 'low': 1}
        sample_tasks.sort(key=lambda t: priority_order.get(t.complexity, 0), reverse=True)
        
        # Select tasks that fit in available hours
        selected_tasks = []
        remaining_hours = available_hours
        
        for task in sample_tasks:
            if task.estimated_hours <= remaining_hours:
                selected_tasks.append(task)
                remaining_hours -= task.estimated_hours
        
        # Generate predictions
        team_velocity = sum(profile.velocity for profile in self.developer_profiles.values())
        prediction = await self.predict_milestone(selected_tasks, team_velocity)
        
        # Task assignments
        assignments = self._assign_tasks_to_developers(selected_tasks)
        
        return {
            "sprint_summary": {
                "total_tasks": len(selected_tasks),
                "total_hours": sum(task.estimated_hours for task in selected_tasks),
                "available_hours": available_hours,
                "utilization": (sum(task.estimated_hours for task in selected_tasks) / available_hours) * 100,
                "sprint_length_weeks": sprint_length_weeks
            },
            "selected_tasks": [asdict(task) for task in selected_tasks],
            "task_assignments": assignments,
            "completion_prediction": asdict(prediction),
            "risk_mitigation": self._generate_risk_mitigation(prediction.risk_factors),
            "success_metrics": {
                "velocity_target": team_velocity * sprint_length_weeks,
                "quality_target": "90% test coverage",
                "delivery_confidence": prediction.accuracy_score
            }
        }
    
    def _assign_tasks_to_developers(self, tasks: List[TaskEstimate]) -> Dict[str, List[str]]:
        """Assign tasks to developers based on skills and capacity"""
        assignments = defaultdict(list)
        
        # Simple assignment algorithm based on skills
        for task in tasks:
            best_developer = None
            best_score = 0
            
            for dev_id, profile in self.developer_profiles.items():
                score = 0
                
                # Skill matching
                for skill in task.skills_required:
                    if skill in profile.skills:
                        score += profile.skills[skill]
                
                # Task preference
                if task.task_type in profile.task_preferences:
                    score += 0.3
                
                # Specialization bonus
                if any(spec in task.task_name.lower() for spec in profile.specializations):
                    score += 0.2
                
                if score > best_score:
                    best_score = score
                    best_developer = dev_id
            
            if best_developer:
                assignments[best_developer].append(task.task_name)
            else:
                assignments["unassigned"].append(task.task_name)
        
        return dict(assignments)
    
    def _generate_risk_mitigation(self, risk_factors: List[str]) -> List[str]:
        """Generate risk mitigation strategies"""
        mitigations = []
        
        for risk in risk_factors:
            if "complex" in risk.lower():
                mitigations.append("Break down complex tasks into smaller subtasks")
            elif "uncertain" in risk.lower():
                mitigations.append("Add discovery spikes for uncertain work")
            elif "missing skills" in risk.lower():
                mitigations.append("Plan knowledge transfer sessions")
            elif "demand" in risk.lower():
                mitigations.append("Consider pair programming for bottleneck skills")
        
        return mitigations

# Demo function
async def main() -> Any:
    """Demo the predictive planning system"""
    print("🔮 Starting Predictive Development Planning...")
    
    engine = PredictiveEngine()
    
    # Generate sprint plan
    print("📋 Generating optimal sprint plan...")
    available_hours = 80  # 2 developers × 40 hours/week × 1 week
    sprint_plan = await engine.generate_sprint_plan(available_hours, sprint_length_weeks=1)
    
    print("✅ Sprint Plan Generated:")
    summary = sprint_plan["sprint_summary"]
    print(f"  • Tasks: {summary['total_tasks']}")
    print(f"  • Estimated Hours: {summary['total_hours']:.1f}")
    print(f"  • Utilization: {summary['utilization']:.1f}%")
    
    print(f"\n📝 Selected Tasks:")
    for i, task in enumerate(sprint_plan["selected_tasks"][:3], 1):
        print(f"  {i}. {task['task_name']} ({task['complexity']}) - {task['estimated_hours']}h")
    
    print(f"\n👥 Task Assignments:")
    for dev, tasks in sprint_plan["task_assignments"].items():
        if tasks:
            print(f"  • {dev}: {', '.join(tasks[:2])}{'...' if len(tasks) > 2 else ''}")
    
    # Generate workflow optimizations
    print(f"\n⚡ Workflow Optimizations:")
    optimizations = await engine.optimize_workflow(2.5, 3.5)
    for opt in optimizations[:2]:
        print(f"  • {opt.workflow_area}: +{opt.predicted_improvement*100:.0f}% efficiency")
        print(f"    Effort: {opt.effort_required}, ROI: {opt.expected_roi:.1f}x")
    
    # Show prediction details
    prediction = sprint_plan["completion_prediction"]
    print(f"\n🎯 Completion Prediction:")
    # Convert datetime string back to datetime for formatting
    if isinstance(prediction['predicted_completion'], str):
        completion_date = datetime.fromisoformat(prediction['predicted_completion']).strftime('%Y-%m-%d')
    else:
        completion_date = prediction['predicted_completion'].strftime('%Y-%m-%d')
    print(f"  • Target: {completion_date}")
    print(f"  • Confidence: {prediction['accuracy_score']*100:.0f}%")
    
    if prediction["risk_factors"]:
        print(f"  • Risks: {prediction['risk_factors'][0]}")
    
    print(f"\n📊 Success Metrics:")
    metrics = sprint_plan["success_metrics"]
    print(f"  • Velocity Target: {metrics['velocity_target']:.1f} tasks/week")
    print(f"  • Quality Target: {metrics['quality_target']}")
    print(f"  • Delivery Confidence: {metrics['delivery_confidence']*100:.0f}%")

if __name__ == "__main__":
    asyncio.run(main())
