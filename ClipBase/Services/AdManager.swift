import Foundation
import GoogleMobileAds

@Observable
final class AdManager: NSObject {
    static let shared = AdManager()

    #if DEBUG
    // テスト用広告ユニットID
    private let nativeAdUnitID = "ca-app-pub-3940256099942544/3986624511"
    #else
    // 本番用広告ユニットID
    private let nativeAdUnitID = "ca-app-pub-8595003034177265/2186527599"
    #endif

    private(set) var nativeAd: NativeAd?
    private var adLoader: AdLoader?
    private(set) var isAdLoaded = false
    private var isLoading = false

    private override init() {
        super.init()
    }

    func configure() {
        MobileAds.shared.start { status in
            print("AdMob SDK initialized: \(status.adapterStatusesByClassName)")
        }
    }

    func loadNativeAd(rootViewController: UIViewController) {
        // 既にロード中 or ロード済みの場合はスキップ
        guard !isLoading && !isAdLoaded else { return }
        isLoading = true

        let options = NativeAdMediaAdLoaderOptions()
        options.mediaAspectRatio = .portrait

        adLoader = AdLoader(
            adUnitID: nativeAdUnitID,
            rootViewController: rootViewController,
            adTypes: [.native],
            options: [options]
        )
        adLoader?.delegate = self
        adLoader?.load(Request())
    }

    func clearAd() {
        nativeAd = nil
        isAdLoaded = false
        isLoading = false
    }
}

// MARK: - NativeAdLoaderDelegate
extension AdManager: NativeAdLoaderDelegate {
    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        self.nativeAd = nativeAd
        self.isAdLoaded = true
        self.isLoading = false
        print("Native ad loaded successfully")
    }

    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        print("Native ad failed to load: \(error.localizedDescription)")
        self.isAdLoaded = false
        self.isLoading = false
    }
}
