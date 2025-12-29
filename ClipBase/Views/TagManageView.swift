import SwiftUI
import SwiftData

struct TagManageView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Tag.sortOrder) private var tags: [Tag]

    @State private var showingAddTag = false
    @State private var editingTag: Tag?

    var body: some View {
        NavigationStack {
            List {
                ForEach(tags) { tag in
                    HStack {
                        Image(systemName: "line.3.horizontal")
                            .foregroundStyle(.tertiary)
                            .font(.subheadline)
                        Circle()
                            .fill(Color(hex: tag.colorHex))
                            .frame(width: 16, height: 16)
                        Text(tag.name)
                        Spacer()
                        Text("\(tag.bookmarks.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editingTag = tag
                    }
                }
                .onDelete(perform: deleteTags)
                .onMove(perform: moveTags)
            }
            .navigationTitle("Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddTag = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTag) {
                TagEditSheet(tag: nil)
            }
            .sheet(item: $editingTag) { tag in
                TagEditSheet(tag: tag)
            }
            .overlay {
                if tags.isEmpty {
                    ContentUnavailableView(
                        "No Tags",
                        systemImage: "tag",
                        description: Text("Tap + to create a tag")
                    )
                }
            }
        }
    }

    private func deleteTags(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(tags[index])
        }
        try? modelContext.save()
    }

    private func moveTags(from source: IndexSet, to destination: Int) {
        var sortedTags = tags.map { $0 }
        sortedTags.move(fromOffsets: source, toOffset: destination)

        // 並び順を更新
        for (index, tag) in sortedTags.enumerated() {
            tag.sortOrder = index
        }
        try? modelContext.save()
    }
}

struct TagEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Tag.sortOrder) private var allTags: [Tag]
    @FocusState private var isFocused: Bool

    let tag: Tag?

    @State private var name: String = ""
    @State private var selectedColor: String = Tag.presetColors[4]

    var isEditing: Bool { tag != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Tag name", text: $name)
                        .focused($isFocused)
                }

                Section("Color") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 12) {
                        ForEach(Tag.presetColors, id: \.self) { color in
                            Circle()
                                .fill(Color(hex: color))
                                .frame(width: 36, height: 36)
                                .overlay {
                                    if selectedColor == color {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.white)
                                            .font(.caption.bold())
                                    }
                                }
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle(isEditing ? "Edit Tag" : "New Tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTag()
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                if let tag = tag {
                    name = tag.name
                    selectedColor = tag.colorHex
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isFocused = true
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func saveTag() {
        if let tag = tag {
            tag.name = name
            tag.colorHex = selectedColor
        } else {
            let maxOrder = allTags.map { $0.sortOrder }.max() ?? -1
            let newTag = Tag(name: name, colorHex: selectedColor, sortOrder: maxOrder + 1)
            modelContext.insert(newTag)
        }
        try? modelContext.save()
    }
}

#Preview {
    TagManageView()
        .modelContainer(for: [Tag.self, VideoBookmark.self], inMemory: true)
}
