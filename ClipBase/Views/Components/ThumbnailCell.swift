import SwiftUI

struct ThumbnailCell: View {
    @Bindable var bookmark: VideoBookmark
    var showTitle: Bool = true
    @State private var thumbnailImage: UIImage?
    @State private var isLoading = true
    @State private var cachedImage: UIImage?

    var body: some View {
        ZStack {
            if let image = thumbnailImage ?? cachedImage {
                // アスペクト比を維持しながらフレームを埋める（CSS background-size: cover と同じ）
                Color.clear
                    .aspectRatio(9/16, contentMode: .fit)
                    .overlay {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    }
                    .clipped()
            } else {
                // サムネイルがない場合はプラットフォーム別のグラデーション背景
                Rectangle()
                    .fill(platformGradient)
                    .aspectRatio(9/16, contentMode: .fill)
                    .overlay {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(bookmark.platform.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.white.opacity(0.9))
                        }
                    }
            }

            // オーバーレイ: バッジ（右上）、タイトル（下部）
            VStack {
                HStack {
                    Spacer()
                    PlatformBadge(platform: bookmark.platform)
                        .padding(6)
                }
                Spacer()

                // タイトル（下部オーバーレイ）
                if showTitle, let title = displayTitle {
                    Text(title)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            LinearGradient(
                                colors: [.clear, .black.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .contentShape(Rectangle()) // タップ領域を全体に拡張
        .task {
            // 既存のサムネイルデータからキャッシュ画像を生成
            if cachedImage == nil, let data = bookmark.thumbnailData {
                cachedImage = UIImage(data: data)
            }
            await loadThumbnail()
        }
        .onChange(of: bookmark.thumbnailData) { _, newData in
            // サムネイルデータが更新されたらキャッシュを更新
            if let data = newData {
                cachedImage = UIImage(data: data)
            }
        }
    }

    // 表示するタイトル（カスタム優先、なければ自動取得）
    private var displayTitle: String? {
        if let customTitle = bookmark.customTitle, !customTitle.isEmpty {
            return customTitle
        }
        if let title = bookmark.title, !title.isEmpty {
            return title
        }
        return nil
    }

    private var platformGradient: LinearGradient {
        switch bookmark.platform {
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

    private func loadThumbnail() async {
        // 既にサムネイルがあれば何もしない
        if bookmark.thumbnailData != nil {
            isLoading = false
            return
        }

        let metadata = await ThumbnailService.shared.fetchMetadata(for: bookmark)
        if let data = metadata.thumbnailData, let image = UIImage(data: data) {
            thumbnailImage = image
            bookmark.thumbnailData = data
        }
        if let title = metadata.title {
            bookmark.title = title
        }
        isLoading = false
    }
}

struct PlatformBadge: View {
    let platform: Platform

    var body: some View {
        Group {
            if platform.isCustomIcon {
                Image(platform.iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)
            } else {
                Image(systemName: platform.iconName)
                    .font(.system(size: 14))
            }
        }
        .padding(2)
        .background(Color(.systemBackground).opacity(0.9))
        .clipShape(Circle())
    }
}

#Preview {
    ThumbnailCell(bookmark: VideoBookmark(
        url: "https://youtube.com/shorts/test",
        platform: .youtube
    ))
    .frame(width: 120)
}
