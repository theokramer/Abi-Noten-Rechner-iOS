//
//  SpendenView.swift
//  Abi-Rechner
//
//  Created by Theo Kramer on 29.01.21.
//

import SwiftUI
import StoreKit

struct PremiumView: View {
    @EnvironmentObject var user: UserStore
    @State private var selectedTier: Int? = nil
    @State private var selectedGoldOption: Int = 0
    @State private var selectedColor = Color(UserDefaults.standard.colorForKey(key: "selectedColor") ?? UIColor.orange)
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            Color.modeColor.edgesIgnoringSafeArea(.all)
            
            

            ScrollView {
                VStack(spacing: 30) {
                    Text("Premium Features")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .padding(.top, 40)
                    
                    if user.userHasGoldPremium {
                        // GOLD Premium-Bereich
                        GoldPremiumView(selectedColor: $selectedColor)
                            .environmentObject(user)
                    } else {
                        // Noch kein Gold → Zeige nur GOLD Card + Hinweis für Basic
                        VStack(spacing: 25) {
                            
                            if user.userHasBasicPremium {
                                // Hinweis, dass Basic bereits gekauft wurde
                                HStack {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundColor(.saleColor)
                                        .frame(width: 30, height: 30)
                                    Text("Du hast das Basic-Abo bereits abgeschlossen")
                                        .foregroundColor(.gray)
                                        .font(.headline)
                                    Spacer()
                                }
                                .padding()
                                .background(Color.gray.opacity(0.15))
                                .cornerRadius(15)
                                .padding(.horizontal)
                            } else {
                                // BASIC Card nur anzeigen, wenn es noch nicht gekauft wurde
                                PremiumCardView(
                                    title: "BASIC",
                                    price: "1,99€ / Jahr",
                                    features: [
                                        ("infinity", "Unendlich viele Semester anlegen"),
                                        ("list.bullet.rectangle", "Semesterübersicht freischalten"),
                                        ("hand.raised.fill", "Keine Werbung"),
                                    ],
                                    isSelected: selectedTier == 0,
                                    colorScheme: colorScheme
                                ) {
                                    selectedTier = 0
                                }
                                .padding(.horizontal)
                            }
                            
                            // GOLD Card + Option Picker
                            VStack(spacing: 10) {
                                PremiumCardView(
                                    title: "GOLD",
                                    price: selectedGoldOption == 0 ? "2,99€ / Jahr" : "4,99€ einmalig",
                                    features: [
                                        ("crown.fill", "Alles von BASIC"),
                                        ("graduationcap.fill", "Notendurchschnitt aller Semester"),
                                        ("paintbrush.fill", "Individuelle Farbe & App Icon"),
                                        ("function", "Endnote berechnen"),
                                        ("sparkles", "Probewoche starten"),
                                        ("chart.bar.doc.horizontal", "Szenario Planer • NEW") // NEUES FEATURE
                                    ],
                                    isSelected: selectedTier == 1,
                                    colorScheme: colorScheme
                                ) {
                                    selectedTier = 1
                                }

                                if selectedTier == 1 {
                                    Picker("Option", selection: $selectedGoldOption) {
                                        Text("Jährlich").tag(0)
                                        Text("Lifetime").tag(1)
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.horizontal)
                            
                            // Kauf Button wie gehabt
                            if let tier = selectedTier {
                                Button(action: {
                                    purchase(tier: tier, goldOption: selectedGoldOption)
                                }) {
                                    Text(tier == 0 ? "BASIC kaufen" : selectedGoldOption == 0 ? "GOLD Jährlich kaufen" : "GOLD Lifetime kaufen")
                                        .bold()
                                        .frame(maxWidth: .infinity, minHeight: 60)
                                        .background(Color.saleColor)
                                        .foregroundColor(.white)
                                        .cornerRadius(20)
                                        .shadow(radius: 5)
                                }
                                .padding(.horizontal)
                            }
                        }
                    }

                    // Restore & Policy unverändert

                    if(!user.userHasGoldPremium) {
                        // Restore & Policy
                        VStack(spacing: 10) {
                            Text("Kauf wiederherstellen")
                                .underline()
                                .foregroundColor(.blue)
                                .onTapGesture { restorePurchases() }

                            Link("Privacy Policy & Terms of Use",
                                 destination: URL(string: "https://415414.8b.io/privacyAndTerms.html")!)
                                .foregroundColor(.blue)
                        }
                        .padding(.vertical, 20)
                    }
                    
                }
            }
        }
    }

    private func purchase(tier: Int, goldOption: Int) {
        Products.store.requestProducts { _, products in
            guard let products = products else { return }
            
            var productId = ""
            if tier == 0 {
                productId = Products.basicSub
            } else {
                productId = goldOption == 0 ? Products.goldSub : Products.permanent
            }

            if let product = products.first(where: { $0.productIdentifier == productId }) {
                Products.store.buyProduct(product) { _, _ in
                    // nach erfolgreichem Kauf direkt Status setzen
                    updatePremiumStatus()
                }
            }
        }
    }

    private func restorePurchases() {
        Products.store.restorePurchases()
        updatePremiumStatus()
    }

    private func updatePremiumStatus() {
        user.userHasGoldPremium = user.premium ||
            Products.store.isProductPurchased(Products.permanent) ||
            Products.store.isProductPurchased(Products.goldSub)
        user.userHasBasicPremium = user.basicPremium ||
            Products.store.isProductPurchased(Products.basicSub)
    }
}


// MARK: - Premium Card
struct PremiumCardView: View {
    var title: String
    var price: String
    var features: [(String, String)]
    var isSelected: Bool
    var colorScheme: ColorScheme
    var onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(title)
                .font(.title2)
                .bold()
                .foregroundColor(colorScheme == .dark ? .white : .black)
            
            ForEach(features, id: \.1) { feature in
                HStack(spacing: 10) {
                    ZStack {
                        Ellipse().fill(Color.saleColor).frame(width: 36, height: 36)
                        Image(systemName: feature.0)
                            .foregroundColor(.white)
                            .frame(width: 18, height: 18)
                    }
                    Text(feature.1)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .font(.body)
                    Spacer()
                }
            }
            
            Text(price)
                .font(.headline)
                .bold()
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .padding(.top, 10)
            
        }
        .padding()
        .background(isSelected ? Color.saleColor.opacity(0.3) : Color.gray.opacity(0.15))
        .cornerRadius(20)
        .shadow(radius: isSelected ? 10 : 3)
        .onTapGesture { onTap() }
        .animation(.spring(), value: isSelected)
    }
}



struct BuyButtonRectangle: View {
    var body: some View {
        ZStack {
            Color.black
            RoundedRectangle(cornerRadius: 20).stroke(Color.white)
        }.frame(width: checkIfSaleIsActive() ? screen.width * 0.97 : screen.width * 0.9, height: 60).cornerRadius(20)
    }
}

struct GoldPremiumView: View {
    @EnvironmentObject var user: UserStore   // <<< hinzufügen
    @Binding var selectedColor:Color
    var body: some View {
        VStack {

            Text("Farbe auswählen").font(.headline).padding(.top).foregroundColor(.modeColorSwitch).padding(.bottom, 10)

            ColorPicker("Farbe auswählen", selection: $selectedColor).foregroundColor(.modeColor)
                .frame(maxWidth: screen.width - 100, maxHeight: 50).padding(.horizontal, 10)
                .padding(.vertical, 5).background(selectedColor).cornerRadius(10)
                .onChange(of: selectedColor, perform: { _ in
                    let color = UIColor(selectedColor)
                    UserDefaults.standard.setColor(color: color, forKey: "selectedColor")
                    Color.mainColor = selectedColor
                    user.objectWillChange.send()  // <<< erzwingt Redraw
                })

            Text("App Icon auswählen").font(.headline).padding(.top).foregroundColor(.modeColorSwitch)

            VStack {
                HStack {

                    Button {
                        UIApplication.shared.setAlternateIconName(nil)
                    } label: {
                        Image("AppIconImage").resizable().aspectRatio(contentMode: .fit)
                            .cornerRadius(20)
                    }.padding(.horizontal, 5).frame(maxWidth: 200)

                    Button {
                        UIApplication.shared.setAlternateIconName("DarkIcon")
                    } label: {
                        Image("DarkImage").resizable().aspectRatio(contentMode: .fit)
                            .cornerRadius(20)
                    }.padding(.horizontal, 5).frame(maxWidth: 200)

                    Button {
                        UIApplication.shared.setAlternateIconName("OrangeIcon")
                    } label: {
                        Image("OrangeImage").resizable().aspectRatio(contentMode: .fit)
                            .cornerRadius(20)
                    }.padding(.horizontal, 5).frame(maxWidth: 200)

                }.padding(.horizontal, 30).padding(.top, 20)

                HStack {

                    Button {
                        UIApplication.shared.setAlternateIconName("LightBlueIcon")
                    } label: {
                        Image("LightBlueImage").resizable().aspectRatio(contentMode: .fit)
                            .cornerRadius(20)
                    }.padding(.horizontal, 5).frame(maxWidth: 200)

                    Button {
                        UIApplication.shared.setAlternateIconName("PurpleLightBlueIcon")
                    } label: {
                        Image("PurpleLightBlueImage").resizable().aspectRatio(contentMode: .fit)
                            .cornerRadius(20)
                    }.padding(.horizontal, 5).frame(maxWidth: 200)

                    Button {
                        UIApplication.shared.setAlternateIconName("LightRedIcon")
                    } label: {
                        Image("LightRedImage").resizable().aspectRatio(contentMode: .fit)
                            .cornerRadius(20)
                    }.padding(.horizontal, 5).frame(maxWidth: 200)
                    //
                }.padding(.horizontal, 30).padding(.top, 10)
            }

            Spacer()
        }
    }
}
