import Foundation
import SwiftData

@Model
final class Tag {
    var id: UUID
    var name: String
    var colorHex: String
    var bookmarks: [VideoBookmark]

    init(
        id: UUID = UUID(),
        name: String,
        colorHex: String = "#007AFF",
        bookmarks: [VideoBookmark] = []
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.bookmarks = bookmarks
    }
}

extension Tag {
    static let presetColors: [String] = [
        "#FF3B30", // Red
        "#FF9500", // Orange
        "#FFCC00", // Yellow
        "#34C759", // Green
        "#007AFF", // Blue
        "#5856D6", // Purple
        "#AF52DE", // Violet
        "#FF2D55"  // Pink
    ]
}
