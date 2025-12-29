//
//  ShareViewController.swift
//  ClipBaseShareExtension
//

import UIKit
import SwiftUI
import SwiftData
import UniformTypeIdentifiers

class ShareViewController: UIViewController {

    private var hasProcessed = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        makeBackgroundTransparent()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        makeBackgroundTransparent()

        guard !hasProcessed else { return }
        hasProcessed = true

        processShareInput()
    }

    private func makeBackgroundTransparent() {
        // 全ての親ビューを透明に
        func clearBackground(_ view: UIView?) {
            guard let view = view else { return }
            view.backgroundColor = .clear
            view.isOpaque = false
            for subview in view.subviews {
                if subview != self.view && String(describing: type(of: subview)).contains("Dimming") {
                    subview.alpha = 0
                }
            }
            clearBackground(view.superview)
        }
        clearBackground(view)

        // ウィンドウレベルで背景を透明に
        view.window?.backgroundColor = .clear
        presentationController?.containerView?.backgroundColor = .clear

        // 角丸の背景ビューを探して透明に
        if let containerView = presentationController?.containerView {
            for subview in containerView.subviews {
                if subview != view {
                    subview.backgroundColor = .clear
                    subview.isHidden = true
                }
            }
        }
    }

    private func processShareInput() {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let itemProviders = extensionItem.attachments else {
            completeRequest()
            return
        }

        // URLを探す
        for provider in itemProviders {
            if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.url.identifier) { [weak self] item, error in
                    DispatchQueue.main.async {
                        if let url = item as? URL {
                            self?.showTagSelection(for: url.absoluteString)
                        } else {
                            self?.completeRequest()
                        }
                    }
                }
                return
            }
        }

        // テキストからURLを探す
        for provider in itemProviders {
            if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) { [weak self] item, error in
                    DispatchQueue.main.async {
                        if let text = item as? String,
                           let extractedURL = self?.extractURL(from: text) {
                            self?.showTagSelection(for: extractedURL)
                        } else {
                            self?.completeRequest()
                        }
                    }
                }
                return
            }
        }

        completeRequest()
    }

    private func extractURL(from text: String) -> String? {
        if let url = URL(string: text.trimmingCharacters(in: .whitespacesAndNewlines)),
           url.scheme?.hasPrefix("http") == true {
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let range = NSRange(text.startIndex..., in: text)
        if let match = detector?.firstMatch(in: text, options: [], range: range),
           let url = match.url {
            return url.absoluteString
        }

        return nil
    }

    private func showTagSelection(for url: String) {
        let parsed = URLParserService.parse(url)

        // 対応プラットフォームでない場合は保存せず終了
        guard parsed.platform != .unknown else {
            completeRequest()
            return
        }

        let contentView = ShareContentView(
            url: url,
            platform: parsed.platform,
            onSave: { [weak self] selectedTagIds in
                self?.saveBookmark(url: url, platform: parsed.platform, tagIds: selectedTagIds)
                self?.completeRequest()
            },
            onCancel: { [weak self] in
                self?.completeRequest()
            }
        )

        let hostingController = UIHostingController(rootView: contentView)
        hostingController.view.backgroundColor = .systemBackground
        hostingController.view.layer.cornerRadius = 16
        hostingController.view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        hostingController.view.layer.masksToBounds = true

        addChild(hostingController)

        // 固定の高さで下部に配置
        let sheetHeight: CGFloat = 320

        hostingController.view.frame = CGRect(
            x: 0,
            y: view.bounds.height - sheetHeight,
            width: view.bounds.width,
            height: sheetHeight
        )
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]

        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
    }

    private func saveBookmark(url: String, platform: Platform, tagIds: Set<UUID>) {
        let bookmark = VideoBookmark(
            url: url,
            platform: platform
        )

        do {
            let context = ModelContext(ModelContainer.shared)

            // 選択されたタグを取得して関連付け
            if !tagIds.isEmpty {
                let descriptor = FetchDescriptor<Tag>()
                let allTags = try context.fetch(descriptor)
                let selectedTags = allTags.filter { tagIds.contains($0.id) }
                bookmark.tags = selectedTags
            }

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

// MARK: - SwiftUI Views

struct ShareContentView: View {
    let url: String
    let platform: Platform
    let onSave: (Set<UUID>) -> Void
    let onCancel: () -> Void

    @State private var tags: [Tag] = []
    @State private var selectedTagIds: Set<UUID> = []

    var body: some View {
        VStack(spacing: 0) {
            // Grabber
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color(.systemGray3))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 4)

            // Header
            HStack {
                Button("Cancel") { onCancel() }
                    .foregroundStyle(.primary)
                Spacer()
                Text("Save Video")
                    .font(.headline)
                Spacer()
                Button("Save") { onSave(selectedTagIds) }
                    .fontWeight(.semibold)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            // Content (scrollable)
            ScrollView {
                VStack(spacing: 12) {
                    // Platform
                    HStack(spacing: 10) {
                        platformIcon
                            .frame(width: 22, height: 22)
                        Text(platform.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    .padding(10)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    // Tags
                    if !tags.isEmpty {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 6) {
                            ForEach(tags, id: \.id) { tag in
                                TagChip(
                                    tag: tag,
                                    isSelected: selectedTagIds.contains(tag.id),
                                    onTap: {
                                        if selectedTagIds.contains(tag.id) {
                                            selectedTagIds.remove(tag.id)
                                        } else {
                                            selectedTagIds.insert(tag.id)
                                        }
                                    }
                                )
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .onAppear { loadTags() }
    }

    @ViewBuilder
    private var platformIcon: some View {
        if platform.isCustomIcon {
            Image(platform.iconName)
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: platform.iconName)
                .resizable()
                .scaledToFit()
        }
    }

    private func loadTags() {
        do {
            let context = ModelContext(ModelContainer.shared)
            let descriptor = FetchDescriptor<Tag>()
            tags = try context.fetch(descriptor)
        } catch {
            print("Failed to load tags: \(error)")
        }
    }
}

struct TagChip: View {
    let tag: Tag
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color(hex: tag.colorHex))
                    .frame(width: 8, height: 8)
                Text(tag.name)
                    .font(.subheadline)
            }
            .fixedSize()
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color(hex: tag.colorHex).opacity(0.3) : Color(.tertiarySystemBackground))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? Color(hex: tag.colorHex) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// Color hex extension for Share Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    var isLight: Bool {
        guard let components = UIColor(self).cgColor.components else { return false }
        let r = components[0]
        let g = components.count > 1 ? components[1] : r
        let b = components.count > 2 ? components[2] : r
        let luminance = (r * 299 + g * 587 + b * 114) / 1000
        return luminance > 0.5
    }
}
