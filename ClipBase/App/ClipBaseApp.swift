import SwiftUI
import SwiftData
import WebKit
import GoogleMobileAds

@main
struct ClipBaseApp: App {
    @State private var showSplash = true

    init() {
        // AdMob SDK を初期化
        AdManager.shared.configure()

        // WebKit をバックグラウンドでプリロード（初回表示の遅延を解消）
        DispatchQueue.main.async {
            _ = WKWebView()
        }
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()

                if showSplash {
                    SplashView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .onAppear {
                // スプラッシュ画面を非表示
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        showSplash = false
                    }
                }
            }
        }
        .modelContainer(ModelContainer.shared)
    }
}
