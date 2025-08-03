//
// CodingReviewerApp.swift
// CodingReviewer
//
// Created by Daniel Stevens on 7/16/25.
//

import SwiftUI

@main
struct CodingReviewerApp: App {
    @StateObject private var fileManager = FileManagerService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(fileManager)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 900, height: 700)
        .commands {
            CommandGroup(replacing: .newItem) {
                // Remove default new item command
            }
        }
    }
}
