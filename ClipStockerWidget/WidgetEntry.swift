import WidgetKit
import Foundation

struct WidgetEntry: TimelineEntry {
    let date: Date
    let bookmarks: [WidgetBookmarkItem]
    var tagName: String = "すべて"
}

struct WidgetBookmarkItem: Identifiable {
    let id: UUID
    let url: String
    let platform: Platform
    let title: String?
    let thumbnailData: Data?
}
