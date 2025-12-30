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

    private(set) var nativeAds: [NativeAd] = []
    private var adLoader: AdLoader?
    private(set) var isAdLoaded = false
    private var isLoading = false

    // 読み込む広告の数
    private let numberOfAdsToLoad = 5

    private override init() {
        super.init()
    }

    func configure() {
        MobileAds.shared.start { status in
            print("AdMob SDK initialized: \(status.adapterStatusesByClassName)")
        }
    }

    /// 指定インデックスの広告を取得
    func nativeAd(at index: Int) -> NativeAd? {
        guard !nativeAds.isEmpty else { return nil }
        return nativeAds[index % nativeAds.count]
    }

    func loadNativeAds(rootViewController: UIViewController) {
        // 既にロード中 or ロード済みの場合はスキップ
        guard !isLoading && !isAdLoaded else { return }
        isLoading = true

        let mediaOptions = NativeAdMediaAdLoaderOptions()
        mediaOptions.mediaAspectRatio = .portrait

        // 動画広告の自動再生を無効化（スクロール時の問題を回避）
        let videoOptions = VideoOptions()
        videoOptions.shouldStartMuted = true
        videoOptions.isClickToExpandRequested = true

        // 複数の広告を読み込む
        let multipleAdsOptions = MultipleAdsAdLoaderOptions()
        multipleAdsOptions.numberOfAds = numberOfAdsToLoad

        adLoader = AdLoader(
            adUnitID: nativeAdUnitID,
            rootViewController: rootViewController,
            adTypes: [.native],
            options: [mediaOptions, videoOptions, multipleAdsOptions]
        )
        adLoader?.delegate = self
        adLoader?.load(Request())
    }

    func clearAds() {
        nativeAds.removeAll()
        isAdLoaded = false
        isLoading = false
    }
}

// MARK: - NativeAdLoaderDelegate
extension AdManager: NativeAdLoaderDelegate {
    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        nativeAds.append(nativeAd)
        print("Native ad loaded: \(nativeAds.count)")
    }

    func adLoaderDidFinishLoading(_ adLoader: AdLoader) {
        isAdLoaded = !nativeAds.isEmpty
        isLoading = false
        print("Finished loading \(nativeAds.count) native ads")
    }

    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        print("Native ad failed to load: \(error.localizedDescription)")
        isLoading = false
        if nativeAds.isEmpty {
            isAdLoaded = false
        }
    }
}
