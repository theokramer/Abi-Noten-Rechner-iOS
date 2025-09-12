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
            HomeView()
                .background(Color(.systemBackground))
                .ignoresSafeArea()
            
            // MARK: Scene Handling
            Group {
                if activeScene == 0 {
                    handleNewSemester()
                }
                
                if activeScene == 1 {
                    handleEditSemester()
                }
                
                if user.ausrechnen {
                    SemesterNoteAusrechnen()
                        .onDisappear {
                            user.reviewCount += 1
                            if user.reviewCount == 4 || user.reviewCount == 8 {
                                rateApp()
                            }
                        }
                }
                
                if user.abiClicked {
                    AbiClicked()
                }
            }
        }
        .sheet(isPresented: $user.spendenClicked) {
            PremiumView()
                .environmentObject(user)  // <<< NICHT neu erstellen
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
            loadInterstitial()
        }
    }
}

// MARK: - Helpers
extension StartView {
    @ViewBuilder
    private func handleNewSemester() -> some View {
        if (fetchAllSemesterNoten(viewContext: viewContext)?.count ?? 0) < 1 ||
            user.basicPremium || Products.store.isProductPurchased(Products.basicSub) ||
            user.premium || Products.store.isProductPurchased(Products.permanent) ||
            Products.store.isProductPurchased(Products.goldSub) {
            
            SemesterNoteAusrechnen()
                .onAppear {
                    user.ausrechnen = true
                    user.updateMode = false
                    user.aktuellerFaecherArray = fetchMap()
                    user.aktuellerNotenName = ""
                    hideKeyboard()
                    activeScene = -1
                }
        } else {
            Color.clear.onAppear {
                user.simpleError()
            }
        }
    }
    
    @ViewBuilder
    private func handleEditSemester() -> some View {
        if let semester = fetchAllSemesterNoten(viewContext: viewContext)?.first {
            SemesterNoteAusrechnen()
                .onAppear {
                    user.ausrechnen = true
                    user.aktuellerFaecherArray = fetchAllFaecherFromSemesternote(id: semester.id, viewContext: viewContext)
                    user.aktuellerNotenName = semester.name
                    user.aktuelleID = semester.id.uuidString
                    user.updateMode = true
                    activeScene = -1
                }
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
    
    private func loadInterstitial() {
        // iOS 15: AdMob Ads werden asynchron geladen
        let request = GADRequest()
        GADInterstitialAd.load(withAdUnitID: "YOUR-AD-UNIT-ID", request: request) { ad, error in
            if let ad = ad {
                self.interstitial = ad
                if let root = UIApplication.shared.connectedScenes
                    .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
                    .first?.rootViewController {
                    ad.present(fromRootViewController: root)
                }
            } else {
                print("Interstitial load error: \(error?.localizedDescription ?? "unknown")")
            }
        }
    }
}

struct StartView_Previews: PreviewProvider {
    static var previews: some View {
        StartView(activeScene: .constant(0))
            .environmentObject(UserStore())
    }
}


let screen = UIScreen.main.bounds
