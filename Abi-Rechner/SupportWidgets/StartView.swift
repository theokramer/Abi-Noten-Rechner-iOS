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

// StartView.swift
struct StartView: View {
    @EnvironmentObject var user: UserStore
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var activeScene: Int
    
    var body: some View {
        ZStack {
            if UIDevice.current.userInterfaceIdiom == .pad {
                // iPad: HomeView direkt anzeigen, NavigationView nur optional
                HomeView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                    .ignoresSafeArea()
            } else {
                // iPhone: NavigationView wie gewohnt
                NavigationView {
                    HomeView()
                }
                .navigationViewStyle(StackNavigationViewStyle())
            }
        }
        .sheet(isPresented: $user.spendenClicked) {
            PremiumView()
                .environmentObject(user)
                .frame(maxWidth: UIDevice.current.userInterfaceIdiom == .pad ? 500 : .infinity,
                       maxHeight: UIDevice.current.userInterfaceIdiom == .pad ? 600 : .infinity)
        }
        .onAppear {
            setupUserPremium()
        }
    }

    
    
    
    private func setupUserPremium() {
        user.userHasBasicPremium = user.basicPremium || Products.store.isProductPurchased(Products.basicSub)
        user.userHasGoldPremium = user.premium ||
            Products.store.isProductPurchased(Products.permanent) ||
            Products.store.isProductPurchased(Products.goldSub)
    }
    
}

let screen = UIScreen.main.bounds
