#!/usr/bin/env python3
"""
Cross-Project Learning and Optimization System
Knowledge sharing and pattern recognition across multiple projects

This system enables learning from multiple codebases to improve
recommendations, share best practices, and optimize development patterns.
"""

import asyncio
import json
import logging
import hashlib
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any, Set, Tuple
from dataclasses import dataclass, asdict
from pathlib import Path
from collections import defaultdict, Counter
import sqlite3
import statistics

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@dataclass
class ProjectProfile:
    """Profile of a project for cross-learning"""
    project_id: str
    project_name: str
    project_path: str
    language_mix: Dict[str, float]  # language -> percentage
    project_type: str  # web, mobile, library, etc.
    team_size: int
    creation_date: datetime
    last_analysis: datetime
    metrics: Dict[str, float]

@dataclass
class Pattern:
    """Learned pattern from project analysis"""
    pattern_id: str
    pattern_type: str
    pattern_name: str
    description: str
    context: Dict[str, Any]
    success_metrics: Dict[str, float]
    applicability_score: float
    projects_using: List[str]
    effectiveness_rating: float

@dataclass
class BestPractice:
    """Best practice derived from cross-project analysis"""
    practice_id: str
    practice_name: str
    description: str
    implementation_guide: str
    benefits: List[str]
    prerequisites: List[str]
    applicable_project_types: List[str]
    success_stories: List[str]
    confidence_score: float

@dataclass
class OptimizationRecommendation:
    """Optimization recommendation based on cross-project learning"""
    recommendation_id: str
    target_project: str
    optimization_type: str
    title: str
    description: str
    implementation_steps: List[str]
    expected_benefits: Dict[str, float]
    effort_estimate: str
    confidence: float
    similar_implementations: List[str]

class ProjectKnowledgeBase:
    """Central knowledge base for cross-project learning"""
    
    def __init__(self, kb_path: Path):
        self.kb_path = kb_path
        self.kb_path.mkdir(exist_ok=True)
        self.db_path = self.kb_path / "knowledge_base.db"
        self._init_database()
    
    def _init_database(self):
        """Initialize knowledge base database"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # Projects table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS projects (
                project_id TEXT PRIMARY KEY,
                project_name TEXT NOT NULL,
                project_path TEXT NOT NULL,
                language_mix TEXT,
                project_type TEXT,
                team_size INTEGER,
                creation_date TEXT,
                last_analysis TEXT,
                metrics TEXT
            )
        ''')
        
        # Patterns table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS patterns (
                pattern_id TEXT PRIMARY KEY,
                pattern_type TEXT NOT NULL,
                pattern_name TEXT NOT NULL,
                description TEXT,
                context TEXT,
                success_metrics TEXT,
                applicability_score REAL,
                projects_using TEXT,
                effectiveness_rating REAL,
                created_date TEXT
            )
        ''')
        
        # Best practices table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS best_practices (
                practice_id TEXT PRIMARY KEY,
                practice_name TEXT NOT NULL,
                description TEXT,
                implementation_guide TEXT,
                benefits TEXT,
                prerequisites TEXT,
                applicable_project_types TEXT,
                success_stories TEXT,
                confidence_score REAL,
                created_date TEXT
            )
        ''')
        
        # Learning history table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS learning_history (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                event_type TEXT NOT NULL,
                project_id TEXT,
                data TEXT,
                timestamp TEXT
            )
        ''')
        
        conn.commit()
        conn.close()
    
    def store_project_profile(self, profile: ProjectProfile):
        """Store project profile"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute('''
            INSERT OR REPLACE INTO projects 
            (project_id, project_name, project_path, language_mix, project_type, 
             team_size, creation_date, last_analysis, metrics)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            profile.project_id,
            profile.project_name,
            profile.project_path,
            json.dumps(profile.language_mix),
            profile.project_type,
            profile.team_size,
            profile.creation_date.isoformat(),
            profile.last_analysis.isoformat(),
            json.dumps(profile.metrics)
        ))
        
        conn.commit()
        conn.close()
    
    def get_similar_projects(self, target_profile: ProjectProfile, limit: int = 5) -> List[ProjectProfile]:
        """Find similar projects for learning"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute('SELECT * FROM projects WHERE project_id != ?', (target_profile.project_id,))
        
        projects = []
        for row in cursor.fetchall():
            projects.append(ProjectProfile(
                project_id=row[0],
                project_name=row[1],
                project_path=row[2],
                language_mix=json.loads(row[3]),
                project_type=row[4],
                team_size=row[5],
                creation_date=datetime.fromisoformat(row[6]),
                last_analysis=datetime.fromisoformat(row[7]),
                metrics=json.loads(row[8])
            ))
        
        conn.close()
        
        # Calculate similarity scores and sort
        scored_projects = []
        for project in projects:
            similarity = self._calculate_similarity(target_profile, project)
            scored_projects.append((similarity, project))
        
        # Return top similar projects
        scored_projects.sort(reverse=True)
        return [project for _, project in scored_projects[:limit]]
    
    def _calculate_similarity(self, project1: ProjectProfile, project2: ProjectProfile) -> float:
        """Calculate similarity between two projects"""
        score = 0.0
        
        # Project type similarity (30%)
        if project1.project_type == project2.project_type:
            score += 0.3
        
        # Language similarity (40%)
        lang_sim = self._calculate_language_similarity(project1.language_mix, project2.language_mix)
        score += 0.4 * lang_sim
        
        # Team size similarity (10%)
        team_diff = abs(project1.team_size - project2.team_size)
        team_sim = max(0, 1 - team_diff / 10)  # Normalize to 0-1
        score += 0.1 * team_sim
        
        # Metrics similarity (20%)
        metrics_sim = self._calculate_metrics_similarity(project1.metrics, project2.metrics)
        score += 0.2 * metrics_sim
        
        return score
    
    def _calculate_language_similarity(self, lang1: Dict[str, float], lang2: Dict[str, float]) -> float:
        """Calculate language mix similarity"""
        all_languages = set(lang1.keys()) | set(lang2.keys())
        if not all_languages:
            return 1.0
        
        similarity = 0.0
        for lang in all_languages:
            pct1 = lang1.get(lang, 0.0)
            pct2 = lang2.get(lang, 0.0)
            similarity += 1 - abs(pct1 - pct2)
        
        return similarity / len(all_languages)
    
    def _calculate_metrics_similarity(self, metrics1: Dict[str, float], metrics2: Dict[str, float]) -> float:
        """Calculate metrics similarity"""
        common_metrics = set(metrics1.keys()) & set(metrics2.keys())
        if not common_metrics:
            return 0.0
        
        similarities = []
        for metric in common_metrics:
            val1, val2 = metrics1[metric], metrics2[metric]
            if val1 == 0 and val2 == 0:
                similarities.append(1.0)
            else:
                max_val = max(val1, val2)
                if max_val > 0:
                    similarities.append(1 - abs(val1 - val2) / max_val)
                else:
                    similarities.append(1.0)
        
        return statistics.mean(similarities) if similarities else 0.0

class CrossProjectLearner:
    """Main cross-project learning system"""
    
    def __init__(self, knowledge_base_dir: str = ".cross_project_kb"):
        self.kb_dir = Path(knowledge_base_dir)
        self.kb_dir.mkdir(exist_ok=True)
        
        self.knowledge_base = ProjectKnowledgeBase(self.kb_dir)
        self.patterns: Dict[str, Pattern] = {}
        self.best_practices: Dict[str, BestPractice] = {}
        
        logger.info("Cross-project learning system initialized")
    
    async def analyze_project(self, project_path: str, project_name: str) -> ProjectProfile:
        """Analyze a project and create its profile"""
        project_id = hashlib.md5(project_path.encode()).hexdigest()
        path = Path(project_path)
        
        # Analyze language composition
        language_mix = await self._analyze_language_mix(path)
        
        # Determine project type
        project_type = await self._determine_project_type(path)
        
        # Estimate team size (heuristic based on git if available)
        team_size = await self._estimate_team_size(path)
        
        # Collect metrics
        metrics = await self._collect_project_metrics(path)
        
        profile = ProjectProfile(
            project_id=project_id,
            project_name=project_name,
            project_path=project_path,
            language_mix=language_mix,
            project_type=project_type,
            team_size=team_size,
            creation_date=datetime.now(),
            last_analysis=datetime.now(),
            metrics=metrics
        )
        
        # Store in knowledge base
        self.knowledge_base.store_project_profile(profile)
        
        return profile
    
    async def learn_from_project(self, project_path: str) -> List[Pattern]:
        """Learn patterns from a project"""
        logger.info(f"Learning patterns from {project_path}")
        
        patterns = []
        path = Path(project_path)
        
        # Learn architectural patterns
        arch_patterns = await self._learn_architectural_patterns(path)
        patterns.extend(arch_patterns)
        
        # Learn coding patterns
        code_patterns = await self._learn_coding_patterns(path)
        patterns.extend(code_patterns)
        
        # Learn workflow patterns
        workflow_patterns = await self._learn_workflow_patterns(path)
        patterns.extend(workflow_patterns)
        
        # Store patterns
        for pattern in patterns:
            self.patterns[pattern.pattern_id] = pattern
        
        return patterns
    
    async def generate_recommendations(self, target_project: str) -> List[OptimizationRecommendation]:
        """Generate optimization recommendations for a target project"""
        logger.info(f"Generating recommendations for {target_project}")
        
        # Get target project profile
        target_profile = await self.analyze_project(target_project, Path(target_project).name)
        
        # Find similar projects
        similar_projects = self.knowledge_base.get_similar_projects(target_profile)
        
        recommendations = []
        
        # Generate architecture recommendations
        arch_recs = await self._generate_architecture_recommendations(
            target_profile, similar_projects
        )
        recommendations.extend(arch_recs)
        
        # Generate performance recommendations
        perf_recs = await self._generate_performance_recommendations(
            target_profile, similar_projects
        )
        recommendations.extend(perf_recs)
        
        # Generate workflow recommendations
        workflow_recs = await self._generate_workflow_recommendations(
            target_profile, similar_projects
        )
        recommendations.extend(workflow_recs)
        
        return recommendations
    
    async def _analyze_language_mix(self, path: Path) -> Dict[str, float]:
        """Analyze language composition"""
        file_counts = defaultdict(int)
        total_files = 0
        
        extensions = {
            '.py': 'Python',
            '.swift': 'Swift',
            '.js': 'JavaScript',
            '.ts': 'TypeScript',
            '.java': 'Java',
            '.cpp': 'C++',
            '.c': 'C',
            '.go': 'Go',
            '.rs': 'Rust',
            '.rb': 'Ruby'
        }
        
        for ext, lang in extensions.items():
            files = list(path.glob(f"**/*{ext}"))
            count = len([f for f in files if not any(skip in str(f) for skip in ['.git', '__pycache__', 'node_modules'])])
            if count > 0:
                file_counts[lang] = count
                total_files += count
        
        if total_files == 0:
            return {}
        
        return {lang: count / total_files for lang, count in file_counts.items()}
    
    async def _determine_project_type(self, path: Path) -> str:
        """Determine project type based on structure"""
        # Check for common project indicators
        if (path / "package.json").exists():
            return "web_frontend"
        elif (path / "requirements.txt").exists() or (path / "pyproject.toml").exists():
            if (path / "app").exists() or (path / "webapp").exists():
                return "web_backend"
            else:
                return "python_library"
        elif (path / "Cargo.toml").exists():
            return "rust_project"
        elif any(path.glob("*.xcodeproj")):
            return "ios_app"
        elif (path / "pom.xml").exists() or (path / "build.gradle").exists():
            return "java_project"
        else:
            return "unknown"
    
    async def _estimate_team_size(self, path: Path) -> int:
        """Estimate team size from git history"""
        try:
            import subprocess
            result = subprocess.run(
                ["git", "log", "--format=%ae", "--since=3 months ago"],
                cwd=path,
                capture_output=True,
                text=True
            )
            if result.returncode == 0:
                emails = set(result.stdout.strip().split('\n'))
                return len(emails) if emails and emails != {''} else 1
        except Exception as e:
            pass
        
        return 1  # Default to 1 if can't determine
    
    async def _collect_project_metrics(self, path: Path) -> Dict[str, float]:
        """Collect project metrics"""
        metrics = {}
        
        # File counts
        py_files = len(list(path.glob("**/*.py")))
        swift_files = len(list(path.glob("**/*.swift")))
        
        metrics["python_files"] = py_files
        metrics["swift_files"] = swift_files
        metrics["total_files"] = py_files + swift_files
        
        # Estimate lines of code
        loc = 0
        for file_path in path.glob("**/*.py"):
            try:
                loc += len(file_path.read_text().split('\n'))
            except Exception as e:
                continue
        
        metrics["lines_of_code"] = loc
        
        # Check for tests
        test_files = len(list(path.glob("**/test*.py"))) + len(list(path.glob("**/*test*.py")))
        metrics["test_files"] = test_files
        metrics["test_coverage_estimate"] = min(1.0, test_files / max(1, py_files)) * 100
        
        return metrics
    
    async def _learn_architectural_patterns(self, path: Path) -> List[Pattern]:
        """Learn architectural patterns"""
        patterns = []
        
        # MVC pattern detection
        has_models = bool(list(path.glob("**/models/**/*.py"))) or bool(list(path.glob("**/model*.py")))
        has_views = bool(list(path.glob("**/views/**/*.py"))) or bool(list(path.glob("**/view*.py")))
        has_controllers = bool(list(path.glob("**/controllers/**/*.py"))) or bool(list(path.glob("**/controller*.py")))
        
        if has_models and has_views and has_controllers:
            patterns.append(Pattern(
                pattern_id=f"mvc_{hashlib.md5(str(path).encode()).hexdigest()[:8]}",
                pattern_type="architecture",
                pattern_name="MVC Pattern",
                description="Model-View-Controller architectural pattern",
                context={"project_path": str(path)},
                success_metrics={"maintainability": 0.8, "testability": 0.7},
                applicability_score=0.9,
                projects_using=[str(path)],
                effectiveness_rating=0.8
            ))
        
        # Microservices pattern detection
        service_dirs = [d for d in path.iterdir() if d.is_dir() and "service" in d.name.lower()]
        if len(service_dirs) > 2:
            patterns.append(Pattern(
                pattern_id=f"microservices_{hashlib.md5(str(path).encode()).hexdigest()[:8]}",
                pattern_type="architecture",
                pattern_name="Microservices Pattern",
                description="Microservices architectural pattern",
                context={"project_path": str(path), "service_count": len(service_dirs)},
                success_metrics={"scalability": 0.9, "maintainability": 0.6},
                applicability_score=0.7,
                projects_using=[str(path)],
                effectiveness_rating=0.7
            ))
        
        return patterns
    
    async def _learn_coding_patterns(self, path: Path) -> List[Pattern]:
        """Learn coding patterns"""
        patterns = []
        
        # Dependency injection pattern
        di_usage = 0
        for py_file in path.glob("**/*.py"):
            try:
                content = py_file.read_text()
                if "inject" in content.lower() or "__init__" in content:
                    di_usage += 1
            except Exception as e:
                continue
        
        if di_usage > 3:
            patterns.append(Pattern(
                pattern_id=f"dependency_injection_{hashlib.md5(str(path).encode()).hexdigest()[:8]}",
                pattern_type="coding",
                pattern_name="Dependency Injection",
                description="Dependency injection pattern usage",
                context={"project_path": str(path), "usage_count": di_usage},
                success_metrics={"testability": 0.9, "maintainability": 0.8},
                applicability_score=0.8,
                projects_using=[str(path)],
                effectiveness_rating=0.8
            ))
        
        return patterns
    
    async def _learn_workflow_patterns(self, path: Path) -> List[Pattern]:
        """Learn workflow patterns"""
        patterns = []
        
        # CI/CD pattern detection
        has_github_actions = (path / ".github" / "workflows").exists()
        has_jenkins = (path / "Jenkinsfile").exists()
        has_travis = (path / ".travis.yml").exists()
        
        if has_github_actions or has_jenkins or has_travis:
            patterns.append(Pattern(
                pattern_id=f"cicd_{hashlib.md5(str(path).encode()).hexdigest()[:8]}",
                pattern_type="workflow",
                pattern_name="CI/CD Pipeline",
                description="Continuous integration and deployment",
                context={"project_path": str(path)},
                success_metrics={"deployment_frequency": 0.9, "lead_time": 0.8},
                applicability_score=0.95,
                projects_using=[str(path)],
                effectiveness_rating=0.9
            ))
        
        return patterns
    
    async def _generate_architecture_recommendations(self, target: ProjectProfile, similar: List[ProjectProfile]) -> List[OptimizationRecommendation]:
        """Generate architecture recommendations"""
        recommendations = []
        
        # Analyze successful patterns in similar projects
        if target.project_type == "web_backend" and target.metrics.get("lines_of_code", 0) > 5000:
            recommendations.append(OptimizationRecommendation(
                recommendation_id=f"arch_modular_{target.project_id}",
                target_project=target.project_path,
                optimization_type="architecture",
                title="Consider Modular Architecture",
                description="Break monolithic structure into modules for better maintainability",
                implementation_steps=[
                    "Identify functional boundaries",
                    "Extract modules with clear interfaces",
                    "Implement dependency injection",
                    "Create module tests"
                ],
                expected_benefits={"maintainability": 0.3, "testability": 0.25},
                effort_estimate="4-6 weeks",
                confidence=0.8,
                similar_implementations=[p.project_name for p in similar if "modular" in str(p.metrics)]
            ))
        
        return recommendations
    
    async def _generate_performance_recommendations(self, target: ProjectProfile, similar: List[ProjectProfile]) -> List[OptimizationRecommendation]:
        """Generate performance recommendations"""
        recommendations = []
        
        # Caching recommendations
        if target.project_type in ["web_backend", "web_frontend"]:
            recommendations.append(OptimizationRecommendation(
                recommendation_id=f"perf_caching_{target.project_id}",
                target_project=target.project_path,
                optimization_type="performance",
                title="Implement Caching Strategy",
                description="Add caching to improve response times and reduce load",
                implementation_steps=[
                    "Identify frequently accessed data",
                    "Choose caching strategy (Redis, in-memory, etc.)",
                    "Implement cache invalidation",
                    "Monitor cache hit rates"
                ],
                expected_benefits={"response_time": 0.5, "throughput": 0.3},
                effort_estimate="2-3 weeks",
                confidence=0.7,
                similar_implementations=[p.project_name for p in similar]
            ))
        
        return recommendations
    
    async def _generate_workflow_recommendations(self, target: ProjectProfile, similar: List[ProjectProfile]) -> List[OptimizationRecommendation]:
        """Generate workflow recommendations"""
        recommendations = []
        
        # Automated testing recommendations
        test_coverage = target.metrics.get("test_coverage_estimate", 0)
        if test_coverage < 50:
            recommendations.append(OptimizationRecommendation(
                recommendation_id=f"workflow_testing_{target.project_id}",
                target_project=target.project_path,
                optimization_type="workflow",
                title="Improve Test Coverage",
                description="Increase automated test coverage for better reliability",
                implementation_steps=[
                    "Audit current test coverage",
                    "Identify critical paths needing tests",
                    "Implement unit and integration tests",
                    "Set up coverage reporting",
                    "Establish coverage targets"
                ],
                expected_benefits={"reliability": 0.4, "development_velocity": 0.2},
                effort_estimate="3-4 weeks",
                confidence=0.9,
                similar_implementations=[p.project_name for p in similar if p.metrics.get("test_coverage_estimate", 0) > 70]
            ))
        
        return recommendations
    
    async def generate_learning_report(self) -> Dict[str, Any]:
        """Generate cross-project learning report"""
        report = {
            "timestamp": datetime.now().isoformat(),
            "projects_analyzed": len(self.patterns),
            "patterns_learned": len(self.patterns),
            "best_practices": len(self.best_practices),
            "pattern_distribution": self._analyze_pattern_distribution(),
            "top_patterns": self._get_top_patterns(),
            "effectiveness_insights": self._analyze_effectiveness(),
            "recommendations_summary": "Cross-project learning active"
        }
        
        return report
    
    def _analyze_pattern_distribution(self) -> Dict[str, int]:
        """Analyze distribution of patterns by type"""
        distribution = defaultdict(int)
        for pattern in self.patterns.values():
            distribution[pattern.pattern_type] += 1
        return dict(distribution)
    
    def _get_top_patterns(self) -> List[str]:
        """Get most effective patterns"""
        sorted_patterns = sorted(
            self.patterns.values(),
            key=lambda p: p.effectiveness_rating,
            reverse=True
        )
        return [p.pattern_name for p in sorted_patterns[:5]]
    
    def _analyze_effectiveness(self) -> Dict[str, float]:
        """Analyze pattern effectiveness"""
        if not self.patterns:
            return {}
        
        ratings = [p.effectiveness_rating for p in self.patterns.values()]
        return {
            "average_effectiveness": statistics.mean(ratings),
            "max_effectiveness": max(ratings),
            "pattern_count": len(ratings)
        }

# Demo function
async def main():
    """Demo the cross-project learning system"""
    print("🌐 Starting Cross-Project Learning and Optimization...")
    
    learner = CrossProjectLearner()
    
    # Analyze current project
    print("📊 Analyzing current project...")
    profile = await learner.analyze_project(".", "CodingReviewer")
    
    print(f"✅ Project Profile Created:")
    print(f"  • Type: {profile.project_type}")
    print(f"  • Languages: {profile.language_mix}")
    print(f"  • Team Size: {profile.team_size}")
    
    # Learn patterns
    print("\n🧠 Learning patterns from project...")
    patterns = await learner.learn_from_project(".")
    
    print(f"✅ Learned {len(patterns)} patterns:")
    for pattern in patterns[:3]:
        print(f"  • {pattern.pattern_name}: {pattern.description}")
    
    # Generate recommendations
    print("\n💡 Generating optimization recommendations...")
    recommendations = await learner.generate_recommendations(".")
    
    print(f"✅ Generated {len(recommendations)} recommendations:")
    for rec in recommendations[:3]:
        print(f"  • {rec.title}")
        print(f"    Benefits: {rec.expected_benefits}")
        print(f"    Effort: {rec.effort_estimate}")
    
    # Generate learning report
    print("\n📈 Generating learning report...")
    report = await learner.generate_learning_report()
    
    print(f"✅ Learning Report:")
    print(f"  • Patterns Learned: {report['patterns_learned']}")
    print(f"  • Top Patterns: {report['top_patterns']}")
    print(f"  • Average Effectiveness: {report['effectiveness_insights'].get('average_effectiveness', 0):.2f}")

if __name__ == "__main__":
    asyncio.run(main())