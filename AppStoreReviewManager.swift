//
//  AppStoreReviewManager.swift
//  Abi-Rechner
//
//  Created by Theo Kramer on 01.02.21.
//

import SwiftUI
import StoreKit

func rateApp() {
    if #available(iOS 14.0, *) {
            if let windowScene = UIApplication.shared.windows.first?.windowScene {
                SKStoreReviewController.requestReview(in: windowScene)
            }
        } else {
            SKStoreReviewController.requestReview()
        }
}
