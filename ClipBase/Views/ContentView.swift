import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \VideoBookmark.createdAt, order: .reverse) private var bookmarks: [VideoBookmark]
    @Query private var tags: [Tag]

    @State private var viewModel = VideoBookmarkViewModel()
    @State private var selectedBookmark: VideoBookmark?

    private let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 150), spacing: 4)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                // Tag filter
                if !tags.isEmpty {
                    TagFilterBar(tags: tags, selectedTag: $viewModel.selectedTag)
                        .padding(.horizontal)
                }

                // Video grid
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(viewModel.filteredBookmarks(bookmarks)) { bookmark in
                        ThumbnailCell(bookmark: bookmark)
                            .onTapGesture {
                                selectedBookmark = bookmark
                            }
                            .contextMenu {
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
            .navigationTitle("ClipStocker")
            .searchable(text: $viewModel.searchText, prompt: "Search videos")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        viewModel.showingTagManager = true
                    } label: {
                        Image(systemName: "tag")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
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
            .sheet(item: $selectedBookmark) { bookmark in
                VideoDetailView(bookmark: bookmark)
            }
        }
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
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? color : color.opacity(0.2))
                .foregroundStyle(isSelected ? .white : color)
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
                            Image(systemName: parsed.platform.iconName)
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
}

#Preview {
    ContentView()
        .modelContainer(for: [VideoBookmark.self, Tag.self], inMemory: true)
}
