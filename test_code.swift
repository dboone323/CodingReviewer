import Foundation

// Test code with various issues for analysis
func testFunction() {
    let password = "hardcoded_password"  // Security issue
    let url = "http://insecure.com"      // HTTP instead of HTTPS
    let array = [1, 2, 3, 4, 5]
    
    // Force unwrapping
    let firstElement = array.first!
    
    // Long line that exceeds 120 characters - this is a very long comment that should trigger the line length warning
    
    for i in 0..<1000 {
        print("Processing item \(i)")    // Performance issue
    }
}
