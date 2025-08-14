import Foundation
import Combine
import SwiftUI

// MARK: - Shared Data Manager

// This class ensures that file data is shared across all views in the app

@MainActor
final class SharedDataManager: ObservableObject {
    static let shared = SharedDataManager()

    // Shared FileManagerService instance
    @Published var fileManager: FileManagerService

    private init() {
        fileManager = FileManagerService()
    }

    // Method to get the shared file manager
    /// <#Description#>
    /// - Returns: <#description#>
    func getFileManager() -> FileManagerService {
        fileManager
    }

    // Method to explicitly refresh all views
    /// <#Description#>
    /// - Returns: <#description#>
    func refreshAllViews() {
        objectWillChange.send()
        fileManager.objectWillChange.send()
    }
}

// MARK: - View Extensions for Shared Data

extension View {
    // / Access the shared file manager service
    var sharedFileManager: FileManagerService {
        SharedDataManager.shared.fileManager
    }
}

// MARK: - Environment Key for File Manager

private struct FileManagerKey: EnvironmentKey {
    static let defaultValue: FileManagerService = SharedDataManager.shared.fileManager
}

extension EnvironmentValues {
    var fileManager: FileManagerService {
        get { self[FileManagerKey.self] }
        set { self[FileManagerKey.self] = newValue }
    }
}
