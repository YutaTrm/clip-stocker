import WidgetKit
import SwiftUI
import SwiftData

struct ClipStockerWidget: Widget {
    let kind: String = "ClipStockerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("ClipStocker")
        .description("最新の保存動画を表示")
        .supportedFamilies([.systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

struct Provider: TimelineProvider {
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
        WidgetEntry(date: Date(), bookmarks: sampleBookmarks(), debugMessage: "Placeholder")
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> ()) {
        if context.isPreview {
            // プレビュー用サンプルデータ
            completion(WidgetEntry(date: Date(), bookmarks: sampleBookmarks(), debugMessage: "Preview"))
        } else {
            let entry = fetchEntry()
            completion(entry)
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

    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetEntry>) -> ()) {
        let entry = fetchEntry()
        // 15分ごとに更新
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func fetchEntry() -> WidgetEntry {
        let context = ModelContext(container)
        var descriptor = FetchDescriptor<VideoBookmark>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = 30

        do {
            let bookmarks = try context.fetch(descriptor)
            let items = bookmarks.map { bookmark in
                WidgetBookmarkItem(
                    id: bookmark.id,
                    url: bookmark.url,
                    platform: bookmark.platform,
                    title: bookmark.customTitle ?? bookmark.title,
                    thumbnailData: bookmark.thumbnailData
                )
            }
            return WidgetEntry(date: Date(), bookmarks: items, debugMessage: "[\(initStatus)] \(bookmarks.count)件")
        } catch {
            return WidgetEntry(date: Date(), bookmarks: [], debugMessage: "[\(initStatus)] Err")
        }
    }
}

#Preview(as: .systemSmall) {
    ClipStockerWidget()
} timeline: {
    WidgetEntry(date: .now, bookmarks: [])
}

#Preview(as: .systemMedium) {
    ClipStockerWidget()
} timeline: {
    WidgetEntry(date: .now, bookmarks: [])
}
