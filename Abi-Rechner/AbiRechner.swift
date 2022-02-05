//
//  Abi_RechnerApp.swift
//  Abi-Rechner
//
//  Created by Theo Kramer on 23.01.21.
//

import SwiftUI
import StoreKit
import AppTrackingTransparency
import GoogleMobileAds

@main
struct AbiRechner: App {
    let persistenceController = PersistenceController.shared
    let selectedColor: UIColor = UserDefaults.standard.colorForKey(key: "selectedColor") ?? UIColor(Color("Orange"))

    @Environment(\.scenePhase) var phase
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @State var activeScene = -1
    
    func addQuickActions() {
        var newUserInfo: [String: NSSecureCoding] {
                    return ["name": "new" as NSSecureCoding]
                }
        var editUserInfo: [String: NSSecureCoding] {
                    return ["name": "edit" as NSSecureCoding]
                }
            UIApplication.shared.shortcutItems = [
                UIApplicationShortcutItem(type: "Edit", localizedTitle: "Bearbeiten",
                                          localizedSubtitle: "Semesternote bearbeiten",
                                          icon: UIApplicationShortcutIcon(systemImageName: "pencil"),
                                          userInfo: editUserInfo),
                UIApplicationShortcutItem(type: "New", localizedTitle: "Neu",
                                          localizedSubtitle: "Neue Semesternote anlegen",
                                          icon: UIApplicationShortcutIcon(systemImageName: "plus"),
                                          userInfo: newUserInfo)
            ]
        }

    init() {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
            ATTrackingManager.requestTrackingAuthorization { status in
                
                switch status {
                case .notDetermined:

                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
                        if success {
                            
                        } else if let error = error {
                            print(error.localizedDescription)
                        }
                    }
                case .restricted:

                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
                        if success {
                           
                        } else if let error = error {
                            print(error.localizedDescription)
                        }
                    }
                case .denied:

                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
                        if success {
                          
                        } else if let error = error {
                            print(error.localizedDescription)
                        }
                    }
                case .authorized:

                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
                        if success {
                            sheduleNotificationHalbjahr()
                            sheduleNotificationEndeDesJahres()
                            sheduleNotificationGeneral()
                            sheduleNotificationSaleEnding()
                        } else if let error = error {
                            print(error.localizedDescription)
                        }
                    }
                @unknown default:
                    break
                }
                
                GADMobileAds.sharedInstance().start(completionHandler: nil)
            }
            
        })
        
        }

    var body: some Scene {
        WindowGroup {
            StartView(activeScene: $activeScene).accentColor(Color(selectedColor))
                .environment(\.managedObjectContext, persistenceController.container.viewContext).environmentObject(UserStore()).onAppear {
                    if Products.store.isProductPurchased(Products.basicSub) {
                        UserStore().userHasBasicPremium = true
                    } else {
                        UserStore().userHasBasicPremium = false
                    }
                    
                    if Products.store.isProductPurchased(Products.goldSub) {
                        UserStore().userHasGoldPremium = true
                    } else {
                        UserStore().userHasGoldPremium = false
                    }
                }
                
        }.onChange(of: phase) { (newPhase) in
            switch newPhase {
            case .active :

                if shortcutItemToProcess?.localizedTitle == "Neu" {
                activeScene = 0

                }
                
                if shortcutItemToProcess?.localizedTitle == "Bearbeiten" {
                activeScene = 1

                }

            case .inactive:
                break
                
            case .background:

                addQuickActions() 
            @unknown default:
                break
            }
            
        }
    }
}

var activeScreen: [String: NSSecureCoding] = [:]

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        if let shortcutItem = options.shortcutItem {
            shortcutItemToProcess = shortcutItem
        }
        
        let sceneConfiguration = UISceneConfiguration(name: "Custom Configuration", sessionRole: connectingSceneSession.role)
        sceneConfiguration.delegateClass = CustomSceneDelegate.self
        
        return sceneConfiguration
    }
}

class CustomSceneDelegate: UIResponder, UIWindowSceneDelegate {
    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        shortcutItemToProcess = shortcutItem
    }
}

var shortcutItemToProcess: UIApplicationShortcutItem?
