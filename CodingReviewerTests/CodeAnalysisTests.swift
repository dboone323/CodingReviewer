import XCTest
@testable import CodingReviewer

final class CodeAnalysisTests: XCTestCase {
    
    func testBasicCodeAnalysis() async throws {
        let qualityAnalyzer = QualityAnalyzer()
        let securityAnalyzer = SecurityAnalyzer()
        let testCode = """
        import Foundation
        
        func testFunction() {
            let password = "hardcoded_password"  // Security issue
            let url = "http://insecure.com"      // HTTP instead of HTTPS
            let array = [1, 2, 3, 4, 5]
            
            // Force unwrapping
            let firstElement = array.first!
            
            // This is a very long line that exceeds 120 characters and should trigger the line length warning in our analyzer
        }
        """
        
        let qualityResults = await qualityAnalyzer.analyze(testCode)
        let securityResults = await securityAnalyzer.analyze(testCode)
        let allResults = qualityResults + securityResults
        
        // Verify we get analysis results
        XCTAssertFalse(allResults.isEmpty, "Analysis should return results for problematic code")
        
        // Check for security issues
        let securityIssues = allResults.filter { $0.type == .security }
        XCTAssertTrue(securityIssues.count >= 1, "Should detect at least one security issue")
        
        // Check for quality issues
        let qualityIssues = allResults.filter { $0.type == .quality }
        XCTAssertTrue(qualityIssues.count >= 1, "Should detect at least one quality issue")
        
        print("✅ Analysis found \(allResults.count) total issues:")
        for result in allResults {
            print("   - \(result.type): \(result.message)")
        }
    }
    
    func testCleanCodeAnalysis() async throws {
        let qualityAnalyzer = QualityAnalyzer()
        let securityAnalyzer = SecurityAnalyzer()
        let cleanCode = """
        import Foundation
        
        func cleanFunction() {
            let items = [1, 2, 3]
            if let first = items.first {
                print("First item: \\(first)")
            }
        }
        """
        
        let qualityResults = await qualityAnalyzer.analyze(cleanCode)
        let securityResults = await securityAnalyzer.analyze(cleanCode)
        let allResults = qualityResults + securityResults
        
        // Clean code should have minimal or no issues
        let criticalIssues = allResults.filter { $0.severity == .high }
        XCTAssertTrue(criticalIssues.isEmpty, "Clean code should have no critical issues")
        
        print("✅ Clean code analysis found \(allResults.count) issues")
    }
}
