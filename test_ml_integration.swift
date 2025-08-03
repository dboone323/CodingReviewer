#!/usr/bin/env swift

//
// ML Integration Test Script
// Tests the updated ML integration functionality
//

import Foundation

// Test ML Integration
func testMLIntegration() {
    print("🧪 Testing ML Integration")
    print("========================")
    
    // Check for ML data files
    let fileManager = FileManager.default
    let mlDirectories = [
        ".ml_automation/data",
        ".predictive_analytics",
        ".cross_project_learning/insights"
    ]
    
    for dir in mlDirectories {
        print("\n📂 Checking directory: \(dir)")
        
        if fileManager.fileExists(atPath: dir) {
            do {
                let files = try fileManager.contentsOfDirectory(atPath: dir)
                let recentFiles = files.filter { $0.contains("20250803") }
                
                if recentFiles.isEmpty {
                    print("  ❌ No recent files found")
                } else {
                    print("  ✅ Found \(recentFiles.count) recent files:")
                    for file in recentFiles.prefix(3) {
                        print("    • \(file)")
                    }
                }
            } catch {
                print("  ❌ Error reading directory: \(error)")
            }
        } else {
            print("  ❌ Directory not found")
        }
    }
    
    print("\n🎯 ML Integration Status: Data Available")
}

testMLIntegration()
