//
//  StartView.swift
//  Abi-Rechner
//
//  Created by Theo Kramer on 23.01.21.
//


import SwiftUI
import UserNotifications
import GoogleMobileAds
import CoreData

struct StartView: View {
    @EnvironmentObject var user: UserStore
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var activeScene: Int
    
    @State private var interstitial: GADInterstitialAd?
    
    var body: some View {
        ZStack {
            // HomeView direkt und groß anzeigen
            HomeView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
                .ignoresSafeArea()
            
            
        }
        .sheet(isPresented: $user.spendenClicked) {
            PremiumView()
                .environmentObject(user)
                .onDisappear {
                    user.userHasBasicPremium = user.basicPremium || Products.store.isProductPurchased(Products.basicSub)
                    user.userHasGoldPremium = user.premium ||
                        Products.store.isProductPurchased(Products.permanent) ||
                        Products.store.isProductPurchased(Products.goldSub)
                }
                .frame(maxWidth: UIDevice.current.userInterfaceIdiom == .pad ? 500 : .infinity,
                       maxHeight: UIDevice.current.userInterfaceIdiom == .pad ? 600 : .infinity)
        }
        .onAppear {
            setupUserPremium()
            setupSaleColor()
        }
    }
    
    
    
    private func setupUserPremium() {
        user.userHasBasicPremium = user.basicPremium || Products.store.isProductPurchased(Products.basicSub)
        user.userHasGoldPremium = user.premium ||
            Products.store.isProductPurchased(Products.permanent) ||
            Products.store.isProductPurchased(Products.goldSub)
    }
    
    private func setupSaleColor() {
        if !checkIfSaleIsActive() {
            Color.saleColor = Color("Orange")
        }
    }
}

let screen = UIScreen.main.bounds
