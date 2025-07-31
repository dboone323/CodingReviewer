import Foundation

// MARK: - Sample Swift Code
let sampleSwiftCode = """
import Foundation
import UIKit

class UserManager: ObservableObject {
    @Published var users: [User] = [];
    private let networkService = NetworkService()
    
    func fetchUsers() async {
        do {
            let fetchedUsers = try await networkService.getUsers()
            await MainActor.run {
                self.users = fetchedUsers
            }
        } catch {
            print("Error fetching users: \\(error)")
        }
    }
    
    func addUser(_ user: User) {
        users.append(user)
    }
    
    func removeUser(withId id: String) {
        users.removeAll { $0.id == id }
    }
}

struct User: Codable, Identifiable {
    let id: String
    let name: String
    let email: String
    let isActive: Bool
    
    init(id: String = UUID().uuidString, name: String, email: String, isActive: Bool = true) {
        self.id = id
        self.name = name
        self.email = email
        self.isActive = isActive
    }
}

class NetworkService {
    private let baseURL = "https://api.example.com"
    
    func getUsers() async throws -> [User] {
        guard let url = URL(string: "\\(baseURL)/users") else {
            throw NetworkError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.badResponse
        }
        
        return try JSONDecoder().decode([User].self, from: data)
    }
}

enum NetworkError: Error {
    case invalidURL
    case badResponse
    case decodingError
}
"""

// MARK: - Sample JavaScript Code  
let sampleJavaScriptCode = """
class TaskManager {
    constructor() {
        this.tasks = [];
        this.nextId = 1;
    }
    
    addTask(title, description, priority = 'medium') {
        const task = {
            id: this.nextId++,
            title: title,
            description: description,
            priority: priority,
            completed: false,
            createdAt: new Date().toISOString()
        };
        
        this.tasks.push(task);
        this.notifyObservers('taskAdded', task);
        return task;
    }
    
    completeTask(taskId) {
        const task = this.tasks.find(t => t.id === taskId);
        if (task) {
            task.completed = true;
            task.completedAt = new Date().toISOString();
            this.notifyObservers('taskCompleted', task);
        }
    }
    
    removeTask(taskId) {
        const index = this.tasks.findIndex(t => t.id === taskId);
        if (index !== -1) {
            const removedTask = this.tasks.splice(index, 1)[0];
            this.notifyObservers('taskRemoved', removedTask);
        }
    }
    
    getTasks(filter = 'all') {
        switch (filter) {
            case 'completed':
                return this.tasks.filter(task => task.completed);
            case 'pending':
                return this.tasks.filter(task => !task.completed);
            case 'high-priority':
                return this.tasks.filter(task => task.priority === 'high');
            default:
                return this.tasks;
        }
    }
    
    notifyObservers(event, data) {
        if (this.observers) {
            this.observers.forEach(observer => {
                if (typeof observer[event] === 'function') {
                    observer[event](data);
                }
            });
        }
    }
}

// Usage example
const taskManager = new TaskManager();
taskManager.addTask('Complete project', 'Finish the coding reviewer app', 'high');
taskManager.addTask('Write tests', 'Create comprehensive test suite', 'medium');
"""

// MARK: - Sample Python Code
let samplePythonCode = """
import asyncio
import aiohttp
import json
from datetime import datetime
from typing import List, Dict, Optional

class DataAnalyzer:
    def __init__(self, api_key: str):
        self.api_key = api_key
        self.session: Optional[aiohttp.ClientSession] = None
        self.data_cache: Dict[str, any] = {}
    
    async def __aenter__(self):
        self.session = aiohttp.ClientSession()
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        if self.session:
            await self.session.close()
    
    async def fetch_data(self, endpoint: str) -> Dict:
        if not self.session:
            raise RuntimeError("Session not initialized. Use async context manager.")
        
        headers = {
            'Authorization': f'Bearer {self.api_key}',
            'Content-Type': 'application/json'
        }
        
        try:
            async with self.session.get(endpoint, headers=headers) as response:
                response.raise_for_status()
                return await response.json()
        except aiohttp.ClientError as e:
            print(f"Error fetching data: {e}")
            return {}
    
    def analyze_data(self, data: List[Dict]) -> Dict[str, any]:
        if not data:
            return {"error": "No data to analyze"}
        
        analysis = {
            "total_records": len(data),
            "timestamp": datetime.now().isoformat(),
            "statistics": {}
        }
        
        # Perform statistical analysis
        numeric_fields = self._identify_numeric_fields(data)
        
        for field in numeric_fields:
            values = [record.get(field, 0) for record in data if field in record]
            if values:
                analysis["statistics"][field] = {
                    "mean": sum(values) / len(values),
                    "min": min(values),
                    "max": max(values),
                    "count": len(values)
                }
        
        return analysis
    
    def _identify_numeric_fields(self, data: List[Dict]) -> List[str]:
        if not data:
            return []
        
        sample = data[0]
        numeric_fields = []
        
        for key, value in sample.items():
            if isinstance(value, (int, float)):
                numeric_fields.append(key)
        
        return numeric_fields
    
    def cache_result(self, key: str, result: any) -> None:
        self.data_cache[key] = result
    
    def get_cached_result(self, key: str) -> Optional[any]:
        return self.data_cache.get(key)

# Usage example
async def main():
    async with DataAnalyzer("your-api-key") as analyzer:
        data = await analyzer.fetch_data("https://api.example.com/data")
        analysis = analyzer.analyze_data(data)
        analyzer.cache_result("latest_analysis", analysis)
        print(json.dumps(analysis, indent=2))

if __name__ == "__main__":
    asyncio.run(main())
"""

// MARK: - Sample HTML Code
let sampleHTMLCode = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Code Review Dashboard</title>
    <link rel="stylesheet" href="styles.css">
</head>
<body>
    <header class="header">
        <nav class="navigation">
            <div class="logo">
                <h1>CodingReviewer</h1>
            </div>
            <ul class="nav-menu">
                <li><a href="#dashboard">Dashboard</a></li>
                <li><a href="#analytics">Analytics</a></li>
                <li><a href="#reports">Reports</a></li>
                <li><a href="#settings">Settings</a></li>
            </ul>
        </nav>
    </header>
    
    <main class="main-content">
        <section id="dashboard" class="dashboard">
            <h2>Project Overview</h2>
            <div class="stats-grid">
                <div class="stat-card">
                    <h3>Total Files</h3>
                    <span class="stat-number" id="total-files">0</span>
                </div>
                <div class="stat-card">
                    <h3>Issues Found</h3>
                    <span class="stat-number critical" id="issues-count">0</span>
                </div>
                <div class="stat-card">
                    <h3>Code Quality</h3>
                    <span class="stat-number good" id="quality-score">85%</span>
                </div>
                <div class="stat-card">
                    <h3>Test Coverage</h3>
                    <span class="stat-number" id="coverage">92%</span>
                </div>
            </div>
        </section>
        
        <section id="file-upload" class="upload-section">
            <h2>Upload Files</h2>
            <div class="upload-area" id="upload-area">
                <p>Drag and drop files here or click to select</p>
                <input type="file" id="file-input" multiple accept=".swift,.js,.py,.html,.css,.json">
            </div>
            <div class="upload-progress" id="upload-progress">
                <div class="progress-bar" id="progress-bar"></div>
            </div>
        </section>
        
        <section id="results" class="results-section">
            <h2>Analysis Results</h2>
            <div class="results-container" id="results-container">
                <!-- Results will be populated dynamically -->
            </div>
        </section>
    </main>
    
    <footer class="footer">
        <p>&copy; 2025 CodingReviewer. All rights reserved.</p>
    </footer>
    
    <script src="app.js"></script>
</body>
</html>
"""

// MARK: - Sample JSON Configuration
let sampleJSONCode = """
{
  "application": {
    "name": "CodingReviewer",
    "version": "1.0.0",
    "environment": "development"
  },
  "fileUpload": {
    "maxFilesPerUpload": 1000,
    "allowedExtensions": [
      ".swift", ".js", ".py", ".html", ".css", 
      ".json", ".xml", ".java", ".cpp", ".c", 
      ".h", ".m", ".mm", ".php", ".rb", ".go"
    ],
    "maxFileSize": "10MB"
  },
  "analysis": {
    "enableComplexityAnalysis": true,
    "enableSecurityScanning": true,
    "enablePerformanceAnalysis": true,
    "complexityThresholds": {
      "low": 1,
      "medium": 5,
      "high": 10,
      "critical": 20
    }
  },
  "ai": {
    "providers": {
      "openai": {
        "enabled": true,
        "model": "gpt-4",
        "maxTokens": 4000,
        "temperature": 0.3
      },
      "gemini": {
        "enabled": true,
        "model": "gemini-pro",
        "maxTokens": 8000,
        "temperature": 0.2
      }
    },
    "features": {
      "codeReview": true,
      "patternRecognition": true,
      "mlIntegration": true,
      "predictiveAnalytics": true
    }
  },
  "security": {
    "encryptionEnabled": true,
    "keyRotationInterval": "30d",
    "auditLogging": true,
    "allowedDomains": [
      "localhost",
      "*.openai.com",
      "*.googleapis.com"
    ]
  },
  "performance": {
    "cacheEnabled": true,
    "cacheTTL": "1h",
    "maxConcurrentUploads": 5,
    "batchProcessingSize": 50
  },
  "logging": {
    "level": "info",
    "categories": ["ai", "file", "security", "performance"],
    "retentionDays": 30,
    "enableRemoteLogging": false
  }
}
"""

// MARK: - Complex Swift Code Sample
let complexSwiftCodeSample = """
import Foundation
import Combine
import SwiftUI

// MARK: - Complex Generic Repository Pattern

protocol Repository {
    associatedtype Entity: Identifiable & Codable
    associatedtype ID: Hashable
    
    func create(_ entity: Entity) async throws -> Entity
    func read(id: ID) async throws -> Entity?
    func update(_ entity: Entity) async throws -> Entity
    func delete(id: ID) async throws
    func list(filter: FilterCriteria?) async throws -> [Entity]
}

struct FilterCriteria {
    let field: String
    let operator: FilterOperator
    let value: Any
    
    enum FilterOperator {
        case equals, contains, greaterThan, lessThan, between
    }
}

class GenericRepository<T: Identifiable & Codable>: Repository {
    typealias Entity = T
    typealias ID = T.ID
    
    private let networkService: NetworkServiceProtocol
    private let cacheService: CacheServiceProtocol
    private let endpoint: String
    
    private var cancellables = Set<AnyCancellable>();
    
    init(networkService: NetworkServiceProtocol, 
         cacheService: CacheServiceProtocol, 
         endpoint: String) {
        self.networkService = networkService
        self.cacheService = cacheService
        self.endpoint = endpoint
    }
    
    func create(_ entity: Entity) async throws -> Entity {
        let request = CreateRequest(endpoint: endpoint, entity: entity)
        let response: Entity = try await networkService.execute(request)
        
        await cacheService.set(key: "\\(endpoint)_\\(response.id)", value: response)
        return response
    }
    
    func read(id: ID) async throws -> Entity? {
        let cacheKey = "\\(endpoint)_\\(id)"
        
        if let cachedEntity: Entity = await cacheService.get(key: cacheKey) {
            return cachedEntity
        }
        
        let request = ReadRequest<Entity>(endpoint: endpoint, id: id)
        let entity: Entity = try await networkService.execute(request)
        
        await cacheService.set(key: cacheKey, value: entity)
        return entity
    }
    
    func update(_ entity: Entity) async throws -> Entity {
        let request = UpdateRequest(endpoint: endpoint, entity: entity)
        let updatedEntity: Entity = try await networkService.execute(request)
        
        let cacheKey = "\\(endpoint)_\\(updatedEntity.id)"
        await cacheService.set(key: cacheKey, value: updatedEntity)
        
        return updatedEntity
    }
    
    func delete(id: ID) async throws {
        let request = DeleteRequest(endpoint: endpoint, id: id)
        try await networkService.execute(request)
        
        let cacheKey = "\\(endpoint)_\\(id)"
        await cacheService.remove(key: cacheKey)
    }
    
    func list(filter: FilterCriteria? = nil) async throws -> [Entity] {
        let request = ListRequest<Entity>(endpoint: endpoint, filter: filter)
        let entities: [Entity] = try await networkService.execute(request)
        
        // Cache individual entities
        await withTaskGroup(of: Void.self) { group in
            for entity in entities {
                group.addTask {
                    let cacheKey = "\\(self.endpoint)_\\(entity.id)"
                    await self.cacheService.set(key: cacheKey, value: entity)
                }
            }
        }
        
        return entities
    }
}

// MARK: - Advanced Error Handling

enum RepositoryError: Error, LocalizedError {
    case networkError(NetworkError)
    case cacheError(CacheError)
    case validationError(ValidationError)
    case unknownError(Error)
    
    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \\(error.localizedDescription)"
        case .cacheError(let error):
            return "Cache error: \\(error.localizedDescription)"
        case .validationError(let error):
            return "Validation error: \\(error.localizedDescription)"
        case .unknownError(let error):
            return "Unknown error: \\(error.localizedDescription)"
        }
    }
}

// MARK: - Complex Business Logic

@MainActor
class ProjectAnalysisEngine: ObservableObject {
    @Published var analysisState: AnalysisState = .idle;
    @Published var currentProgress: Double = 0.0;
    @Published var analysisResults: [AnalysisResult] = [];
    
    private let fileRepository: GenericRepository<CodeFile>
    private let analysisService: AnalysisServiceProtocol
    private let mlService: MLServiceProtocol
    
    private var analysisTask: Task<Void, Error>?
    
    enum AnalysisState {
        case idle, analyzing, completed, failed(Error)
    }
    
    init(fileRepository: GenericRepository<CodeFile>,
         analysisService: AnalysisServiceProtocol,
         mlService: MLServiceProtocol) {
        self.fileRepository = fileRepository
        self.analysisService = analysisService
        self.mlService = mlService
    }
    
    func startAnalysis(for projectId: String) async {
        analysisState = .analyzing
        currentProgress = 0.0
        analysisResults.removeAll()
        
        analysisTask = Task {
            do {
                let files = try await fileRepository.list(filter: nil)
                let totalFiles = files.count
                
                await withThrowingTaskGroup(of: AnalysisResult.self) { group in
                    for (index, file) in files.enumerated() {
                        group.addTask {
                            let result = try await self.analyzeFile(file)
                            
                            await MainActor.run {
                                self.currentProgress = Double(index + 1) / Double(totalFiles)
                            }
                            
                            return result
                        }
                    }
                    
                    for try await result in group {
                        analysisResults.append(result)
                    }
                }
                
                // Perform ML analysis on all results
                let mlInsights = try await mlService.generateInsights(from: analysisResults)
                
                for insight in mlInsights {
                    if let index = analysisResults.firstIndex(where: { $0.fileId == insight.fileId }) {
                        analysisResults[index].mlInsights = insight.insights
                    }
                }
                
                analysisState = .completed
                
            } catch {
                analysisState = .failed(error)
            }
        }
    }
    
    private func analyzeFile(_ file: CodeFile) async throws -> AnalysisResult {
        let complexity = try await analysisService.calculateComplexity(for: file)
        let issues = try await analysisService.findIssues(in: file)
        let suggestions = try await analysisService.generateSuggestions(for: file)
        
        return AnalysisResult(
            fileId: file.id,
            fileName: file.name,
            complexity: complexity,
            issues: issues,
            suggestions: suggestions,
            timestamp: Date()
        )
    }
    
    func cancelAnalysis() {
        analysisTask?.cancel()
        analysisState = .idle
        currentProgress = 0.0
    }
}

struct AnalysisResult: Identifiable {
    let id = UUID()
    let fileId: String
    let fileName: String
    let complexity: ComplexityMetrics
    let issues: [CodeIssue]
    let suggestions: [Suggestion]
    let timestamp: Date
    var mlInsights: [MLInsight] = [];
}
"""
