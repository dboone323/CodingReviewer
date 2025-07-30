//
// Item.swift
// CodingReviewer
//
// Created by Daniel Stevens on 7/16/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date

    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
