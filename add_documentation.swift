#!/usr/bin/env swift

import Foundation

// Auto-documentation generator for Swift functions
let swiftFiles = CommandLine.arguments.dropFirst()

for filePath in swiftFiles {
    let url = URL(fileURLWithPath: String(filePath))
    guard let content = try? String(contentsOf: url) else { continue }
    
    let lines = content.components(separatedBy: .newlines)
    var newLines: [String] = []
    
    for (index, line) in lines.enumerated() {
        // Check if this is a public function without documentation
        if line.trimmingCharacters(in: .whitespaces).hasPrefix("public func") ||
           line.trimmingCharacters(in: .whitespaces).hasPrefix("open func") {
            
            let prevLine = index > 0 ? lines[index - 1] : ""
            if !prevLine.contains("///") {
                let indent = String(line.prefix(while: { $0.isWhitespace }))
                newLines.append("\(indent)/// <#Description#>")
            }
        }
        newLines.append(line)
    }
    
    let newContent = newLines.joined(separator: "\n")
    try? newContent.write(to: url, atomically: true, encoding: .utf8)
}
