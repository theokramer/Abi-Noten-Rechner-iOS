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
//    @Environment(\.scenePhase) var phase
    @Environment(\.managedObjectContext) private var viewContext
//    @StateObject var storeManager:StoreManager2
    
    @Binding var activeScene: Int
    
    func containedView() -> AnyView {
        switch user.siteOpened {
        case 0:
            return AnyView(HomeView())
        case 1:
            return AnyView(SemesterNoteAusrechnen())
        case 2:
            return AnyView(SemesterNotenVerlauf())
        case 3:
            return AnyView(SpendenView())
        case 4:
            return AnyView(AbiClicked())
        case 5:
            return AnyView(SupportView())
        default:
            return AnyView(HomeView())
        }
    }
    
    @State var interstitial: GADInterstitialAd = GADInterstitialAd()
    var body: some View {
        ZStack {
            if tablet {
            containedView()
            } else {
                
                ZStack {
                        HomeView()
                    if activeScene == 0 {
                     if fetchAllSemesterNoten(viewContext: viewContext)?.count ?? 0 < 1 ||
                            user.basicPremium || Products.store.isProductPurchased(Products.basicSub) ||
                            user.premium || Products.store.isProductPurchased(Products.permanent) ||
                            Products.store.isProductPurchased(Products.goldSub) {
                        
                        SemesterNoteAusrechnen().onAppear {
                            
                                user.ausrechnen = true
                                    
                                user.updateMode = false
                                user.aktuellerFaecherArray = fetchMap()
                                user.aktuellerNotenName = ""
                                    hideKeyboard()
                            activeScene = -1
                                    
                        }
                    } else {
                        Color.white.opacity(0).onAppear {
                            user.simpleError()
                        }
                    }
                        
                    }
                        if activeScene == 1 {
                        SemesterNoteAusrechnen().onAppear {
                            
                                user.ausrechnen = true
                                
                            user.aktuellerFaecherArray = fetchAllFaecherFromSemesternote(
                                id: fetchAllSemesterNoten(viewContext: viewContext)![0].id, viewContext: viewContext)
                                user.aktuellerNotenName = fetchAllSemesterNoten(viewContext: viewContext)![0].name
                                user.aktuelleID = fetchAllSemesterNoten(viewContext: viewContext)![0].id.uuidString
                                user.updateMode = true
                                activeScene = -1
                            
                        }
                        }
                    
                        if user.ausrechnen {
                            SemesterNoteAusrechnen().onAppear {
                                
                            }.onDisappear {
                                user.reviewCount += 1
                                if user.reviewCount == 4 || user.reviewCount == 8 {
                                    rateApp()
                                }
                                
                            }
                        }
                        
                        if user.verlauf {
                            SemesterNotenVerlauf()
                        }
                    
                        if user.showAd {
                            
                        }
                    
                    if user.abiClicked {
                        AbiClicked()
                    }
                    
                    }.sheet(isPresented: $user.spendenClicked, content: {
                        SpendenView().environmentObject(UserStore()).onDisappear {
                            user.userHasBasicPremium = user.basicPremium || Products.store.isProductPurchased(Products.basicSub) ? true : false
                            user.userHasGoldPremium = user.premium || Products.store.isProductPurchased(Products.permanent) ||
                            Products.store.isProductPurchased(Products.goldSub) ? true : false
                        }
                    }).sheet(isPresented: $user.supportClicked, content: {
                        SupportView()
                    })
               
            }
                
        }.onAppear {

            user.userHasBasicPremium = user.basicPremium || Products.store.isProductPurchased(Products.basicSub) ? true : false
            user.userHasGoldPremium = user.premium || Products.store.isProductPurchased(Products.permanent) ||
            Products.store.isProductPurchased(Products.goldSub) ? true : false
            print("hallo")
            if !checkIfSaleIsActive() {
                Color.saleColor = Color("Orange")
            }
            
            print(self.interstitial.adUnitID)
                let root = UIApplication.shared.windows.first?.rootViewController
                self.interstitial.present(fromRootViewController: root!)
            
        }

    }
}

struct StartView_Previews: PreviewProvider {
    static var previews: some View {
        StartView(activeScene: .constant(0)).environmentObject(UserStore())
    }
}

let screen = UIScreen.main.bounds
