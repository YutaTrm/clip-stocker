import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \VideoBookmark.createdAt, order: .reverse) private var bookmarks: [VideoBookmark]
    @Query(sort: \Tag.sortOrder) private var tags: [Tag]

    @State private var viewModel = VideoBookmarkViewModel()
    @State private var bookmarkForTagEdit: VideoBookmark?
    @State private var showingMenu = false
    @State private var gridMode = 0  // 0: 3列, 1: 4列, 2: 5列
    @State private var sortAscending = false

    private var columns: [GridItem] {
        switch gridMode {
        case 1:
            // 4カラム
            return [GridItem(.adaptive(minimum: 80, maximum: 100), spacing: 4)]
        case 2:
            // 5カラム
            return [GridItem(.adaptive(minimum: 60, maximum: 80), spacing: 4)]
        default:
            // 3カラム
            return [GridItem(.adaptive(minimum: 100, maximum: 150), spacing: 4)]
        }
    }

    private var sortedBookmarks: [VideoBookmark] {
        if sortAscending {
            return bookmarks.reversed()
        } else {
            return Array(bookmarks)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                // Tag filter
                if !tags.isEmpty {
                    TagFilterBar(tags: tags, selectedTag: $viewModel.selectedTag)
                        .padding(.horizontal)
                }

                // Count + Sort
                HStack {
                    Text("\(viewModel.filteredBookmarks(sortedBookmarks).count) videos")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        sortAscending.toggle()
                    } label: {
                        Image(systemName: sortAscending ? "arrow.up" : "arrow.down")
                            .font(.system(size: 14, weight: .medium))
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .tint(.primary)
                }
                .padding(.horizontal)
                .padding(.vertical, 4)

                // Video grid
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(viewModel.filteredBookmarks(sortedBookmarks)) { bookmark in
                        ThumbnailCell(bookmark: bookmark, showTitle: gridMode == 0)
                            .onTapGesture {
                                openInExternalApp(bookmark)
                            }
                            .contextMenu {
                                Button {
                                    bookmarkForTagEdit = bookmark
                                } label: {
                                    Label("Add Tags", systemImage: "tag")
                                }
                                Button(role: .destructive) {
                                    viewModel.deleteBookmark(bookmark, context: modelContext)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .padding(4)
            }
            .scrollDismissesKeyboard(.interactively)
            .simultaneousGesture(
                MagnificationGesture()
                    .onEnded { scale in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if scale > 1.3 && gridMode > 0 {
                                // ピンチアウト（拡大）→ カラム数を減らす
                                gridMode -= 1
                            } else if scale < 0.7 && gridMode < 2 {
                                // ピンチイン（縮小）→ カラム数を増やす
                                gridMode += 1
                            }
                        }
                    }
            )
            .navigationTitle("ClipStocker")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingMenu = true
                    } label: {
                        Image(systemName: "line.3.horizontal")
                    }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        viewModel.showingTagManager = true
                    } label: {
                        Image(systemName: "tag")
                    }
                    Button {
                        viewModel.showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingAddSheet) {
                AddBookmarkSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showingTagManager) {
                TagManageView()
            }
            .sheet(item: $bookmarkForTagEdit) { bookmark in
                QuickTagSheet(bookmark: bookmark, allTags: tags)
            }
            .sheet(isPresented: $showingMenu) {
                MenuView()
            }
            .safeAreaInset(edge: .bottom) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search videos", text: $viewModel.searchText)
                    if !viewModel.searchText.isEmpty {
                        Button {
                            viewModel.searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                        }
                        .tint(.primary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .padding(.horizontal, 80)
            }
        }
    }

    private func openInExternalApp(_ bookmark: VideoBookmark) {
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

struct QuickTagSheet: View {
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

struct TagFilterBar: View {
    let tags: [Tag]
    @Binding var selectedTag: Tag?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", isSelected: selectedTag == nil) {
                    selectedTag = nil
                }

                ForEach(tags) { tag in
                    FilterChip(
                        title: tag.name,
                        color: Color(hex: tag.colorHex),
                        colorHex: tag.colorHex,
                        isSelected: selectedTag?.id == tag.id
                    ) {
                        selectedTag = selectedTag?.id == tag.id ? nil : tag
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
}

struct FilterChip: View {
    let title: String
    var color: Color = .blue
    var colorHex: String = "#007AFF"
    let isSelected: Bool
    let action: () -> Void

    private var isLightColor: Bool {
        Color(hex: colorHex).isLight
    }

    private var textColor: Color {
        if isSelected {
            // 選択時: 背景色に応じて黒/白
            return isLightColor ? .black : .white
        } else {
            // 非選択時: 白や明るい色は少し暗く、黒は少し明るく
            if colorHex == "#FFFFFF" {
                return Color(.systemGray)
            } else if colorHex == "#1C1C1E" {
                return Color(.systemGray)
            } else {
                return color
            }
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            return color
        } else {
            // 白・黒は少し見やすく調整
            if colorHex == "#FFFFFF" {
                return Color(.systemGray5)
            } else if colorHex == "#1C1C1E" {
                return Color(.systemGray5)
            } else {
                return color.opacity(0.2)
            }
        }
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(backgroundColor)
                .foregroundStyle(textColor)
                .clipShape(Capsule())
        }
    }
}

struct AddBookmarkSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let viewModel: VideoBookmarkViewModel

    @State private var urlText = ""
    @State private var titleText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Video URL") {
                    TextField("Paste URL here", text: $urlText)
                        .textContentType(.URL)
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                }

                Section {
                    TextField("Enter title (optional)", text: $titleText)
                } header: {
                    Text("Title")
                } footer: {
                    Text("Leave empty to auto-fetch from video")
                }

                if !urlText.isEmpty {
                    Section {
                        let parsed = URLParserService.parse(urlText)
                        HStack {
                            if parsed.platform.isCustomIcon {
                                Image(parsed.platform.iconName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                            } else {
                                Image(systemName: parsed.platform.iconName)
                            }
                            Text(parsed.platform.rawValue)
                        }
                    } header: {
                        Text("Detected Platform")
                    }
                }
            }
            .navigationTitle("Add Video")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            let customTitle = titleText.isEmpty ? nil : titleText
                            await viewModel.addBookmark(url: urlText, customTitle: customTitle, context: modelContext)
                            dismiss()
                        }
                    }
                    .disabled(urlText.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// Color hex extension
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

    /// 明るい色かどうか判定（輝度ベース）
    var isLight: Bool {
        guard let components = UIColor(self).cgColor.components else { return false }
        let r = components[0]
        let g = components.count > 1 ? components[1] : r
        let b = components.count > 2 ? components[2] : r
        // 輝度計算（YIQ式）
        let luminance = (r * 299 + g * 587 + b * 114) / 1000
        return luminance > 0.5
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [VideoBookmark.self, Tag.self], inMemory: true)
}
