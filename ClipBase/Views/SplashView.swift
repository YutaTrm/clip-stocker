import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // AppIconImage が Assets にあれば表示、なければ代替アイコン
                Group {
                    if let uiImage = UIImage(named: "AppIconImage") {
                        Image(uiImage: uiImage)
                            .resizable()
                    } else {
                        // 代替: SF Symbols でアイコン風に表示
                        Image(systemName: "play.rectangle.fill")
                            .resizable()
                            .foregroundStyle(.blue)
                    }
                }
                .scaledToFit()
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 24))

                Text("ClipStocker")
                    .font(.title)
                    .fontWeight(.semibold)
            }
        }
    }
}

#Preview {
    SplashView()
}
