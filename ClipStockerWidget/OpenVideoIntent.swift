import AppIntents
import Foundation

struct OpenVideoIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Video"
    static var description = IntentDescription("Opens the video in its original app")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "URL")
    var urlString: String

    init() {
        self.urlString = ""
    }

    init(urlString: String) {
        self.urlString = urlString
    }

    func perform() async throws -> some IntentResult {
        // openAppWhenRun = true により、アプリが開かれる
        // アプリ側でURLを処理する
        return .result()
    }
}
