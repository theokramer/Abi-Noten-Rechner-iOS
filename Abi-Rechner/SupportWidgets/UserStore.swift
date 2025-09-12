//
//  UserStore.swift
//  Abi-Rechner
//
//  Created by Theo Kramer on 23.01.21.
//

import SwiftUI
import Combine
import StoreKit

class UserStore: ObservableObject {
    @Published var spendenClicked: Bool = false
    @Published var updateMode = true
    @Published var aktuelleID = ""
    @Published var semesterNoten = [SemesternotenItem]()
    @Published var products = [SKProduct]()
    @Published var components = DateComponents()
    @Published var differenceBetweenDates = updateDifferenceBetweenDates()
    @Published var interstitialCount: Int = defaults.integer(forKey: "interstitialCount") {
        didSet { defaults.set(interstitialCount, forKey: "interstitialCount") }
    }
    @Published var userHasBasicPremium = defaults.bool(forKey: "userHasBasicPremium") {
        didSet {
            defaults.set(userHasBasicPremium, forKey: "userHasBasicPremium")
        }
    }
    @Published var userHasGoldPremium = defaults.bool(forKey: "userHasGoldPremium") {
        didSet {
            defaults.set(userHasGoldPremium, forKey: "userHasGoldPremium")
        }
    }
    
    func checkForPremiumStatus() {
        userHasBasicPremium = basicPremium || Products.store.isProductPurchased(Products.basicSub) ? true : false
        userHasGoldPremium = premium || Products.store.isProductPurchased(Products.permanent) ||
        Products.store.isProductPurchased(Products.goldSub) ? true : false
    }
    
    @Published var premium: Bool = defaults.bool(forKey: "premium") {
        didSet {
            defaults.set(premium, forKey: "premium")
        }
    }
    
    func simpleSuccess() {
        
        let generator = UINotificationFeedbackGenerator()
        
            generator.notificationOccurred(.success)
        
    }
    
    func simpleWarning() {
        let generator = UINotificationFeedbackGenerator()
        
            generator.notificationOccurred(.warning)
    }
    
    func simpleError() {
        let generator = UINotificationFeedbackGenerator()
        
            generator.notificationOccurred(.error)
    }
    
    @Published var basicPremium: Bool = defaults.bool(forKey: "basicPremium") {
        didSet {
            defaults.set(basicPremium, forKey: "basicPremium")
        }
    }
    
    @Published var endNoteAbi: Double = defaults.double(forKey: "endNoteAbi") {
        didSet {
            defaults.set(endNoteAbi, forKey: "endNoteAbi")
        }
    }

    @Published var endPunkteAbi: Double = defaults.double(forKey: "endPunkteAbi") {
        didSet {
            defaults.set(endPunkteAbi, forKey: "endPunkteAbi")
        }
    }
    @Published var pruefungsNamenArray: [String] = defaults.stringArray(forKey: "pruefungsNamenArray") ?? [] {
        didSet {
            defaults.set(pruefungsNamenArray, forKey: "pruefungsNamenArray")
        }
    }
    @Published var pruefungsNotenArray: [String] = defaults.stringArray(forKey: "pruefungsNotenArray") ?? [] {
        didSet {
            defaults.set(pruefungsNotenArray, forKey: "pruefungsNotenArray")
        }
    }

    

    @Published var aktuellerFaecherArray:[FachItem] = fetchMap()
    @Published var semesterArray: [SemesternotenItem] = {
        if let data = defaults.data(forKey: "semesterArray_v1") {
            do {
                return try JSONDecoder().decode([SemesternotenItem].self, from: data)
            } catch {
                print("⚠️ Fehler beim Laden semesterArray:", error)
            }
        }
        return []
    }() {
        didSet {
            do {
                let data = try JSONEncoder().encode(semesterArray)
                defaults.set(data, forKey: "semesterArray_v1")
            } catch {
                print("⚠️ Fehler beim Speichern semesterArray:", error)
            }
        }
    }

    
    
    @Published var aktuellerAbiNotenArray: [AbiItem] = {
        if let data = defaults.data(forKey: "aktuellerAbiNotenArray_v1") {
            do {
                return try JSONDecoder().decode([AbiItem].self, from: data)
            } catch {
                print("⚠️ Fehler beim Laden aktuellerAbiNotenArray:", error)
            }
        }
        return []
    }() {
        didSet {
            do {
                let data = try JSONEncoder().encode(aktuellerAbiNotenArray)
                defaults.set(data, forKey: "aktuellerAbiNotenArray_v1")
            } catch {
                print("⚠️ Fehler beim Speichern aktuellerAbiNotenArray:", error)
            }
        }
    }
    
    @Published var selectedSemesterIDs: [UUID] = {
        if let saved = defaults.array(forKey: "selectedSemesterIDs_v1") as? [String] {
            return saved.compactMap { UUID(uuidString: $0) }
        }
        return []
    }() {
        didSet {
            let ids = selectedSemesterIDs.map { $0.uuidString }
            defaults.set(ids, forKey: "selectedSemesterIDs_v1")
        }
    }



    @Published var aktuellerNotenName = defaults.string(forKey: "aktuellerNotenName") ?? "" {
        didSet {
            defaults.set(aktuellerNotenName, forKey: "aktuellerNotenName")
        }
    }
    
    func refreshSemesterArray() {
           // zwingt SwiftUI, das Array neu zu erkennen
           objectWillChange.send()
       }
    
}
let defaults = UserDefaults.standard
let  tablet = screen.width > 430 ? true : false

func sheduleNotificationHalbjahr() {
    let content = UNMutableNotificationContent()
    content.title = "Semester-Note ausrechnen"
    content.body = "Es sieht so aus, als neige sich das Halbjahr dem Ende zu. Denk daran, deine Semesternote auszurechnen."
    
    var dateComponents = DateComponents()
    dateComponents.calendar = Calendar.current
    dateComponents.month = 1
    dateComponents.day = 28
    dateComponents.hour = 13
    dateComponents.minute = 30
    
    let trigger = UNCalendarNotificationTrigger(
             dateMatching: dateComponents, repeats: true)
    
    let uuidString = UUID().uuidString
    let request = UNNotificationRequest(identifier: uuidString,
                content: content, trigger: trigger)

    // Schedule the request with the system.
    let notificationCenter = UNUserNotificationCenter.current()
    notificationCenter.add(request) { (error) in
       if error != nil {
          // Handle any errors.
       }
    }
}

extension UIApplication {
    func hideKeyboard() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
func hideKeyboard() {
    UIApplication.shared.hideKeyboard()
}

