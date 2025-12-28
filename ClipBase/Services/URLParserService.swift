import Foundation

struct URLParserService {

    struct ParsedURL {
        let platform: Platform
        let videoId: String?
        let originalURL: String
    }

    static func parse(_ urlString: String) -> ParsedURL {
        guard let url = URL(string: urlString) else {
            return ParsedURL(platform: .unknown, videoId: nil, originalURL: urlString)
        }

        let host = url.host?.lowercased() ?? ""

        // YouTube / YouTube Shorts
        if host.contains("youtube.com") || host.contains("youtu.be") {
            let videoId = extractYouTubeVideoId(from: url)
            return ParsedURL(platform: .youtube, videoId: videoId, originalURL: urlString)
        }

        // TikTok
        if host.contains("tiktok.com") {
            let videoId = extractTikTokVideoId(from: url)
            return ParsedURL(platform: .tiktok, videoId: videoId, originalURL: urlString)
        }

        // Instagram Reels
        if host.contains("instagram.com") {
            let videoId = extractInstagramVideoId(from: url)
            return ParsedURL(platform: .instagram, videoId: videoId, originalURL: urlString)
        }

        // X (Twitter)
        if host.contains("twitter.com") || host.contains("x.com") {
            let videoId = extractTwitterVideoId(from: url)
            return ParsedURL(platform: .twitter, videoId: videoId, originalURL: urlString)
        }

        // Threads
        if host.contains("threads.net") || host.contains("threads.com") {
            let videoId = extractThreadsPostId(from: url)
            return ParsedURL(platform: .threads, videoId: videoId, originalURL: urlString)
        }

        return ParsedURL(platform: .unknown, videoId: nil, originalURL: urlString)
    }

    private static func extractYouTubeVideoId(from url: URL) -> String? {
        // youtu.be/VIDEO_ID
        if url.host?.contains("youtu.be") == true {
            return url.pathComponents.dropFirst().first
        }

        // youtube.com/watch?v=VIDEO_ID
        if let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems {
            if let videoId = queryItems.first(where: { $0.name == "v" })?.value {
                return videoId
            }
        }

        // youtube.com/shorts/VIDEO_ID
        if url.pathComponents.contains("shorts") {
            if let index = url.pathComponents.firstIndex(of: "shorts"),
               index + 1 < url.pathComponents.count {
                return url.pathComponents[index + 1]
            }
        }

        return nil
    }

    private static func extractTikTokVideoId(from url: URL) -> String? {
        // tiktok.com/@user/video/VIDEO_ID
        if let index = url.pathComponents.firstIndex(of: "video"),
           index + 1 < url.pathComponents.count {
            return url.pathComponents[index + 1]
        }

        // vm.tiktok.com/SHORT_ID
        if url.host?.contains("vm.tiktok.com") == true {
            return url.pathComponents.dropFirst().first
        }

        return nil
    }

    private static func extractInstagramVideoId(from url: URL) -> String? {
        // instagram.com/reel/VIDEO_ID or instagram.com/reels/VIDEO_ID
        if url.pathComponents.contains("reel") || url.pathComponents.contains("reels") {
            let reelIndex = url.pathComponents.firstIndex(of: "reel") ?? url.pathComponents.firstIndex(of: "reels")
            if let index = reelIndex, index + 1 < url.pathComponents.count {
                return url.pathComponents[index + 1]
            }
        }

        return nil
    }

    private static func extractTwitterVideoId(from url: URL) -> String? {
        // x.com/{username}/status/{id} or twitter.com/{username}/status/{id}
        if let index = url.pathComponents.firstIndex(of: "status"),
           index + 1 < url.pathComponents.count {
            return url.pathComponents[index + 1]
        }

        return nil
    }

    private static func extractThreadsPostId(from url: URL) -> String? {
        // threads.net/@username/post/POST_ID
        if let index = url.pathComponents.firstIndex(of: "post"),
           index + 1 < url.pathComponents.count {
            return url.pathComponents[index + 1]
        }

        return nil
    }
}
