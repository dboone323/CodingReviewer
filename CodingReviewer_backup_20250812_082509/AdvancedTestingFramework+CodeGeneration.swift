//
//  AdvancedTestingFramework+CodeGeneration.swift
//  CodingReviewer
//
//  Created by Daniel Stevens on 8/7/25.
//  Phase 7 - Advanced Testing Integration
//

import Foundation

// MARK: - Test Code Generation Extensions

extension AdvancedTestingFramework {
    // MARK: - Helper Functions for Code Parsing

    /// <#Description#>
    /// - Returns: <#description#>
    func extractFunctionName(from line: String) -> String {
        let pattern = #"func\s+(\w+)"#
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(line.startIndex ..< line.endIndex, in: line)

        if let match = regex?.firstMatch(in: line, range: range) {
            let matchRange = Range(match.range(at: 1), in: line)!
            return String(line[matchRange])
        }
        return "unknownFunction"
    }

    /// <#Description#>
    /// - Returns: <#description#>
    func extractClassName(from line: String) -> String {
        let pattern = #"class\s+(\w+)"#
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(line.startIndex ..< line.endIndex, in: line)

        if let match = regex?.firstMatch(in: line, range: range) {
            let matchRange = Range(match.range(at: 1), in: line)!
            return String(line[matchRange])
        }
        return "UnknownClass"
    }

    /// <#Description#>
    /// - Returns: <#description#>
    func extractParameters(from line: String) -> [String] {
        let pattern = #"\(([^)]*)\)"#
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(line.startIndex ..< line.endIndex, in: line)

        if let match = regex?.firstMatch(in: line, range: range) {
            let matchRange = Range(match.range(at: 1), in: line)!
            let paramString = String(line[matchRange])
            return paramString.isEmpty ? [] : paramString.components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
        }
        return []
    }

    /// <#Description#>
    /// - Returns: <#description#>
    func extractReturnType(from line: String) -> String? {
        let pattern = #"->\s*(\w+)"#
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(line.startIndex ..< line.endIndex, in: line)

        if let match = regex?.firstMatch(in: line, range: range) {
            let matchRange = Range(match.range(at: 1), in: line)!
            return String(line[matchRange])
        }
        return nil
    }

    // MARK: - Basic Function Test Generation

    func generateBasicFunctionTest(functionName: String, parameters: [String], returnType: String?,
                                   fileName: String) -> String
    {
        let className = extractTestClassName(from: fileName)
        let testFunctionName = "test\(functionName.capitalized)BasicFunctionality"

        var testCode = """
    /// <#Description#>
    /// - Returns: <#description#>
        func \(testFunctionName)() async throws {
            // Arrange
            let sut = \(className)()

        """

        // Generate parameter setup
        if !parameters.isEmpty {
            testCode += "        // Setup test parameters\n"
            for param in parameters {
                let paramName = extractParameterName(from: param)
                let paramType = extractParameterType(from: param)
                testCode += "        let \(paramName) = \(generateTestValue(for: paramType))\n"
            }
            testCode += "\n"
        }

        // Generate function call
        testCode += "        // Act\n"
        if let returnType {
            let paramList = parameters.isEmpty ? "" : parameters.map { extractParameterName(from: $0) }
                .joined(separator: ", ")
            testCode += "        let result = "
            if returnType == "Void" || returnType.isEmpty {
                testCode += "sut.\(functionName)(\(paramList))\n"
            } else {
                testCode += "await sut.\(functionName)(\(paramList))\n"
            }
        } else {
            let paramList = parameters.isEmpty ? "" : parameters.map { extractParameterName(from: $0) }
                .joined(separator: ", ")
            testCode += "        await sut.\(functionName)(\(paramList))\n"
        }

        testCode += "\n        // Assert\n"
        if let returnType, returnType != "Void", !returnType.isEmpty {
            testCode += "        XCTAssertNotNil(result, \"\(functionName) should return a valid result\")\n"
            testCode += "        // Add specific assertions based on expected behavior\n"
        } else {
            testCode += "        // Verify that function executes without throwing\n"
            testCode += "        // Add specific state assertions here\n"
        }

        testCode += "    }\n"
        return testCode
    }

    // MARK: - Edge Case Test Generation

    func generateEdgeCaseFunctionTest(
        functionName: String,
        parameters: [String],
        returnType _: String?,
        fileName: String
    ) -> String {
        let className = extractTestClassName(from: fileName)
        let testFunctionName = "test\(functionName.capitalized)EdgeCases"

        var testCode = """
    /// <#Description#>
    /// - Returns: <#description#>
        func \(testFunctionName)() async throws {
            // Arrange
            let sut = \(className)()

            // Test with nil values where applicable
        """

        for param in parameters {
            let paramName = extractParameterName(from: param)
            let paramType = extractParameterType(from: param)

            if paramType.contains("?") {
                testCode += """

                        // Act & Assert - Test with nil \(paramName)
                        do {
                            let result = await sut.\(functionName)(\(paramName): nil)
                            // Verify nil handling behavior
                        } catch {
                            // Expected error for nil input
                        }
                """
            }

            if paramType.contains("String") {
                testCode += """

                        // Act & Assert - Test with empty string
                        do {
                            let result = await sut.\(functionName)(\(paramName): "")
                            // Verify empty string handling
                        } catch {
                            // Handle empty string error if applicable
                        }
                """
            }

            if paramType.contains("Array") || paramType.contains("[") {
                testCode += """

                        // Act & Assert - Test with empty array
                        do {
                            let result = await sut.\(functionName)(\(paramName): [])
                            // Verify empty array handling
                        } catch {
                            // Handle empty array error if applicable
                        }
                """
            }
        }

        testCode += "\n    }\n"
        return testCode
    }

    // MARK: - Error Handling Test Generation

    /// <#Description#>
    /// - Returns: <#description#>
    func generateErrorHandlingFunctionTest(functionName: String, parameters _: [String], fileName: String) -> String {
        let className = extractTestClassName(from: fileName)
        let testFunctionName = "test\(functionName.capitalized)ErrorHandling"

        let testCode = """
    /// <#Description#>
    /// - Returns: <#description#>
        func \(testFunctionName)() async throws {
            // Arrange
            let sut = \(className)()

            // Act & Assert - Test error throwing behavior
            do {
                let invalidInput = generateInvalidInput()
                let result = try await sut.\(functionName)(invalidInput)
                XCTFail("Expected function to throw an error")
            } catch {
                // Verify that appropriate error is thrown
                XCTAssertNotNil(error, "Function should throw a meaningful error")
                // Add specific error type assertions here
            }

            // Test error recovery
            do {
                let validInput = generateValidInput()
                let result = try await sut.\(functionName)(validInput)
                XCTAssertNotNil(result, "Function should work with valid input after error")
            } catch {
                XCTFail("Function should not throw with valid input: \\(error)")
            }
        }

        private func generateInvalidInput() -> Any {
            // Return intentionally invalid input for testing
            return NSNull()
        }

        private func generateValidInput() -> Any {
            // Return valid input for recovery testing
            return "validTestInput"
        }
        """

        return testCode
    }

    // MARK: - Class Test Generation

    /// <#Description#>
    /// - Returns: <#description#>
    func generateClassInitializationTest(className: String, fileName _: String) -> String {
        let testCode = """
    /// <#Description#>
    /// - Returns: <#description#>
        func test\(className)Initialization() {
            // Act
            let sut = \(className)()

            // Assert
            XCTAssertNotNil(sut, "\(className) should initialize successfully")
            // Add property initialization assertions here

            // Test that initial state is valid
            // Example: XCTAssertEqual(sut.initialProperty, expectedValue)
        }
        """
        return testCode
    }

    /// <#Description#>
    /// - Returns: <#description#>
    func generateClassLifecycleTest(className: String, fileName _: String) -> String {
        let testCode = """
    /// <#Description#>
    /// - Returns: <#description#>
        func test\(className)Lifecycle() async {
            var sut: \(className)? = \(className)()

            // Verify initialization
            XCTAssertNotNil(sut, "\(className) should initialize")

            // Test lifecycle methods if any
            // await sut?.prepareForUse()

            // Test cleanup
            sut = nil

            // Allow time for deinitialization
            await Task.yield()

            // Verify cleanup completed
            // Add specific cleanup verification here
        }
        """
        return testCode
    }

    // MARK: - Concurrency Test Generation

    /// <#Description#>
    /// - Returns: <#description#>
    func generateAsyncTest(fileName: String) -> String {
        let className = extractTestClassName(from: fileName)
        let testCode = """
    /// <#Description#>
    /// - Returns: <#description#>
        func testAsyncFunctionality() async throws {
            // Arrange
            let sut = \(className)()
            let expectation = XCTestExpectation(description: "Async operation completes")

            // Act
            let task = Task {
                defer { expectation.fulfill() }
                // Test async operations
                let result = await sut.performAsyncOperation()
                return result
            }

            // Wait for completion
            await fulfillment(of: [expectation], timeout: 5.0)

            // Assert
            let result = await task.value
            XCTAssertNotNil(result, "Async operation should return result")
        }
        """
        return testCode
    }

    /// <#Description#>
    /// - Returns: <#description#>
    func generateActorIsolationTest(fileName _: String) -> String {
        let testCode = """
    /// <#Description#>
    /// - Returns: <#description#>
        func testActorIsolation() async {
            // Test that actor isolation is properly maintained
            let actor = TestActor()

            // Test concurrent access doesn't cause data races
            await withTaskGroup(of: Void.self) { group in
                for i in 0..<10 {
                    group.addTask {
                        await actor.performOperation(i)
                    }
                }
            }

            // Verify state consistency
            let finalState = await actor.getState()
            XCTAssertNotNil(finalState, "Actor state should be consistent")
        }

        actor TestActor {
            private var state: Int = 0

    /// <#Description#>
    /// - Returns: <#description#>
            func performOperation(_ value: Int) {
                state += value
            }

    /// <#Description#>
    /// - Returns: <#description#>
            func getState() -> Int {
                return state
            }
        }
        """
        return testCode
    }

    /// <#Description#>
    /// - Returns: <#description#>
    func generateTaskTest(fileName _: String) -> String {
        let testCode = """
    /// <#Description#>
    /// - Returns: <#description#>
        func testTaskExecution() async throws {
            // Test Task-based concurrency
            let tasks = (0..<5).map { index in
                Task {
                    await performBackgroundWork(index)
                    return index
                }
            }

            // Wait for all tasks to complete
            let results = await withTaskGroup(of: Int.self) { group in
                for task in tasks {
                    group.addTask {
                        await task.value
                    }
                }

                var collectedResults: [Int] = []
                for await result in group {
                    collectedResults.append(result)
                }
                return collectedResults
            }

            // Assert results
            XCTAssertEqual(results.count, 5, "All tasks should complete")
            XCTAssertEqual(Set(results), Set(0..<5), "All expected results should be present")
        }

        private func performBackgroundWork(_ index: Int) async {
            // Simulate background work
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        """
        return testCode
    }

    // MARK: - Specialized Test Generation

    /// <#Description#>
    /// - Returns: <#description#>
    func generateErrorPropagationTest(fileName: String) -> String {
        let className = extractTestClassName(from: fileName)
        let testCode = """
    /// <#Description#>
    /// - Returns: <#description#>
        func testErrorPropagation() async throws {
            // Arrange
            let sut = \(className)()

            // Act & Assert - Test error propagation
            do {
                try await sut.operationThatThrows()
                XCTFail("Operation should have thrown an error")
            } catch TestError.expectedError {
                // Expected error type - test passes
            } catch {
                XCTFail("Unexpected error type: \\(error)")
            }
        }

        enum TestError: Error {
            case expectedError
        }
        """
        return testCode
    }

    /// <#Description#>
    /// - Returns: <#description#>
    func generateErrorRecoveryTest(fileName: String) -> String {
        let className = extractTestClassName(from: fileName)
        let testCode = """
    /// <#Description#>
    /// - Returns: <#description#>
        func testErrorRecovery() async throws {
            // Arrange
            let sut = \(className)()

            // Simulate error condition
            // Act & Assert - Test recovery after error
            do {
                try await sut.operationWithRecovery()
            } catch {
                // Test that system can recover from error
                let recoveryResult = await sut.attemptRecovery()
                XCTAssertTrue(recoveryResult, "System should recover from error")
            }
        }
        """
        return testCode
    }

    /// <#Description#>
    /// - Returns: <#description#>
    func generateNilHandlingTest(fileName: String) -> String {
        let className = extractTestClassName(from: fileName)
        let testCode = """
    /// <#Description#>
    /// - Returns: <#description#>
        func testNilHandling() {
            // Arrange
            let sut = \(className)()

            // Test nil parameter handling
            let result1 = sut.handleOptionalParameter(nil)
            XCTAssertNotNil(result1, "Should handle nil gracefully")

            // Test optional chaining
            let optionalObject: TestObject? = nil
            let result2 = optionalObject?.property
            XCTAssertNil(result2, "Optional chaining should return nil")

            // Test nil coalescing
            let result3 = optionalObject?.property ?? "default"
            XCTAssertEqual(result3, "default", "Nil coalescing should work")
        }

        struct TestObject {
            let property: String = "test"
        }
        """
        return testCode
    }

    /// <#Description#>
    /// - Returns: <#description#>
    func generateEmptyCollectionTest(fileName: String) -> String {
        let className = extractTestClassName(from: fileName)
        let testCode = """
    /// <#Description#>
    /// - Returns: <#description#>
        func testEmptyCollections() {
            // Arrange
            let sut = \(className)()

            // Test empty array handling
            let emptyArray: [String] = []
            let result1 = sut.processArray(emptyArray)
            XCTAssertNotNil(result1, "Should handle empty arrays")

            // Test empty dictionary handling
            let emptyDict: [String: Any] = [:]
            let result2 = sut.processDictionary(emptyDict)
            XCTAssertNotNil(result2, "Should handle empty dictionaries")

            // Test empty string handling
            let emptyString = ""
            let result3 = sut.processString(emptyString)
            XCTAssertNotNil(result3, "Should handle empty strings")
        }
        """
        return testCode
    }

    /// <#Description#>
    /// - Returns: <#description#>
    func generateBoundaryValueTest(fileName: String) -> String {
        let className = extractTestClassName(from: fileName)
        let testCode = """
    /// <#Description#>
    /// - Returns: <#description#>
        func testBoundaryValues() {
            // Arrange
            let sut = \(className)()

            // Test minimum values
            let minResult = sut.processValue(Int.min)
            XCTAssertNotNil(minResult, "Should handle minimum integer value")

            // Test maximum values
            let maxResult = sut.processValue(Int.max)
            XCTAssertNotNil(maxResult, "Should handle maximum integer value")

            // Test zero boundary
            let zeroResult = sut.processValue(0)
            XCTAssertNotNil(zeroResult, "Should handle zero value")

            // Test negative boundary
            let negativeResult = sut.processValue(-1)
            XCTAssertNotNil(negativeResult, "Should handle negative values")
        }
        """
        return testCode
    }

    // MARK: - Helper Methods

    private func extractTestClassName(from fileName: String) -> String {
        let baseName = fileName.replacingOccurrences(of: ".swift", with: "")
        return baseName.replacingOccurrences(of: "Tests", with: "")
    }

    private func extractParameterName(from parameter: String) -> String {
        let components = parameter.components(separatedBy: ":")
        return components.first?.trimmingCharacters(in: .whitespaces) ?? "param"
    }

    private func extractParameterType(from parameter: String) -> String {
        let components = parameter.components(separatedBy: ":")
        if components.count > 1 {
            return components[1].trimmingCharacters(in: .whitespaces)
        }
        return "Any"
    }

    private func generateTestValue(for type: String) -> String {
        switch type.lowercased() {
        case "string", "string?":
            "\"testValue\""
        case "int", "int?":
            "42"
        case "double", "double?":
            "3.14"
        case "bool", "bool?":
            "true"
        case let arrayType where arrayType.contains("[") && arrayType.contains("]"):
            "[]"
        case let dictType where dictType.contains("dictionary") || dictType.contains(":"):
            "[:]"
        default:
            "TestValue()"
        }
    }
}
