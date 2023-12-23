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
    @Published var ausrechnen: Bool = defaults.bool(forKey: "ausrechnen") {
        didSet {
            defaults.set(ausrechnen, forKey: "ausrechnen")
        }
    }
    @Published var schnitt: Bool = defaults.bool(forKey: "schnitt") {
        didSet {
            defaults.set(schnitt, forKey: "schnitt")
        }
    }
    @Published var verlauf: Bool = defaults.bool(forKey: "verlauf") {
        didSet {
            defaults.set(verlauf, forKey: "verlauf")
        }
    }
    
    @Published var abiClicked: Bool = defaults.bool(forKey: "abiClicked") {
        didSet {
            defaults.set(abiClicked, forKey: "abiClicked")
        }
    }
    @Published var spendenClicked: Bool = defaults.bool(forKey: "spendenClicked") {
        didSet {
            defaults.set(spendenClicked, forKey: "spendenClicked")
        }
    }
    @Published var letztesSemester = false
    @Published var itemClicked = false
    @Published var updateMode = true
    @Published var reviewed = false
    @Published var aktuelleID = ""
    @Published var siteOpened = defaults.integer(forKey: "siteOpened") {
        didSet {
            defaults.set(siteOpened, forKey: "siteOpened")
        }
    }
    @Published var updateVerlauf = false
    @Published var semesterNoten = [SemesternotenItem]()
    @Published var showAd = false
    @Published var products = [SKProduct]()
    @Published var components = DateComponents()
    @Published var differenceBetweenDates = updateDifferenceBetweenDates()
    @Published var supportClicked = false
    @Published var sendEmail = false
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
    
    @Published var blackText: Bool = defaults.bool(forKey: "blackText") {
        didSet {
            defaults.set(blackText, forKey: "blackText")
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
    
    @Published var aktuellePunkte: Double = defaults.double(forKey: "aktuellePunkte") {
        didSet {
            defaults.set(aktuellePunkte, forKey: "aktuellePunkte")
        }
    }
    @Published var aktuelleNote: Double = defaults.double(forKey: "aktuelleNote") {
        didSet {
            defaults.set(aktuelleNote, forKey: "aktuelleNote")
        }
    }
    @Published var aktuellerName = defaults.string(forKey: "aktuellerName") {
        didSet {
            defaults.set(aktuellerName, forKey: "aktuellerName")
        }
    }
    //fetchMap()
    @Published var aktuellerFaecherArray:[FachItem] = fetchMap()
    
    @Published var aktuellerAbiNotenArray = fetchMapAbi()
    @Published var aktuellerNotenName = defaults.string(forKey: "aktuellerNotenName") ?? "" {
        didSet {
            defaults.set(aktuellerNotenName, forKey: "aktuellerNotenName")
        }
    }
    
    @Published var verlaufPunkte = 0.0
    @Published var verlaufNote = 0.0
    @Published var verlaufName = ""
    @Published var verlaufFaecherArray = fetchMap()
    @Published var verlaufNotenName = ""
    @Published var reviewCount: Int = defaults.integer(forKey: "reviewCount") {
        didSet {
            defaults.set(reviewCount, forKey: "reviewCount")
        }
    }
    @Published var nachSpeichernFragenStopp: Bool = defaults.bool(forKey: "nachSpeichernFragenStopp") {
        didSet {
            defaults.set(nachSpeichernFragenStopp, forKey: "nachSpeichernFragenStopp")
        }
    }
    @Published var frageNachSpeichern = false
    
}
let defaults = UserDefaults.standard
let  tablet = screen.width > 430 ? true : false
 
extension Color {
    static var mainColor = Color.accentColor
    static let modeColor = Color("modeColor")
    static let modeColorSwitch = Color("modeColorSwitch")
    static let mainColor2 = Color("Orange")
    static var saleColor = Color("Sale Color")
}

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

func sheduleNotificationGeneral() {
    let content = UNMutableNotificationContent()
    content.title = "Semester-Note ausrechnen"
    content.body = "Denk daran, deine Semesternote auszurechnen!"
    
    var dateComponents = DateComponents()
    dateComponents.calendar = Calendar.current
    dateComponents.weekOfMonth = 1
    dateComponents.weekday = 1
    dateComponents.hour = 17
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

func sheduleNotificationSaleEnding() {
    let content = UNMutableNotificationContent()
    content.title = "Bis zu 40% Winter-Sale"
    content.body = "Der Winter-Sale endet bald. Hol dir jetzt noch die Premiumversion des Abi Noten Rechners für bis zu 40% reduziert."
    
    var dateComponents = DateComponents()
    dateComponents.calendar = Calendar.current
    dateComponents.year = 2022
    dateComponents.month = 1
    dateComponents.day = 20
    dateComponents.hour = 17
    dateComponents.minute = 00
    
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

func sheduleNotificationEndeDesJahres() {
    let content = UNMutableNotificationContent()
    content.title = "Semester-Note ausrechnen"
    content.body = "Es sieht so aus, als neige sich das Schuljahr dem Ende zu. Denk daran, deine Semesternote auszurechnen."
    
    var dateComponents = DateComponents()
    dateComponents.calendar = Calendar.current
    dateComponents.month = 7
    dateComponents.day = 30
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

func checkIfSaleIsActive() -> Bool {
    
/*
 let formatter = DateFormatter()
 formatter.dateFormat = "dd/MM/yyyy"
 let firstDate = formatter.date(from: "20/01/2022")
 let secondDate = Date()

 if firstDate?.compare(secondDate) == .orderedDescending {
     return true
 }
 return false
 */
    
    return true
    
}

extension UserDefaults {
  func colorForKey(key: String) -> UIColor? {
    var colorReturnded: UIColor?
    if let colorData = data(forKey: key) {
      do {
        if let color = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(colorData) as? UIColor {
          colorReturnded = color
        }
      } catch {
        print("Error UserDefaults")
      }
    }
    return colorReturnded
  }
  
  func setColor(color: UIColor?, forKey key: String) {
    var colorData: NSData?
    if let color = color {
      do {
        let data = try NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: false) as NSData?
        colorData = data
      } catch {
        print("Error UserDefaults")
      }
    }
    set(colorData, forKey: key)
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

struct HideRowSeparatorModifier: ViewModifier {
    static let defaultListRowHeight: CGFloat = 44
    var insets: EdgeInsets
    var background: Color
    
    init(insets: EdgeInsets, background: Color) {
        self.insets = insets
        var alpha: CGFloat = 0
        UIColor(background).getWhite(nil, alpha: &alpha)
        assert(alpha == 1, "Setting background to a non-opaque color will result in separators remaining visible.")
        self.background = background
    }
    
    func body(content: Content) -> some View {
        content
            .padding(insets)
            .frame(
                minWidth: 0, maxWidth: .infinity,
                minHeight: Self.defaultListRowHeight,
                alignment: .leading
            )
            .listRowInsets(EdgeInsets())
            .background(background)
    }
}

extension EdgeInsets {
    static let defaultListRowInsets = Self(top: 0, leading: 16, bottom: 0, trailing: 16)
}

extension View {
    func hideRowSeparator(insets: EdgeInsets = .defaultListRowInsets, background: Color = .white) -> some View {
        modifier(HideRowSeparatorModifier(insets: insets, background: background))
    }
}

let minDragTranslationForSwipe: CGFloat = 10
func handleSwipe(translation: CGFloat) -> Bool {
    if translation > minDragTranslationForSwipe {
        return true
    } else {
        return false
    }
    
}

func handleSwipe2(translation: CGFloat) -> Bool {
    if translation < minDragTranslationForSwipe {
        return true
    } else {
        return false
    }
}
