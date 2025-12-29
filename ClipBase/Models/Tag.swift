import Foundation
import SwiftData

@Model
final class Tag {
    var id: UUID
    var name: String
    var colorHex: String
    var sortOrder: Int = 0
    var bookmarks: [VideoBookmark]

    init(
        id: UUID = UUID(),
        name: String,
        colorHex: String = "#007AFF",
        sortOrder: Int = 0,
        bookmarks: [VideoBookmark] = []
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.bookmarks = bookmarks
    }
}

extension Tag {
    static let presetColors: [String] = [
        "#FF3B30", // Red
        "#FF9500", // Orange
        "#FFCC00", // Yellow
        "#8CC63F", // Yellow-Green
        "#34C759", // Green
        "#5AC8FA", // Cyan
        "#007AFF", // Blue
        "#5856D6", // Purple
        "#FF2D55", // Pink
        "#FFFFFF", // White
        "#8E8E93", // Gray
        "#1C1C1E"  // Black
    ]
}
