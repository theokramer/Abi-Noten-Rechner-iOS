import StoreKit

public typealias ProductID = String
public typealias ProductsRequestCompletionHandler = (_ success: Bool, _ products: [SKProduct]?) -> Void
public typealias ProductPurchaseCompletionHandler = (_ success: Bool, _ productId: ProductID?) -> Void

public class IAPManager: NSObject {
  private let productIDs: Set<ProductID>
  private var purchasedProductIDs: Set<ProductID>
  private var productsRequest: SKProductsRequest?
  private var productsRequestCompletionHandler: ProductsRequestCompletionHandler?
  private var productPurchaseCompletionHandler: ProductPurchaseCompletionHandler?
  
  public init(productIDs: Set<ProductID>) {
    self.productIDs = productIDs
    self.purchasedProductIDs = productIDs.filter { productID in
      let purchased = UserDefaults.standard.bool(forKey: productID)
        
      return purchased
    }
    super.init()
    SKPaymentQueue.default().add(self)
  }
}

extension IAPManager {
  public func requestProducts(_ completionHandler: @escaping ProductsRequestCompletionHandler) {
    productsRequest?.cancel()
    productsRequestCompletionHandler = completionHandler
    
    productsRequest = SKProductsRequest(productIdentifiers: productIDs)
    productsRequest!.delegate = self
    productsRequest!.start()
  }

  public func buyProduct(_ product: SKProduct, _ completionHandler: @escaping ProductPurchaseCompletionHandler) {
    productPurchaseCompletionHandler = completionHandler
    let payment = SKPayment(product: product)
    SKPaymentQueue.default().add(payment)
  }

  public func isProductPurchased(_ productID: ProductID) -> Bool {
    return purchasedProductIDs.contains(productID)
      
  }
  
  public class func canMakePayments() -> Bool {
    return SKPaymentQueue.canMakePayments()
  }
  
  public func restorePurchases() {
    SKPaymentQueue.default().restoreCompletedTransactions()
  }
}

extension IAPManager: SKProductsRequestDelegate {
  public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {

    let products = response.products
    guard !products.isEmpty else {

      productsRequestCompletionHandler?(false, nil)
      return
    }
    productsRequestCompletionHandler?(true, products)
    clearRequestAndHandler()
  }

  public func request(_ request: SKRequest, didFailWithError error: Error) {

    productsRequestCompletionHandler?(false, nil)
    clearRequestAndHandler()
  }

  private func clearRequestAndHandler() {
    productsRequest = nil
    productsRequestCompletionHandler = nil
  }
}

extension IAPManager: SKPaymentTransactionObserver {
  public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
    for transaction in transactions {
      switch transaction.transactionState {
      case .purchased:
        complete(transaction: transaction)

      case .failed:
        fail(transaction: transaction)

      case .restored:
        restore(transaction: transaction)
        
      case .deferred:
        break
      case .purchasing:
        break
      @unknown default:
          fatalError()
      }
    }
  }

  private func complete(transaction: SKPaymentTransaction) {

    productPurchaseCompleted(identifier: transaction.payment.productIdentifier)
    SKPaymentQueue.default().finishTransaction(transaction)
  }

  private func restore(transaction: SKPaymentTransaction) {
    guard let productIdentifier = transaction.original?.payment.productIdentifier else { return }

    productPurchaseCompleted(identifier: productIdentifier)
    SKPaymentQueue.default().finishTransaction(transaction)
  }

  private func fail(transaction: SKPaymentTransaction) {

    if let transactionError = transaction.error as NSError?,
      let localizedDescription = transaction.error?.localizedDescription,
        transactionError.code != SKError.paymentCancelled.rawValue {
        print(localizedDescription)
      }

    productPurchaseCompletionHandler?(false, nil)
    SKPaymentQueue.default().finishTransaction(transaction)
    clearHandler()
  }

  private func productPurchaseCompleted(identifier: ProductID?) {
    guard let identifier = identifier else { return }

    purchasedProductIDs.insert(identifier)
    UserDefaults.standard.set(true, forKey: identifier)
    productPurchaseCompletionHandler?(true, identifier)
    clearHandler()
  }

  private func clearHandler() {
    productPurchaseCompletionHandler = nil
  }
}
