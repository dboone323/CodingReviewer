#!/usr/bin/env swift

//
//  validate_app.swift
//  CodingReviewer App Validation
//
//  Created by AI Assistant on 7/18/25.
//

import Foundation

class AppValidator {
    private var passedChecks = 0
    private var failedChecks = 0
    
    // Dynamic path detection
    private let projectPath: String
    
    init() {
        // Get the current working directory or use the script's directory
        if let scriptPath = ProcessInfo.processInfo.environment["PWD"] {
            projectPath = scriptPath
        } else {
            // Fallback to script's directory
            let scriptURL = URL(fileURLWithPath: CommandLine.arguments[0])
            projectPath = scriptURL.deletingLastPathComponent().path
        }
    }
    
    func validate() {
        print("🔍 CodingReviewer App Validation Suite")
        print("📁 Project Path: \(projectPath)")
        print(String(repeating: "=", count: 60))
        
        validateProjectStructure()
        validateBuildConfiguration()
        validateSourceFiles()
        validateTestFiles()
        validateAssets()
        
        printValidationSummary()
    }
    
    private func check(_ condition: Bool, _ description: String) {
        if condition {
            passedChecks += 1
            print("✅ \(description)")
        } else {
            failedChecks += 1
            print("❌ \(description)")
        }
    }
    
    private func validateProjectStructure() {
        print("\n📁 Validating Project Structure...")
        
        let fileManager = FileManager.default
        
        // Check main project file
        check(fileManager.fileExists(atPath: "\(projectPath)/CodingReviewer.xcodeproj"),
              "Xcode project file exists")
        
        // Check source directory
        check(fileManager.fileExists(atPath: "\(projectPath)/CodingReviewer"),
              "Source directory exists")
        
        // Check test directories
        check(fileManager.fileExists(atPath: "\(projectPath)/CodingReviewerTests"),
              "Unit tests directory exists")
        check(fileManager.fileExists(atPath: "\(projectPath)/CodingReviewerUITests"),
              "UI tests directory exists")
        
        // Check configuration files
        check(fileManager.fileExists(atPath: "\(projectPath)/.gitignore"),
              "Git ignore file exists")
        check(fileManager.fileExists(atPath: "\(projectPath)/README.md"),
              "README file exists")
        
        // Check test files directory
        check(fileManager.fileExists(atPath: "\(projectPath)/TestFiles"),
              "Test files directory exists")
    }
    
    private func validateBuildConfiguration() {
        print("\n🔧 Validating Build Configuration...")
        
        let fileManager = FileManager.default
        
        // Check Info.plist
        check(fileManager.fileExists(atPath: "\(projectPath)/CodingReviewer/Info.plist"),
              "Info.plist exists")
        
        // Check .swiftlint.yml
        check(fileManager.fileExists(atPath: "\(projectPath)/.swiftlint.yml"),
              "SwiftLint configuration exists")
        
        // Check for Package.swift (if using SPM)
        let hasPackageSwift = fileManager.fileExists(atPath: "\(projectPath)/Package.swift")
        if hasPackageSwift {
            print("📦 Package.swift found - SPM project detected")
        }
        
        // Check for Podfile (if using CocoaPods)
        let hasPodfile = fileManager.fileExists(atPath: "\(projectPath)/Podfile")
        if hasPodfile {
            print("🍫 Podfile found - CocoaPods project detected")
        }
        
        // Check schemes directory
        check(fileManager.fileExists(atPath: "\(projectPath)/CodingReviewer.xcodeproj/xcshareddata/xcschemes"),
              "Shared schemes directory exists")
    }
    
    private func validateSourceFiles() {
        print("\n📄 Validating Source Files...")
        
        let fileManager = FileManager.default
        let sourcePath = "\(projectPath)/CodingReviewer"
        let expectedFiles = [
            "CodingReviewerApp.swift",
            "ContentView.swift",
            "AppLogger.swift",
            "CodeAnalyzers.swift",
            "CodeReviewViewModel.swift",
            "FileManagerService.swift",
            "AIServiceProtocol.swift",
            "OpenAIService.swift",
            "AICodeReviewService.swift",
            "APIKeyManager.swift",
            "AISettingsView.swift"
        ]
        
        for file in expectedFiles {
            let filePath = "\(sourcePath)/\(file)"
            let exists = fileManager.fileExists(atPath: filePath)
            check(exists, "Source file exists: \(file)")
            
            if exists {
                // Check if file is not empty
                do {
                    let content = try String(contentsOfFile: filePath, encoding: .utf8)
                    check(!content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                          "Source file has content: \(file)")
                } catch {
                    check(false, "Could not read source file: \(file)")
                }
            }
        }
    }
    
    private func validateTestFiles() {
        print("\n🧪 Validating Test Files...")
        
        let testPath = "\(projectPath)/CodingReviewerTests"
        let expectedTestFiles = [
            "CodingReviewerTests.swift",
            "CodeAnalysisTests.swift",
            "FileManagerServiceTests.swift",
            "AIServiceTests.swift"
        ]
        
        let fileManager = FileManager.default
        
        for file in expectedTestFiles {
            let filePath = "\(testPath)/\(file)"
            let exists = fileManager.fileExists(atPath: filePath)
            check(exists, "Test file exists: \(file)")
            
            if exists {
                // Check if test file contains test methods
                do {
                    let content = try String(contentsOfFile: filePath, encoding: .utf8)
                    check(content.contains("func test"), "Test file contains test methods: \(file)")
                    check(content.contains("XCTest") || content.contains("Testing"),
                          "Test file imports testing framework: \(file)")
                } catch {
                    check(false, "Could not read test file: \(file)")
                }
            }
        }
        
        // Check standalone test files
        let standaloneTests = [
            "test_core_components.swift",
            "validate_app.swift"
        ]
        
        for file in standaloneTests {
            let filePath = "\(projectPath)/\(file)"
            check(fileManager.fileExists(atPath: filePath), "Standalone test exists: \(file)")
        }
    }
    
    private func validateAssets() {
        print("\n🎨 Validating Assets...")
        
        let assetsPath = "\(projectPath)/CodingReviewer/Assets.xcassets"
        let fileManager = FileManager.default
        
        check(fileManager.fileExists(atPath: assetsPath), "Assets catalog exists")
        check(fileManager.fileExists(atPath: "\(assetsPath)/AppIcon.appiconset"),
              "App icon set exists")
        check(fileManager.fileExists(atPath: "\(assetsPath)/AccentColor.colorset"),
              "Accent color set exists")
    }
    
    private func printValidationSummary() {
        print("\n" + String(repeating: "=", count: 60))
        print("📊 VALIDATION SUMMARY")
        print(String(repeating: "=", count: 60))
        print("✅ Passed: \(passedChecks)")
        print("❌ Failed: \(failedChecks)")
        print("📈 Total:  \(passedChecks + failedChecks)")
        
        if failedChecks == 0 {
            print("🎉 ALL VALIDATIONS PASSED!")
            print("✨ The CodingReviewer app is ready for use!")
        } else {
            print("⚠️  \(failedChecks) validation(s) failed")
            print("🔧 Please address the failed validations before using the app")
        }
        print(String(repeating: "=", count: 60))
    }
}

// Run the validation
let validator = AppValidator()
validator.validate()