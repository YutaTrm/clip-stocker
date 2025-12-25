import Foundation
import SwiftData

enum AppGroup {
    static let identifier = "group.com.clipstockerapp.shared"

    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }
}

extension ModelContainer {
    static var shared: ModelContainer = {
        let schema = Schema([VideoBookmark.self, Tag.self])

        // App Groupが設定されている場合は共有コンテナを使用
        // 設定されていない場合はデフォルトの場所を使用
        let config: ModelConfiguration
        if let containerURL = AppGroup.containerURL {
            config = ModelConfiguration(
                schema: schema,
                url: containerURL.appendingPathComponent("ClipBase.store"),
                allowsSave: true
            )
        } else {
            // App Group未設定時はデフォルトストレージを使用
            config = ModelConfiguration(schema: schema, allowsSave: true)
        }

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()
}
