
import XCTest
@testable import CodingReviewer

class ArchitectureTests: XCTestCase {

    func testNoSwiftUIImportsInDataModels() throws {
        let sharedTypesPath = "/Users/danielstevens/Desktop/CodingReviewer/CodingReviewer/SharedTypes"
        let fileManager = FileManager.default
        let enumerator = fileManager.enumerator(atPath: sharedTypesPath)

        while let element = enumerator?.nextObject() as? String {
            if element.hasSuffix(".swift") {
                let filePath = sharedTypesPath + "/" + element
                let content = try String(contentsOfFile: filePath)
                XCTAssertFalse(content.contains("import SwiftUI"), "File \(element) in SharedTypes should not import SwiftUI")
            }
        }
    }
}
