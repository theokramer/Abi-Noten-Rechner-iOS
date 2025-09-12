//
//  AdManager.swift
//  NotenRechner
//
//  Created by Theo Kramer on 12.09.25.
//

import GoogleMobileAds
import UIKit

final class AdManager: NSObject, GADFullScreenContentDelegate {
    static let shared = AdManager()
    
    private var interstitial: GADInterstitialAd?
    private var adUnitID: String?
    
    private override init() {
        super.init()
    }
    
    func loadInterstitial(adUnitID: String) {
        self.adUnitID = adUnitID
        let request = GADRequest()
        GADInterstitialAd.load(withAdUnitID: adUnitID, request: request) { [weak self] ad, error in
            if let ad = ad {
                self?.interstitial = ad
                ad.fullScreenContentDelegate = self
                print("Interstitial loaded")
            } else {
                print("Failed to load interstitial: \(error?.localizedDescription ?? "unknown")")
            }
        }
    }
    
    func showInterstitial(from root: UIViewController) {
        guard let ad = interstitial else {
            print("Interstitial not ready")
            loadInterstitialIfNeeded()
            return
        }
        ad.present(fromRootViewController: root)
    }
    
    private func loadInterstitialIfNeeded() {
        if let id = adUnitID {
            loadInterstitial(adUnitID: id)
        }
    }
    
    // MARK: - GADFullScreenContentDelegate
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        interstitial = nil
        loadInterstitialIfNeeded()
    }
    
    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Interstitial failed to present: \(error.localizedDescription)")
        interstitial = nil
        loadInterstitialIfNeeded()
    }
}
