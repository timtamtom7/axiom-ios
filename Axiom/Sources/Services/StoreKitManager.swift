import Foundation
import StoreKit

/// R8: StoreKit 2 integration for in-app purchases
/// Handles subscription purchases for Free/Pro/Therapist/Teams tiers
@MainActor
final class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()

    // MARK: - Product IDs
    enum ProductID: String, CaseIterable {
        case proMonthly = "com.axiom.beliefaudit.pro.monthly"
        case proYearly = "com.axiom.beliefaudit.pro.yearly"
        case therapyMonthly = "com.axiom.beliefaudit.therapy.monthly"
        case therapyYearly = "com.axiom.beliefaudit.therapy.yearly"
        case teamsMonthly = "com.axiom.beliefaudit.teams.monthly"

        var tier: SubscriptionTier {
            switch self {
            case .proMonthly, .proYearly: return .pro
            case .therapyMonthly, .therapyYearly: return .therapy
            case .teamsMonthly: return .teams
            }
        }
    }

    // MARK: - Published State
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var purchaseState: PurchaseState = .idle
    @Published private(set) var isRestoreInProgress = false

    enum PurchaseState: Equatable {
        case idle
        case purchasing
        case deferred
        case success
        case failure(String)
    }

    private var transactionListenerTask: Task<Void, Never>?

    private init() {
        startTransactionListener()
        Task { await loadProducts() }
    }

    deinit {
        transactionListenerTask?.cancel()
    }

    // MARK: - Load Products

    func loadProducts() async {
        do {
            let productIDs = ProductID.allCases.map { $0.rawValue }
            products = try await Product.products(for: productIDs)
            products.sort { $0.price < $1.price }
        } catch {
            print("Failed to load StoreKit products: \(error)")
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async {
        purchaseState = .purchasing

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                // Verify the transaction
                switch verification {
                case .unverified:
                    throw StoreKitError.verificationFailed
                case .verified(let transaction):
                    await updatePurchasedProducts()
                    await transaction.finish()
                    purchaseState = .success
                    // Apply subscription tier based on product ID
                    if let productID = ProductID(rawValue: product.id) {
                        SubscriptionService.shared.simulatePurchase(tier: productID.tier)
                    }
                    // Reset state after brief delay
                    try? await Task.sleep(for: .seconds(2))
                    purchaseState = .idle
                }

            case .userCancelled:
                purchaseState = .idle

            case .pending:
                purchaseState = .deferred

            @unknown default:
                purchaseState = .idle
            }
        } catch {
            purchaseState = .failure(error.localizedDescription)
            try? await Task.sleep(for: .seconds(3))
            purchaseState = .idle
        }
    }

    // MARK: - Restore

    func restorePurchases() async {
        isRestoreInProgress = true
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
        } catch {
            print("Failed to restore purchases: \(error)")
        }
        isRestoreInProgress = false
    }

    // MARK: - Transaction Listener

    private func startTransactionListener() {
        transactionListenerTask = Task {
            for await result in Transaction.updates {
                switch result {
                case .unverified:
                    print("Unverified transaction received")
                case .verified(let transaction):
                    await transaction.finish()
                }
            }
        }
    }

    // MARK: - Update Purchased Products

    private func updatePurchasedProducts() async {
        var purchased: Set<String> = []

        for await result in Transaction.currentEntitlements {
            switch result {
            case .unverified:
                continue
            case .verified(let transaction):
                if transaction.revocationDate == nil {
                    purchased.insert(transaction.productID)
                }
            }
        }

        purchasedProductIDs = purchased
    }

    var proProduct: Product? {
        products.first { $0.id == ProductID.proMonthly.rawValue }
    }

    var therapyProduct: Product? {
        products.first { $0.id == ProductID.therapyMonthly.rawValue }
    }

    func price(for productID: ProductID) -> String? {
        products.first { $0.id == productID.rawValue }?.displayPrice
    }

    enum StoreKitError: LocalizedError {
        case verificationFailed

        var errorDescription: String? {
            switch self {
            case .verificationFailed:
                return "Transaction verification failed"
            }
        }
    }
}
