#!/usr/bin/env swift

//
// ML Integration Deep Test
// Comprehensive testing of ML integration functionality
//

import Foundation

    /// <#Description#>
    /// - Returns: <#description#>
func testMLIntegrationDeep() {
    print("🔍 Deep ML Integration Test")
    print("===========================")

    // Test 1: Check ML data files
    print("\n📊 Test 1: ML Data Files")
    let mlPaths = [
        ".ml_automation/data",
        ".predictive_analytics",
        ".cross_project_learning/insights",
    ]

    for path in mlPaths {
        print("  Checking: \(path)")

        if FileManager.default.fileExists(atPath: path) {
            do {
                let files = try FileManager.default.contentsOfDirectory(atPath: path)
                let todayFiles = files.filter { $0.contains("20250803") }

                print("    ✅ Directory exists (\(files.count) total files)")
                print("    📅 Today's files: \(todayFiles.count)")

                for file in todayFiles.prefix(2) {
                    print("      • \(file)")
                }
            } catch {
                print("    ❌ Error reading: \(error)")
            }
        } else {
            print("    ❌ Directory not found")
        }
    }

    // Test 2: Check file contents
    print("\n📄 Test 2: File Content Analysis")

    // Check latest predictive analytics file
    if let latestFile = findLatestFile(in: ".predictive_analytics", pattern: "dashboard_") {
        print("  Latest dashboard file: \(latestFile)")

        do {
            let content = try String(contentsOfFile: latestFile, encoding: .utf8)
            print("    ✅ File readable (\(content.count) chars)")

            // Check for key content markers
            let markers = ["confidence", "completion", "risk", "forecast"]
            for marker in markers {
                if content.contains(marker) {
                    print("    ✅ Contains '\(marker)'")
                } else {
                    print("    ⚠️  Missing '\(marker)'")
                }
            }
        } catch {
            print("    ❌ Error reading file: \(error)")
        }
    }

    // Test 3: Check ML automation data
    if let latestMLFile = findLatestFile(in: ".ml_automation/data", pattern: "code_analysis_") {
        print("\n  Latest ML analysis: \(latestMLFile)")

        do {
            let content = try String(contentsOfFile: latestMLFile, encoding: .utf8)
            print("    ✅ File readable (\(content.count) chars)")

            // Try to parse as JSON
            if let data = content.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            {
                print("    ✅ Valid JSON structure")

                if let analysisResults = json["analysis_results"] as? [String: Any] {
                    print("    ✅ Contains analysis_results")
                    print("    📊 Keys: \(analysisResults.keys.joined(separator: ", "))")
                } else {
                    print("    ⚠️  Missing analysis_results")
                }
            } else {
                print("    ❌ Invalid JSON format")
            }
        } catch {
            print("    ❌ Error reading ML file: \(error)")
        }
    }

    // Test 4: Test script execution
    print("\n🔧 Test 3: Script Execution Test")
    print("  Running predictive analytics (5 second test)...")

    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/bin/bash")
    task.arguments = ["-c", "./predictive_analytics.sh > /tmp/ml_test_output.log 2>&1 & echo $!"]

    do {
        try task.run()
        task.waitUntilExit()

        // Check output
        Thread.sleep(forTimeInterval: 2)
        if let output = try? String(contentsOfFile: "/tmp/ml_test_output.log", encoding: .utf8) {
            let lines = output.components(separatedBy: .newlines).prefix(5)
            print("    📋 Script output preview:")
            for line in lines {
                if !line.isEmpty {
                    print("      \(line)")
                }
            }
        }
    } catch {
        print("    ❌ Script execution failed: \(error)")
    }

    print("\n🎯 ML Integration Deep Test Complete")
}

    /// <#Description#>
    /// - Returns: <#description#>
func findLatestFile(in directory: String, pattern: String) -> String? {
    guard let enumerator = FileManager.default.enumerator(atPath: directory) else {
        return nil
    }

    var latestFile: String?
    var latestDate: Date?

    for case let file as String in enumerator {
        if file.contains(pattern) {
            let fullPath = "\(directory)/\(file)"
            if let attributes = try? FileManager.default.attributesOfItem(atPath: fullPath),
               let modDate = attributes[.modificationDate] as? Date
            {
                if latestDate == nil || modDate > latestDate! {
                    latestDate = modDate
                    latestFile = fullPath
                }
            }
        }
    }

    return latestFile
}

testMLIntegrationDeep()
