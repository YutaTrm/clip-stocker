import SwiftUI
import SwiftData
import WebKit

struct VideoDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allTags: [Tag]

    let bookmark: VideoBookmark

    @State private var showingTagSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingTitleSheet = false
    @State private var showWebView = false
    @State private var isLoadingWeb = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Video player (遅延読み込み) - 高さを制限
                GeometryReader { geo in
                    ZStack {
                        if showWebView {
                            VideoWebView(url: bookmark.url)
                        }

                        if !showWebView || isLoadingWeb {
                            // サムネイルをプレースホルダーとして表示
                            if let data = bookmark.thumbnailData, let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                            } else {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                            }
                        }

                        if !showWebView {
                            // 再生ボタン
                            Button {
                                isLoadingWeb = true
                                showWebView = true
                                // 数秒後にローディング表示を消す
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    isLoadingWeb = false
                                }
                            } label: {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundStyle(.white.opacity(0.9))
                                    .shadow(radius: 4)
                            }
                        } else if isLoadingWeb {
                            // ローディング表示
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)
                        }
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .frame(height: 450)
                .padding(.horizontal)
                .padding(.top, 8)

                // Info section
                VStack(alignment: .leading, spacing: 12) {
                    // Title (自動取得 or カスタム)
                    HStack {
                        if let customTitle = bookmark.customTitle, !customTitle.isEmpty {
                            Text(customTitle)
                                .font(.headline)
                        } else if let title = bookmark.title, !title.isEmpty {
                            Text(title)
                                .font(.headline)
                        } else {
                            Text("No title")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        // Instagram/Twitterはタイトル編集可能
                        if bookmark.platform == .instagram || bookmark.platform == .twitter {
                            Button {
                                showingTitleSheet = true
                            } label: {
                                Image(systemName: "pencil")
                                    .font(.subheadline)
                            }
                        }
                    }

                    // Platform and date
                    HStack {
                        PlatformBadge(platform: bookmark.platform)
                        Text(bookmark.platform.rawValue)
                            .font(.subheadline)
                        Spacer()
                        Text(bookmark.createdAt, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Tags
                    if !bookmark.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(bookmark.tags) { tag in
                                    Text(tag.name)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color(hex: tag.colorHex).opacity(0.2))
                                        .foregroundStyle(Color(hex: tag.colorHex))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    // Actions - 2 columns
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        Button {
                            showingTagSheet = true
                        } label: {
                            Label("Add Tags", systemImage: "tag")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        Button {
                            openInExternalApp()
                        } label: {
                            Label("Open App", systemImage: "arrow.up.forward.app")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()

                Spacer()
            }
            .navigationTitle("Video")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingTagSheet) {
                TagSelectionSheet(bookmark: bookmark, allTags: allTags)
            }
            .sheet(isPresented: $showingTitleSheet) {
                TitleEditSheet(bookmark: bookmark)
            }
            .alert("Delete Video", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteBookmark()
                }
            } message: {
                Text("Are you sure you want to delete this video?")
            }
        }
    }

    private func deleteBookmark() {
        modelContext.delete(bookmark)
        try? modelContext.save()
        dismiss()
    }

    private func openInExternalApp() {
        guard let webURL = URL(string: bookmark.url) else { return }

        // YouTubeのみアプリで開く（他はブラウザ）
        if bookmark.platform == .youtube {
            let parsed = URLParserService.parse(bookmark.url)
            if let videoId = parsed.videoId,
               let appURL = URL(string: "youtube://watch?v=\(videoId)"),
               UIApplication.shared.canOpenURL(appURL) {
                UIApplication.shared.open(appURL)
                return
            }
        }

        // その他はブラウザで開く
        UIApplication.shared.open(webURL)
    }
}

struct VideoWebView: UIViewRepresentable {
    let url: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.isScrollEnabled = false
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if let url = URL(string: url) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
}

struct TagSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let bookmark: VideoBookmark
    let allTags: [Tag]

    var body: some View {
        NavigationStack {
            List {
                ForEach(allTags) { tag in
                    let isSelected = bookmark.tags.contains { $0.id == tag.id }
                    Button {
                        toggleTag(tag, isSelected: isSelected)
                    } label: {
                        HStack {
                            Circle()
                                .fill(Color(hex: tag.colorHex))
                                .frame(width: 12, height: 12)
                            Text(tag.name)
                            Spacer()
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                }
            }
            .navigationTitle("Select Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func toggleTag(_ tag: Tag, isSelected: Bool) {
        if isSelected {
            bookmark.tags.removeAll { $0.id == tag.id }
        } else {
            bookmark.tags.append(tag)
        }
        try? modelContext.save()
    }
}

struct TitleEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @FocusState private var isFocused: Bool

    let bookmark: VideoBookmark
    @State private var titleText: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Enter title", text: $titleText)
                        .focused($isFocused)
                } header: {
                    Text("Title")
                } footer: {
                    Text("This title will be displayed on the thumbnail")
                }

                if let originalTitle = bookmark.title, !originalTitle.isEmpty {
                    Section("Original Title") {
                        Text(originalTitle)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Edit Title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        bookmark.customTitle = titleText.isEmpty ? nil : titleText
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
            .onAppear {
                titleText = bookmark.customTitle ?? ""
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isFocused = true
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    let bookmark = VideoBookmark(
        url: "https://youtube.com/shorts/test",
        platform: .youtube
    )
    return VideoDetailView(bookmark: bookmark)
        .modelContainer(for: [VideoBookmark.self, Tag.self], inMemory: true)
}
