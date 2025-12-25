import Foundation
import SwiftUI
import SwiftData

@Observable
final class VideoBookmarkViewModel {
    var searchText: String = ""
    var selectedTag: Tag?
    var showingAddSheet: Bool = false
    var showingTagManager: Bool = false

    func addBookmark(url: String, customTitle: String? = nil, context: ModelContext) async {
        let parsed = URLParserService.parse(url)
        let bookmark = VideoBookmark(
            url: parsed.originalURL,
            platform: parsed.platform,
            customTitle: customTitle  // ユーザーが付けたタイトル
        )

        context.insert(bookmark)

        // サムネイルと元タイトルを取得
        let metadata = await ThumbnailService.shared.fetchMetadata(for: bookmark)
        bookmark.thumbnailData = metadata.thumbnailData
        bookmark.title = metadata.title  // 動画の元タイトル

        try? context.save()
    }

    func deleteBookmark(_ bookmark: VideoBookmark, context: ModelContext) {
        context.delete(bookmark)
        try? context.save()
    }

    func filteredBookmarks(_ bookmarks: [VideoBookmark]) -> [VideoBookmark] {
        var result = bookmarks

        // Filter by search text
        if !searchText.isEmpty {
            result = result.filter { bookmark in
                bookmark.url.localizedCaseInsensitiveContains(searchText) ||
                (bookmark.title?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (bookmark.customTitle?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        // Filter by selected tag
        if let tag = selectedTag {
            result = result.filter { $0.tags.contains { $0.id == tag.id } }
        }

        return result.sorted { $0.createdAt > $1.createdAt }
    }
}
