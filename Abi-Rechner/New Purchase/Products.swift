import Foundation

public struct Products {
  public static let basicSub = "de.abiRechner.basicAbo"
  public static let goldSub = "de.abiRechner.goldAbo"
    public static let permanent = "de.abiRechner.premium"
  public static let store = IAPManager(productIDs: Products.productIDs)
    private static let productIDs: Set<ProductID> = [Products.basicSub, Products.goldSub, Products.permanent]
}

public func resourceNameForProductIdentifier(_ productIdentifier: String) -> String? {
  return productIdentifier.components(separatedBy: ".").last
}
