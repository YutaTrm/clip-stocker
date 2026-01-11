import AppIntents
import WidgetKit
import SwiftData

// MARK: - Tag Entity for Widget Configuration

struct TagEntity: AppEntity {
    var id: String
    var name: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "タグ"
    static var defaultQuery = TagEntityQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    // 「すべて」を表す特別なエンティティ
    static let all = TagEntity(id: "all", name: "すべて")
}

// MARK: - Tag Entity Query

struct TagEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [TagEntity] {
        let allTags = fetchTags()

        return identifiers.compactMap { id in
            if id == "all" {
                return TagEntity.all
            }
            return allTags.first { $0.id == id }
        }
    }

    func suggestedEntities() async throws -> [TagEntity] {
        // Pro限定: 非Proユーザーは「すべて」のみ
        guard isPro else {
            return [TagEntity.all]
        }
        var results = [TagEntity.all]
        results.append(contentsOf: fetchTags())
        return results
    }

    func defaultResult() async -> TagEntity? {
        return TagEntity.all
    }

    private var isPro: Bool {
        let defaults = UserDefaults(suiteName: "group.com.clipstockerapp.shared")
        return defaults?.bool(forKey: "isPro") ?? false
    }

    private func fetchTags() -> [TagEntity] {
        let schema = Schema([VideoBookmark.self, Tag.self])
        let appGroupID = "group.com.clipstockerapp.shared"

        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            return []
        }

        let storeURL = containerURL.appendingPathComponent("ClipBase.store")
        let config = ModelConfiguration(schema: schema, url: storeURL, allowsSave: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            let context = ModelContext(container)
            let descriptor = FetchDescriptor<Tag>(sortBy: [SortDescriptor(\.sortOrder)])
            let tags = try context.fetch(descriptor)

            return tags.map { tag in
                TagEntity(id: tag.id.uuidString, name: tag.name)
            }
        } catch {
            return []
        }
    }
}

// MARK: - Widget Configuration Intent

struct ClipStockerWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "ClipStocker設定"
    static var description = IntentDescription("表示するタグを選択")

    @Parameter(title: "タグ")
    var selectedTag: TagEntity?

    init() {}

    var resolvedTag: TagEntity {
        selectedTag ?? TagEntity.all
    }
}
