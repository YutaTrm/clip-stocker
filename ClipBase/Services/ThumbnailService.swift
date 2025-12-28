import Foundation
import UIKit
import LinkPresentation

struct VideoMetadata {
    let title: String?
    let thumbnailData: Data?
}

actor ThumbnailService {
    static let shared = ThumbnailService()

    private var cache: [String: Data] = [:]

    /// タイトルとサムネイルを同時に取得
    func fetchMetadata(for bookmark: VideoBookmark) async -> VideoMetadata {
        let parsed = URLParserService.parse(bookmark.url)

        switch parsed.platform {
        case .youtube:
            return await fetchYouTubeMetadata(videoId: parsed.videoId, url: bookmark.url)
        case .tiktok:
            return await fetchTikTokMetadata(bookmark.url)
        case .instagram:
            return await fetchInstagramMetadata(bookmark.url)
        case .twitter:
            return await fetchTwitterMetadata(bookmark.url)
        case .threads:
            return await fetchThreadsMetadata(bookmark.url)
        case .unknown:
            return VideoMetadata(title: nil, thumbnailData: nil)
        }
    }

    // MARK: - YouTube

    private func fetchYouTubeMetadata(videoId: String?, url: String) async -> VideoMetadata {
        guard let videoId = videoId else {
            return VideoMetadata(title: nil, thumbnailData: nil)
        }

        // oEmbed APIでタイトルを取得
        let title = await fetchYouTubeTitle(videoId: videoId)

        // Shorts用の縦長サムネイルを試す（利用可能な場合）
        let shortsThumbnailURLs = [
            "https://i.ytimg.com/vi/\(videoId)/oardefault.jpg",  // Shorts縦長
            "https://i.ytimg.com/vi/\(videoId)/oar2.jpg",        // Shorts縦長 代替
            "https://img.youtube.com/vi/\(videoId)/hqdefault.jpg" // フォールバック
        ]

        var thumbnailData: Data?
        for thumbnailURL in shortsThumbnailURLs {
            if let data = await fetchImageData(from: thumbnailURL, cacheKey: url) {
                thumbnailData = data
                break
            }
        }

        return VideoMetadata(title: title, thumbnailData: thumbnailData)
    }

    private func fetchYouTubeTitle(videoId: String) async -> String? {
        let urlString = "https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=\(videoId)&format=json"
        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            return json?["title"] as? String
        } catch {
            print("Failed to fetch YouTube title: \(error)")
            return nil
        }
    }

    // MARK: - TikTok

    private func fetchTikTokMetadata(_ videoURL: String) async -> VideoMetadata {
        guard let encodedURL = videoURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let oembedURL = URL(string: "https://www.tiktok.com/oembed?url=\(encodedURL)") else {
            return VideoMetadata(title: nil, thumbnailData: nil)
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: oembedURL)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

            let title = json?["title"] as? String
            let thumbnailURLString = json?["thumbnail_url"] as? String

            var thumbnailData: Data?
            if let thumbURL = thumbnailURLString {
                thumbnailData = await fetchImageData(from: thumbURL, cacheKey: videoURL)
            }

            return VideoMetadata(title: title, thumbnailData: thumbnailData)
        } catch {
            print("Failed to fetch TikTok oEmbed: \(error)")
            return VideoMetadata(title: nil, thumbnailData: nil)
        }
    }

    // MARK: - Instagram

    private func fetchInstagramMetadata(_ videoURL: String) async -> VideoMetadata {
        return await fetchLinkMetadata(videoURL)
    }

    // MARK: - Twitter (X)

    private func fetchTwitterMetadata(_ videoURL: String) async -> VideoMetadata {
        return await fetchLinkMetadata(videoURL)
    }

    // MARK: - Threads

    private func fetchThreadsMetadata(_ videoURL: String) async -> VideoMetadata {
        return await fetchLinkMetadata(videoURL)
    }

    // MARK: - LPMetadataProvider (Instagram / Twitter / Threads)

    private func fetchLinkMetadata(_ videoURL: String) async -> VideoMetadata {
        guard let url = URL(string: videoURL) else {
            return VideoMetadata(title: nil, thumbnailData: nil)
        }

        return await withCheckedContinuation { continuation in
            let provider = LPMetadataProvider()
            provider.startFetchingMetadata(for: url) { metadata, error in
                Task {
                    if let error = error {
                        print("LPMetadataProvider error: \(error)")
                        continuation.resume(returning: VideoMetadata(title: nil, thumbnailData: nil))
                        return
                    }

                    guard let metadata = metadata else {
                        continuation.resume(returning: VideoMetadata(title: nil, thumbnailData: nil))
                        return
                    }

                    let title = metadata.title

                    // サムネイル画像を取得
                    var thumbnailData: Data?
                    if let imageProvider = metadata.imageProvider {
                        thumbnailData = await self.loadImageData(from: imageProvider)
                    }

                    continuation.resume(returning: VideoMetadata(title: title, thumbnailData: thumbnailData))
                }
            }
        }
    }

    private func loadImageData(from provider: NSItemProvider) async -> Data? {
        return await withCheckedContinuation { continuation in
            provider.loadObject(ofClass: UIImage.self) { image, error in
                if let uiImage = image as? UIImage,
                   let data = uiImage.jpegData(compressionQuality: 0.8) {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    // MARK: - Helper

    private func fetchImageData(from urlString: String, cacheKey: String) async -> Data? {
        if let cachedData = cache[cacheKey] {
            return cachedData
        }

        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            cache[cacheKey] = data
            return data
        } catch {
            print("Failed to fetch image: \(error)")
            return nil
        }
    }

    func clearCache() {
        cache.removeAll()
    }
}
