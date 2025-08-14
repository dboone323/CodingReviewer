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
            case .json: "json"
            case .csv: "csv"
            case .xml: "xml"
            case .pdf: "pdf"
            case .html: "html"
            case .markdown: "md"
            }
        }

        var mimeType: String {
            switch self {
            case .json: "application/json"
            case .csv: "text/csv"
            case .xml: "application/xml"
            case .pdf: "application/pdf"
            case .html: "text/html"
            case .markdown: "text/markdown"
            }
        }

        var iconName: String {
            switch self {
            case .json: "doc.text"
            case .csv: "tablecells"
            case .xml: "doc.richtext"
            case .pdf: "doc.fill"
            case .html: "globe"
            case .markdown: "textformat"
            }
        }

        var icon: String {
            iconName
        }
    }
}
