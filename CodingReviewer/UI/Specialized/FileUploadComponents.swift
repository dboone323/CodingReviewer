import Foundation
//
// FileUploadComponents.swift
// CodingReviewer
//
// Specialized file upload UI components

import SwiftUI
import UniformTypeIdentifiers

/// Drag and drop file upload component
struct DragDropUploadView: View {
    @Binding var isTargeted: Bool
    let onFileDrop: ([URL]) -> Void
    
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(isTargeted ? Color.blue.opacity(0.3) : Color.gray.opacity(0.1))
            .frame(height: 200)
            .overlay(
                VStack(spacing: 16) {
                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 48))
                        .foregroundColor(isTargeted ? .blue : .gray)
                    
                    Text("Drop files here to analyze")
                        .font(.headline)
                        .foregroundColor(isTargeted ? .blue : .gray)
                    
                    Text("Supports Swift, Objective-C, C++, and more")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            )
            .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
                handleDrop(providers: providers)
                return true
            }
    }
    
    private func handleDrop(providers: [NSItemProvider]) {
        let urlsQueue = DispatchQueue(label: "file-urls", attributes: .concurrent)
        var urls: [URL] = []
        let group = DispatchGroup()
        
        for provider in providers {
            group.enter()
            provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, error in
                if let data = item as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil) {
                    urlsQueue.async(flags: .barrier) {
                        urls.append(url)
                    }
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            onFileDrop(urls)
        }
    }
}

/// File selection button component
struct FileSelectionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
    }
}

/// Upload progress indicator
struct UploadProgressView: View {
    let progress: Double
    let fileName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(fileName)
                    .font(.caption)
                    .lineLimit(1)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle())
        }
        .padding(.horizontal)
    }
}

/// File type filter component
struct FileTypeFilterView: View {
    @Binding var selectedTypes: Set<String>
    let availableTypes = ["Swift", "Objective-C", "C++", "JavaScript", "Python", "All"]
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
            ForEach(availableTypes, id: \.self) { type in
                Toggle(type, isOn: Binding(
                    get: { selectedTypes.contains(type) },
                    set: { isSelected in
                        if isSelected {
                            selectedTypes.insert(type)
                        } else {
                            selectedTypes.remove(type)
                        }
                    }
                ))
                .toggleStyle(CheckboxToggleStyle())
            }
        }
    }
}

/// Custom checkbox toggle style
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .foregroundColor(configuration.isOn ? .blue : .gray)
                .onTapGesture {
                    configuration.isOn.toggle()
                }
            
            configuration.label
                .font(.caption)
        }
    }
}
