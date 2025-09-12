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
                    } else if user.userHasBasicPremium {
                        // Basic gekauft → nur Gold Abo anzeigen
                        BasicPremiumView()
                            .environmentObject(user)
                    } else {
                        // Noch kein Abo → Basic + Gold Optionen
                        VStack(spacing: 25) {
                            // BASIC Card
                            PremiumCardView(
                                title: "BASIC",
                                price: "1,99€ / Jahr",
                                features: [
                                    ("infinity", "Unendlich viele Semester anlegen"),
                                    ("list.bullet.rectangle", "Semesterübersicht freischalten")
                                ],
                                isSelected: selectedTier == 0,
                                colorScheme: colorScheme
                            ) {
                                selectedTier = 0
                            }

                            // GOLD Card + Option Picker
                            VStack(spacing: 10) {
                                PremiumCardView(
                                    title: "GOLD",
                                    price: selectedGoldOption == 0 ? "2,99€ / Jahr" : "4,99€ einmalig",
                                    features: [
                                        ("crown.fill", "Alles von BASIC"),
                                        ("graduationcap.fill", "Notendurchschnitt aller Semester"),
                                        ("hand.raised.fill", "Keine Werbung"),
                                        ("paintbrush.fill", "Individuelle Farbe & App Icon"),
                                        ("function", "Endnote berechnen"),
                                        ("sparkles", "Probewoche starten")
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
                        }
                        .padding(.horizontal)

                        // Kauf Button
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
            Text("Premium-Bereich").font(.title).bold().padding(.top, 10)
            // swiftlint:disable:next line_length
            Text("Danke für deine Spende. Wähle jetzt deine individuelle App-Farbe und dein persönliches App Icon aus!").padding(.top).padding(.horizontal, 25).multilineTextAlignment(.center)

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

struct BasicPremiumView: View {
    @EnvironmentObject var user: UserStore
    var body: some View {
        VStack {
            Text("Schalte das GOLD-Abo frei").font(.title2).bold().padding(.top, 5)

            HStack {
                ZStack {
                    Ellipse().foregroundColor(.saleColor)
                    Image(systemName: "checkmark.seal").resizable().aspectRatio(contentMode: .fit).frame(width: 20).foregroundColor(.white)
                }.frame(width: 40, height: 40)
                Text("Du hast das Basic-Abo abgeschlossen").foregroundColor(.gray)
            }

            Rectangle().frame(width: screen.width, height: 0.5).foregroundColor(.gray)

            VStack {
                HStack {
                    ZStack {
                        Ellipse().foregroundColor(.saleColor)
                        Image(systemName: "lock.open").resizable().aspectRatio(contentMode: .fit)
                            .frame(width: 20).foregroundColor(.white)
                    }.frame(width: 40, height: 40)
                    Text("Notendurchschnitt aller Semester").padding(.leading, 10)
                    Spacer()

                }.padding(.horizontal, 15).padding(.top, 5)

                HStack {
                    ZStack {
                        Ellipse().foregroundColor(.saleColor)
                        Image(systemName: "tag.slash").resizable().aspectRatio(contentMode: .fit)
                            .frame(width: 20).foregroundColor(.white)
                    }.frame(width: 40, height: 40)
                    Text("Keine Werbung").padding(.leading, 10)
                    Spacer()

                }.padding(.horizontal, 15).padding(.top, 5)

                HStack {
                    ZStack {
                        Ellipse().foregroundColor(.saleColor)
                        Image(systemName: "paintpalette").resizable().aspectRatio(contentMode: .fit)
                            .frame(width: 20).foregroundColor(.white)
                    }.frame(width: 40, height: 40)
                    Text("Individuelle Farbe und App Icon").padding(.leading, 10)
                    Spacer()

                }.padding(.horizontal, 15).padding(.top, 5)

                HStack {
                    ZStack {
                        Ellipse().foregroundColor(.saleColor)
                        Image(systemName: "checkmark.seal").resizable().aspectRatio(contentMode: .fit)
                            .frame(width: 20).foregroundColor(.white)
                    }.frame(width: 40, height: 40)
                    Text("Endnote berechnen").padding(.leading, 10)
                    Spacer()

                }.padding(.horizontal, 15).padding(.top, 5)
            }
            Spacer()
            VStack {

                ZStack {
                    RoundedRectangle(cornerRadius: 40).foregroundColor(.saleColor).offset(y: 40)
                    VStack {
                        ZStack {

                            BuyButtonRectangle()
                            HStack {
                                if checkIfSaleIsActive() {
                                    Text("1,99€ / Jahr").foregroundColor(.white)
                                } else {
                                    Text("1,99€ / Jahr").foregroundColor(.white)
                                }

                            }

                        }.onTapGesture {

                            Products.store.requestProducts { _, products  in
                                guard let products = products else {
                                    return
                                }
                                var productIndex = 0

                                if products[0].productIdentifier == Products.goldSub {
                                    productIndex = 0
                                }

                                if products[1].productIdentifier == Products.goldSub {
                                    productIndex = 1
                                }
                                if products[2].productIdentifier == Products.goldSub {
                                    productIndex = 2
                                }

                                Products.store.buyProduct(products[productIndex]) {_, productId in

                                    guard let productId = productId else {
                                        return
                                    }

                                    if Products.store.isProductPurchased(productId) {
                                        if productId == Products.permanent || productId == Products.goldSub {
                                            user.premium = true
                                        }
                                        if productId == Products.basicSub {
                                            user.basicPremium = true
                                        }
                                        user.userHasBasicPremium = user.basicPremium ||
                                        Products.store.isProductPurchased(Products.basicSub) ? true : false
                                        user.userHasGoldPremium = user.premium ||
                                        Products.store.isProductPurchased(Products.permanent) ||
                                        Products.store.isProductPurchased(Products.goldSub) ? true : false

                                    }
                                }
                            }
                        }

                        Text("oder").font(.callout).foregroundColor(.white).multilineTextAlignment(.center).padding(.horizontal, 10)

                        ZStack {
                            BuyButtonRectangle()
                            HStack {
                                if checkIfSaleIsActive() {
                                    Text("4,99€ / einmalig").foregroundColor(.white).strikethrough()
                                } else {
                                    Text("4,99€ / einmalig").foregroundColor(.white)
                                }

                            }
                        }.onTapGesture {
                            Products.store.requestProducts { _, products  in
                                guard let products = products else {
                                    return
                                }
                                var productIndex = 0
                                if products[0].productIdentifier == Products.permanent {
                                    productIndex = 0
                                }

                                if products[1].productIdentifier == Products.permanent {
                                    productIndex = 1
                                }
                                if products[2].productIdentifier == Products.permanent {
                                    productIndex = 2
                                }

                                Products.store.buyProduct(products[productIndex]) {_, productId in

                                    guard let productId = productId else {
                                        return
                                    }

                                    if Products.store.isProductPurchased(productId) {
                                        if productId == Products.permanent || productId == Products.goldSub {
                                            user.premium = true
                                        }
                                        if productId == Products.basicSub {
                                            user.basicPremium = true
                                        }
                                        user.userHasBasicPremium = user.basicPremium ||
                                        Products.store.isProductPurchased(Products.basicSub) ? true : false
                                        user.userHasGoldPremium = user.premium ||
                                        Products.store.isProductPurchased(Products.permanent) ||
                                        Products.store.isProductPurchased(Products.goldSub) ? true : false
                                    }
                                }
                            }
                        }

                        Link(destination: URL(string: "https://415414.8b.io/privacyAndTerms.html")!, label: {
                            Text("Privacy Policy & Terms Of Use").font(.callout).underline().padding(.top, 5).foregroundColor(.white)
                        })
                        Text("Kauf wiederherstellen").font(.callout).underline().padding(.top, 5)
                            .foregroundColor(.white).padding(.bottom, 20).onTapGesture {
                                Products.store.restorePurchases()
                                if user.premium || Products.store.isProductPurchased(Products.permanent) ||
                                    Products.store.isProductPurchased(Products.goldSub) || user.basicPremium ||
                                    Products.store.isProductPurchased(Products.basicSub) {
                                    user.spendenClicked = false
                                    user.simpleSuccess()
                                } else {
                                    user.simpleError()
                                }
                            }
                        Spacer()
                    }

                }.frame(width: screen.width, height: screen.height * 0.35).padding(.top, 30)

                Spacer()
            }
        }
    }
}
