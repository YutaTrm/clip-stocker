import WidgetKit
import SwiftUI
import SwiftData
import AppIntents

struct ClipStockerWidget: Widget {
    let kind: String = "ClipStockerWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ClipStockerWidgetIntent.self, provider: Provider()) { entry in
            WidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("ClipStocker")
        .description("最新の保存動画を表示")
        .supportedFamilies([.systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

struct Provider: AppIntentTimelineProvider {
    private let container: ModelContainer
    private let initStatus: String

    init() {
        // Widget専用: App Groupの共有コンテナを直接指定
        let schema = Schema([VideoBookmark.self, Tag.self])
        let appGroupID = "group.com.clipstockerapp.shared"

        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            let storeURL = containerURL.appendingPathComponent("ClipBase.store")
            let config = ModelConfiguration(schema: schema, url: storeURL, allowsSave: false)
            do {
                self.container = try ModelContainer(for: schema, configurations: [config])
                self.initStatus = "OK"
            } catch {
                self.container = ModelContainer.shared
                self.initStatus = "InitErr:\(error.localizedDescription.prefix(20))"
            }
        } else {
            self.container = ModelContainer.shared
            self.initStatus = "NoAppGroup"
        }
    }

    func placeholder(in context: Context) -> WidgetEntry {
        WidgetEntry(date: Date(), bookmarks: sampleBookmarks())
    }

    func snapshot(for configuration: ClipStockerWidgetIntent, in context: Context) async -> WidgetEntry {
        if context.isPreview {
            return WidgetEntry(date: Date(), bookmarks: sampleBookmarks())
        } else {
            return fetchEntry(for: configuration)
        }
    }

    private func sampleBookmarks() -> [WidgetBookmarkItem] {
        return [
            WidgetBookmarkItem(id: UUID(), url: "https://youtube.com", platform: .youtube, title: "Sample 1", thumbnailData: nil),
            WidgetBookmarkItem(id: UUID(), url: "https://tiktok.com", platform: .tiktok, title: "Sample 2", thumbnailData: nil),
            WidgetBookmarkItem(id: UUID(), url: "https://instagram.com", platform: .instagram, title: "Sample 3", thumbnailData: nil),
            WidgetBookmarkItem(id: UUID(), url: "https://x.com", platform: .twitter, title: "Sample 4", thumbnailData: nil),
        ]
    }

    func timeline(for configuration: ClipStockerWidgetIntent, in context: Context) async -> Timeline<WidgetEntry> {
        let entry = fetchEntry(for: configuration)
        // 15分ごとに更新
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    private func fetchEntry(for configuration: ClipStockerWidgetIntent) -> WidgetEntry {
        let context = ModelContext(container)
        let selectedTagId = configuration.selectedTag.id

        do {
            // 全件取得して後でフィルター
            var descriptor = FetchDescriptor<VideoBookmark>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            let allBookmarks = try context.fetch(descriptor)

            var filteredBookmarks: [VideoBookmark]
            if selectedTagId == "all" {
                filteredBookmarks = allBookmarks
            } else if let tagUUID = UUID(uuidString: selectedTagId) {
                // メモリ上でタグフィルター
                filteredBookmarks = allBookmarks.filter { bookmark in
                    bookmark.tags.contains { $0.id == tagUUID }
                }
            } else {
                filteredBookmarks = allBookmarks
            }

            // 30件に制限
            let limitedBookmarks = Array(filteredBookmarks.prefix(30))

            let items = limitedBookmarks.map { bookmark in
                WidgetBookmarkItem(
                    id: bookmark.id,
                    url: bookmark.url,
                    platform: bookmark.platform,
                    title: bookmark.customTitle ?? bookmark.title,
                    thumbnailData: bookmark.thumbnailData
                )
            }
            return WidgetEntry(date: Date(), bookmarks: items, tagName: configuration.selectedTag.name)
        } catch {
            return WidgetEntry(date: Date(), bookmarks: [])
        }
    }
}

#Preview(as: .systemMedium) {
    ClipStockerWidget()
} timeline: {
    WidgetEntry(date: .now, bookmarks: [])
}

#Preview(as: .systemLarge) {
    ClipStockerWidget()
} timeline: {
    WidgetEntry(date: .now, bookmarks: [])
}
