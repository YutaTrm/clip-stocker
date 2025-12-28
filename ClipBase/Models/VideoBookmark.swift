import Foundation
import SwiftData

enum Platform: String, Codable, CaseIterable {
    case youtube = "YouTube"
    case tiktok = "TikTok"
    case instagram = "Instagram"
    case twitter = "X"
    case unknown = "Unknown"

    var iconName: String {
        switch self {
        case .youtube: return "logo_youtube"
        case .tiktok: return "logo_tiktok"
        case .instagram: return "logo_instagram"
        case .twitter: return "logo_x"
        case .unknown: return "link"
        }
    }

    var isCustomIcon: Bool {
        self != .unknown
    }
}

@Model
final class VideoBookmark {
    var id: UUID
    var url: String
    var platformRaw: String
    var title: String?           // 動画の元タイトル（自動取得）
    var customTitle: String?     // ユーザーが付けたタイトル
    var thumbnailURL: String?
    @Attribute(.externalStorage) var thumbnailData: Data?
    var createdAt: Date
    @Relationship(inverse: \Tag.bookmarks) var tags: [Tag]

    var platform: Platform {
        get { Platform(rawValue: platformRaw) ?? .unknown }
        set { platformRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        url: String,
        platform: Platform,
        title: String? = nil,
        customTitle: String? = nil,
        thumbnailURL: String? = nil,
        thumbnailData: Data? = nil,
        createdAt: Date = Date(),
        tags: [Tag] = []
    ) {
        self.id = id
        self.url = url
        self.platformRaw = platform.rawValue
        self.title = title
        self.customTitle = customTitle
        self.thumbnailURL = thumbnailURL
        self.thumbnailData = thumbnailData
        self.createdAt = createdAt
        self.tags = tags
    }
}
