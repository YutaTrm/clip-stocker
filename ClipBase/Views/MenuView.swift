import SwiftUI

struct MenuView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingProUpgrade = false
    private var storeManager = StoreManager.shared

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if storeManager.isPro {
                        HStack {
                            Label {
                                Text("ClipStocker Pro")
                            } icon: {
                                Image(systemName: "crown.fill")
                                    .foregroundStyle(.yellow)
                            }
                            Spacer()
                            Text("Active")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    } else {
                        Button {
                            showingProUpgrade = true
                        } label: {
                            HStack {
                                Label {
                                    Text("Upgrade to Pro")
                                } icon: {
                                    Image(systemName: "crown.fill")
                                        .foregroundStyle(.yellow)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }

                Section {
                    Link(destination: URL(string: "https://yutatrm.github.io/clip-stocker/")!) {
                        Label("Support", systemImage: "questionmark.circle")
                    }
                }

                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Menu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingProUpgrade) {
                ProUpgradeSheet()
            }
        }
    }
}

#Preview {
    MenuView()
}
