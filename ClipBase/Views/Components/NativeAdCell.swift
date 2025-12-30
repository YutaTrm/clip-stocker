import SwiftUI
import GoogleMobileAds

/// グリッド内に表示するネイティブ広告セル
struct NativeAdCell: View {
    let nativeAd: NativeAd?
    let showTitle: Bool

    var body: some View {
        if let ad = nativeAd {
            NativeAdViewRepresentable(nativeAd: ad, showTitle: showTitle)
                .aspectRatio(9/16, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            // 広告読み込み中のプレースホルダー
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
                .aspectRatio(9/16, contentMode: .fit)
                .overlay {
                    ProgressView()
                }
        }
    }
}

/// UIKit の NativeAdView を SwiftUI でラップ
struct NativeAdViewRepresentable: UIViewRepresentable {
    let nativeAd: NativeAd
    let showTitle: Bool

    func makeUIView(context: Context) -> NativeAdView {
        let adView = NativeAdView()
        adView.backgroundColor = .secondarySystemBackground
        adView.layer.cornerRadius = 8
        adView.clipsToBounds = true

        // 動画広告の場合は静止画を使用、それ以外はMediaViewを使用
        if nativeAd.mediaContent.hasVideoContent, let image = nativeAd.images?.first?.image {
            // 静止画で表示（動画のスクロール問題を回避）
            let imageView = UIImageView(image: image)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.contentMode = .scaleAspectFit
            imageView.backgroundColor = .secondarySystemBackground
            adView.addSubview(imageView)
            adView.imageView = imageView

            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: adView.topAnchor),
                imageView.leadingAnchor.constraint(equalTo: adView.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: adView.trailingAnchor),
                imageView.bottomAnchor.constraint(equalTo: adView.bottomAnchor),
            ])
        } else {
            // メディアビュー（静止画広告の場合）
            let mediaView = MediaView()
            mediaView.translatesAutoresizingMaskIntoConstraints = false
            mediaView.contentMode = .scaleAspectFill
            adView.addSubview(mediaView)
            adView.mediaView = mediaView

            NSLayoutConstraint.activate([
                mediaView.topAnchor.constraint(equalTo: adView.topAnchor),
                mediaView.leadingAnchor.constraint(equalTo: adView.leadingAnchor),
                mediaView.trailingAnchor.constraint(equalTo: adView.trailingAnchor),
                mediaView.bottomAnchor.constraint(equalTo: adView.bottomAnchor),
            ])
        }

        // 広告ラベル
        let adLabel = UILabel()
        adLabel.text = "Ad"
        adLabel.font = .systemFont(ofSize: 9, weight: .medium)
        adLabel.textColor = .white
        adLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        adLabel.textAlignment = .center
        adLabel.layer.cornerRadius = 4
        adLabel.clipsToBounds = true
        adLabel.translatesAutoresizingMaskIntoConstraints = false
        adView.addSubview(adLabel)

        // タイトル用グラデーション背景
        let gradientView = GradientView()
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        adView.addSubview(gradientView)

        // タイトルラベル
        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 12, weight: .medium)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        adView.addSubview(titleLabel)
        adView.headlineView = titleLabel

        NSLayoutConstraint.activate([
            // 広告ラベル（右上 - プラットフォームバッジと同じ位置）
            adLabel.topAnchor.constraint(equalTo: adView.topAnchor, constant: 6),
            adLabel.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -6),
            adLabel.widthAnchor.constraint(equalToConstant: 28),
            adLabel.heightAnchor.constraint(equalToConstant: 16),

            // グラデーション背景（下部）
            gradientView.leadingAnchor.constraint(equalTo: adView.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: adView.trailingAnchor),
            gradientView.bottomAnchor.constraint(equalTo: adView.bottomAnchor),
            gradientView.heightAnchor.constraint(equalToConstant: 50),

            // タイトル
            titleLabel.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -8),
            titleLabel.bottomAnchor.constraint(equalTo: adView.bottomAnchor, constant: -8),
        ])

        // タイトル表示/非表示
        gradientView.isHidden = !showTitle
        titleLabel.isHidden = !showTitle

        return adView
    }

    func updateUIView(_ adView: NativeAdView, context: Context) {
        adView.nativeAd = nativeAd
        if !nativeAd.mediaContent.hasVideoContent {
            adView.mediaView?.mediaContent = nativeAd.mediaContent
        }
        (adView.headlineView as? UILabel)?.text = nativeAd.headline
    }
}

/// グラデーション背景用のUIView
private class GradientView: UIView {
    override class var layerClass: AnyClass {
        CAGradientLayer.self
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGradient()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGradient()
    }

    private func setupGradient() {
        guard let gradientLayer = layer as? CAGradientLayer else { return }
        gradientLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.7).cgColor
        ]
        gradientLayer.locations = [0, 1]
    }
}

#Preview {
    NativeAdCell(nativeAd: nil, showTitle: true)
        .frame(width: 120, height: 200)
}
