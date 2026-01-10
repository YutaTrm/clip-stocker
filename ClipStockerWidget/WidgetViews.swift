import SwiftUI
import WidgetKit
import UIKit

struct WidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: WidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(bookmarks: entry.bookmarks)
        case .systemMedium:
            MediumWidgetView(bookmarks: entry.bookmarks)
        case .systemLarge:
            LargeWidgetView(bookmarks: entry.bookmarks)
        default:
            MediumWidgetView(bookmarks: entry.bookmarks)
        }
    }
}

// MARK: - Small Widget (2 thumbnails)

struct SmallWidgetView: View {
    let bookmarks: [WidgetBookmarkItem]

    var body: some View {
        if bookmarks.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.title)
                    .foregroundStyle(.secondary)
                Text("動画を保存してね")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            HStack(spacing: 6) {
                ForEach(bookmarks.prefix(2)) { bookmark in
                    Link(destination: makeURL(for: bookmark)) {
                        SmallThumbnailCard(bookmark: bookmark)
                    }
                }

                // 2件未満の場合はプレースホルダー
                if bookmarks.count < 2 {
                    ForEach(0..<(2 - bookmarks.count), id: \.self) { _ in
                        placeholderCard
                    }
                }
            }
            .padding(8)
        }
    }

    private func makeURL(for bookmark: WidgetBookmarkItem) -> URL {
        let encodedURL = bookmark.url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "clipstocker://open?url=\(encodedURL)") ?? URL(string: "clipstocker://")!
    }

    private var placeholderCard: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(.systemGray5))
            .aspectRatio(9/16, contentMode: .fit)
            .overlay {
                Image(systemName: "plus")
                    .foregroundStyle(.secondary)
            }
    }
}

struct SmallThumbnailCard: View {
    let bookmark: WidgetBookmarkItem

    var body: some View {
        ZStack {
            if let data = bookmark.thumbnailData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                platformGradient(for: bookmark.platform)
            }

            VStack {
                HStack {
                    Spacer()
                    platformBadge(for: bookmark.platform)
                        .padding(4)
                }
                Spacer()
            }
        }
        .aspectRatio(9/16, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Medium Widget (4 thumbnails)

struct MediumWidgetView: View {
    let bookmarks: [WidgetBookmarkItem]

    var body: some View {
        if bookmarks.isEmpty {
            emptyState
        } else {
            HStack(spacing: 6) {
                ForEach(bookmarks.prefix(4)) { bookmark in
                    Link(destination: makeURL(for: bookmark)) {
                        MediumThumbnailCard(bookmark: bookmark)
                    }
                }

                // 4件未満の場合はプレースホルダー
                if bookmarks.count < 4 {
                    ForEach(0..<(4 - bookmarks.count), id: \.self) { _ in
                        placeholderCard
                    }
                }
            }
            .padding(.horizontal, 12)
        }
    }

    private func makeURL(for bookmark: WidgetBookmarkItem) -> URL {
        let encodedURL = bookmark.url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "clipstocker://open?url=\(encodedURL)") ?? URL(string: "clipstocker://")!
    }

    private var placeholderCard: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(.systemGray5))
            .aspectRatio(9/16, contentMode: .fit)
            .overlay {
                Image(systemName: "plus")
                    .foregroundStyle(.secondary)
            }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("動画を保存してね")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct MediumThumbnailCard: View {
    let bookmark: WidgetBookmarkItem

    var body: some View {
        ZStack {
            if let data = bookmark.thumbnailData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                platformGradient(for: bookmark.platform)
            }

            VStack {
                HStack {
                    Spacer()
                    platformBadge(for: bookmark.platform)
                        .padding(4)
                }
                Spacer()
            }
        }
        .aspectRatio(9/16, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Large Widget (8 thumbnails, 2×4 grid)

struct LargeWidgetView: View {
    let bookmarks: [WidgetBookmarkItem]

    private func row(_ index: Int) -> [WidgetBookmarkItem] {
        Array(bookmarks.dropFirst(index * 6).prefix(6))
    }

    var body: some View {
        if bookmarks.isEmpty {
            emptyState
        } else {
            VStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { rowIndex in
                    thumbnailRow(items: row(rowIndex), totalSlots: 6)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
    }

    private func thumbnailRow(items: [WidgetBookmarkItem], totalSlots: Int) -> some View {
        HStack(spacing: 6) {
            ForEach(items) { bookmark in
                Link(destination: makeURL(for: bookmark)) {
                    LargeThumbnailCard(bookmark: bookmark)
                }
            }

            if items.count < totalSlots {
                ForEach(0..<(totalSlots - items.count), id: \.self) { _ in
                    placeholderCard
                }
            }
        }
    }

    private func makeURL(for bookmark: WidgetBookmarkItem) -> URL {
        let encodedURL = bookmark.url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "clipstocker://open?url=\(encodedURL)") ?? URL(string: "clipstocker://")!
    }

    private var placeholderCard: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(.systemGray5))
            .aspectRatio(9/16, contentMode: .fit)
            .overlay {
                Image(systemName: "plus")
                    .foregroundStyle(.secondary)
            }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("動画を保存してね")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct LargeThumbnailCard: View {
    let bookmark: WidgetBookmarkItem

    var body: some View {
        Group {
            if let data = bookmark.thumbnailData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            } else {
                platformGradient(for: bookmark.platform)
            }
        }
        .aspectRatio(3/4, contentMode: .fit)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Helpers

private func platformBadge(for platform: Platform) -> some View {
    Group {
        if platform.isCustomIcon {
            Image(platform.iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 12, height: 12)
        } else {
            Image(systemName: platform.iconName)
                .font(.system(size: 10))
        }
    }
    .padding(3)
    .background(Color(.systemBackground).opacity(0.9))
    .clipShape(Circle())
}

private func platformGradient(for platform: Platform) -> LinearGradient {
    switch platform {
    case .youtube:
        return LinearGradient(
            colors: [.red, .red.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    case .tiktok:
        return LinearGradient(
            colors: [.black, .pink.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    case .instagram:
        return LinearGradient(
            colors: [.purple, .pink, .orange],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    case .twitter:
        return LinearGradient(
            colors: [.black, .gray],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    case .threads:
        return LinearGradient(
            colors: [.black, .gray.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    case .unknown:
        return LinearGradient(
            colors: [.gray, .gray.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
