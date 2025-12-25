//
//  ShareViewController.swift
//  ClipBaseShareExtension
//

import UIKit
import SwiftData
import UniformTypeIdentifiers

class ShareViewController: UIViewController {

    private var hasProcessed = false

    override func viewDidLoad() {
        super.viewDidLoad()
        // ビューを透明にして見えないようにする
        view.backgroundColor = .clear
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // 重複処理を防ぐ
        guard !hasProcessed else { return }
        hasProcessed = true

        // シェアシートのアニメーション完了を待ってから処理
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.processShareInput()
        }
    }

    private func processShareInput() {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let itemProviders = extensionItem.attachments else {
            completeRequest()
            return
        }

        for provider in itemProviders {
            // URL として共有された場合
            if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.url.identifier) { [weak self] item, error in
                    DispatchQueue.main.async {
                        if let url = item as? URL {
                            self?.saveBookmark(url: url.absoluteString)
                        }
                        self?.completeRequest()
                    }
                }
                return
            }

            // テキストとして共有された場合（一部アプリはURLをテキストで共有）
            if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) { [weak self] item, error in
                    DispatchQueue.main.async {
                        if let text = item as? String, let url = URL(string: text), url.scheme != nil {
                            self?.saveBookmark(url: text)
                        }
                        self?.completeRequest()
                    }
                }
                return
            }
        }

        completeRequest()
    }

    private func saveBookmark(url: String) {
        let parsed = URLParserService.parse(url)

        // YouTube, TikTok, Instagram のみ保存
        guard parsed.platform != .unknown else { return }

        let bookmark = VideoBookmark(
            url: parsed.originalURL,
            platform: parsed.platform
        )

        do {
            let context = ModelContext(ModelContainer.shared)
            context.insert(bookmark)
            try context.save()
        } catch {
            print("Failed to save bookmark: \(error)")
        }
    }

    private func completeRequest() {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
}
