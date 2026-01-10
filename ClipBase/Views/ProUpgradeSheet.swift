import SwiftUI
import StoreKit

struct ProUpgradeSheet: View {
    @Environment(\.dismiss) private var dismiss
    private var storeManager = StoreManager.shared

    @State private var isPurchasing = false
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.yellow)

                        Text("ClipStocker Pro")
                            .font(.title.bold())

                        Text("Unlock all features")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 20)

                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        FeatureRow(icon: "infinity", title: "Unlimited Videos", description: "Open all saved videos without limits")
                        FeatureRow(icon: "tag.fill", title: "Unlimited Tags", description: "Create as many tags as you need")
                        FeatureRow(icon: "square.grid.2x2.fill", title: "Widget Tag Filter", description: "Filter widget by tags")
                        FeatureRow(icon: "xmark.circle.fill", title: "No Ads", description: "Enjoy an ad-free experience")
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 20)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    // Plan options
                    if storeManager.isLoading {
                        ProgressView()
                            .padding()
                    } else if storeManager.products.isEmpty {
                        Text("Unable to load products")
                            .foregroundStyle(.secondary)
                            .padding()
                    } else {
                        VStack(spacing: 12) {
                            if let yearly = storeManager.yearlyProduct {
                                PlanButton(
                                    product: yearly,
                                    badge: savingsText,
                                    isRecommended: true,
                                    isPurchasing: isPurchasing
                                ) {
                                    await purchase(yearly)
                                }
                            }

                            if let monthly = storeManager.monthlyProduct {
                                PlanButton(
                                    product: monthly,
                                    badge: nil,
                                    isRecommended: false,
                                    isPurchasing: isPurchasing
                                ) {
                                    await purchase(monthly)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Restore purchases
                    Button {
                        Task {
                            await storeManager.restorePurchases()
                            if storeManager.isPro {
                                dismiss()
                            }
                        }
                    } label: {
                        Text("Restore Purchases")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)

                    // Terms
                    VStack(spacing: 8) {
                        Text("Payment will be charged to your Apple ID account. Subscription automatically renews unless canceled at least 24 hours before the end of the current period.")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)

                        HStack(spacing: 16) {
                            Link("Terms of Use", destination: URL(string: "https://yutatrm.github.io/clip-stocker/terms.html")!)
                            Link("Privacy Policy", destination: URL(string: "https://yutatrm.github.io/clip-stocker/privacy.html")!)
                        }
                        .font(.caption2)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "An error occurred")
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func purchase(_ product: Product) async {
        isPurchasing = true
        do {
            let success = try await storeManager.purchase(product)
            if success {
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isPurchasing = false
    }

    private var savingsText: String? {
        guard let yearly = storeManager.yearlyProduct,
              let monthly = storeManager.monthlyProduct else { return nil }
        let yearlyPrice = NSDecimalNumber(decimal: yearly.price).doubleValue
        let monthlyAnnual = NSDecimalNumber(decimal: monthly.price).doubleValue * 12
        guard monthlyAnnual > 0 else { return nil }
        let savings = ((monthlyAnnual - yearlyPrice) / monthlyAnnual * 100)
        let savingsInt = Int(savings.rounded())
        return savingsInt > 0 ? "\(savingsInt)%お得" : nil
    }
}

// MARK: - Feature Row
private struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Plan Button
private struct PlanButton: View {
    let product: Product
    let badge: String?
    let isRecommended: Bool
    let isPurchasing: Bool
    let action: () async -> Void

    private var periodText: String {
        switch product.subscription?.subscriptionPeriod.unit {
        case .year:
            return "/year"
        case .month:
            return "/month"
        case .week:
            return "/week"
        case .day:
            return "/day"
        default:
            return ""
        }
    }

    var body: some View {
        Button {
            Task {
                await action()
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(product.subscription?.subscriptionPeriod.unit == .year ? "Yearly" : "Monthly")
                            .font(.headline)

                        if let badge = badge {
                            Text(badge)
                                .font(.caption2.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.green)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    }

                    if isRecommended {
                        Text("Most popular")
                            .font(.caption)
                            .foregroundStyle(isRecommended ? .white.opacity(0.8) : .secondary)
                    }
                }

                Spacer()

                if isPurchasing {
                    ProgressView()
                        .tint(isRecommended ? .white : .primary)
                } else {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(product.displayPrice)
                            .font(.title2.bold())
                        Text(periodText)
                            .font(.caption)
                            .foregroundStyle(isRecommended ? .white.opacity(0.8) : .secondary)
                    }
                }
            }
            .padding()
            .background(isRecommended ? Color.blue : Color(.secondarySystemBackground))
            .foregroundStyle(isRecommended ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                if isRecommended {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue, lineWidth: 2)
                }
            }
        }
        .disabled(isPurchasing)
    }
}

#Preview {
    ProUpgradeSheet()
}
