//
// SharedTypes.swift
// CodingReviewer
//
// Additional shared types for enterprise integration
//

import Foundation

// MARK: - Export Template Types
public struct ExportTemplate {
    let id: String
    let name: String
    let description: String
    let format: ExportFormat
    let dataTypes: [String]
    let isDefault: Bool
    let createdAt: Date
    
    public enum ExportFormat: String, Codable, CaseIterable {
        case json = "JSON"
        case csv = "CSV"
        case xml = "XML"
        case pdf = "PDF"
        case html = "HTML"
        case markdown = "Markdown"
        
        var fileExtension: String {
            switch self {
            case .json: return "json"
            case .csv: return "csv"
            case .xml: return "xml"
            case .pdf: return "pdf"
            case .html: return "html"
            case .markdown: return "md"
            }
        }
        
        var mimeType: String {
            switch self {
            case .json: return "application/json"
            case .csv: return "text/csv"
            case .xml: return "application/xml"
            case .pdf: return "application/pdf"
            case .html: return "text/html"
            case .markdown: return "text/markdown"
            }
        }
        
        var iconName: String {
            switch self {
            case .json: return "doc.text"
            case .csv: return "tablecells"
            case .xml: return "doc.richtext"
            case .pdf: return "doc.fill"
            case .html: return "globe"
            case .markdown: return "textformat"
            }
        }
        
        var icon: String {
            return iconName
        }
    }
}
