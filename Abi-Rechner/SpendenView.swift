//
//  SpendenView.swift
//  Abi-Rechner
//
//  Created by Theo Kramer on 29.01.21.
//

import SwiftUI
import StoreKit

func buy(mode: Int, user: UserStore) {
    Products.store.requestProducts { _, products  in
        guard let products = products else {
            return
        }
       var productIndex = 0

        switch mode {
        case 0:
            for i in 0..<3 where products[i].productIdentifier == Products.basicSub {
                    productIndex = i
            }
        case 1:
            for i in 0..<3 where products[i].productIdentifier == Products.goldSub {
                    productIndex = i
            }
        case 2:
            for i in 0..<3 where products[i].productIdentifier == Products.permanent {
                    productIndex = i
            }
        default:
            break
        }

        Products.store.buyProduct(products[productIndex]) {_, productId in

            guard let productId = productId else {
                return
            }

            if Products.store.isProductPurchased(productId) {
                if productId == Products.permanent || productId == Products.goldSub {
                    user.userHasGoldPremium = true
                }
                if productId == Products.basicSub {
                    user.userHasBasicPremium = true
                }
            }
        }
    }

}

struct SpendenView: View {
    @EnvironmentObject var user: UserStore
    @State var mode = 0
    
    @State var selectedColor = Color(UserDefaults.standard.colorForKey(key: "selectedColor") ?? UIColor(Color("Orange")))
    var body: some View {
        ZStack {
            Color.modeColor.edgesIgnoringSafeArea(.bottom)
            
            VStack {
                
                if tablet {
                    ZStack {
                        Color.modeColor
                        HStack {
                            
                            Image(systemName: "xmark").resizable().aspectRatio(contentMode: .fit).frame(width: 30).padding()
                            Spacer()
                            Image(systemName: "")
                        }
                    }.frame(width: screen.width, height: 50).onTapGesture {

                        user.spendenClicked = false
                        user.siteOpened = 0
                        
                    }
                }
                ZStack {
                    if tablet {
                       
                    } else {
                        RoundedRectangle(cornerRadius: 4).frame(width: 37, height: 6).foregroundColor(.gray).padding(.top, 8).onTapGesture {
                            user.spendenClicked = false
                            user.siteOpened = 0
                        }
                        
                    }
                    
                }
                    
                if user.userHasGoldPremium {
                    GoldPremiumView(selectedColor: $selectedColor)
                }
                
                if (user.userHasBasicPremium) && !user.userHasGoldPremium {
                    BasicPremiumView()
                    }
                    
                if !user.userHasBasicPremium && !user.userHasGoldPremium {
                    ZStack {
                        
                        RoundedRectangle(cornerRadius: 32).stroke(Color.gray, lineWidth: 0.5)
                        HStack {
                            
                            ZStack {
                                RoundedRectangle(cornerRadius: 32).foregroundColor(.saleColor).opacity(mode == 0 ? 1 : 0)
                                Text("BASIC").font(.title2).fontWeight(.light).foregroundColor(mode == 1 ? .gray : .white).onTapGesture {
                                    mode = 0
                                }
                            }
                            Spacer()
                            ZStack {
                                RoundedRectangle(cornerRadius: 32).foregroundColor(.saleColor).opacity(mode == 0 ? 0 : 1)
                                Text("GOLD").font(.title2).fontWeight(.light).foregroundColor(mode == 0 ? .gray : .white).onTapGesture {
                                    mode = 1
                                }
                            }
                            
                        }
                    }.padding([.bottom, .horizontal], 10).frame(width: screen.width - 50, height: 50)
                    Text(mode == 0 ? "Mit dem BASIC-Abo des Abi Noten Rechners schaltest du alle grundlegenden Funktionen frei." :
                            "Mit dem GOLD-Abo des Abi Noten Rechners schaltest du alle Funktionen frei.")
                        .multilineTextAlignment(.center).padding(.horizontal, 10).padding(.bottom, 10)
                    
                    Rectangle().frame(width: screen.width, height: 0.5).foregroundColor(.gray)
                    
                    HStack {
                                                ZStack {
                                                    Ellipse().foregroundColor(.saleColor)
                                                    Image(systemName: "lock.open").resizable().aspectRatio(contentMode: .fit)
                                                        .frame(width: 20).foregroundColor(.white)
                                                }.frame(width: 40, height: 40)
                        Text(mode == 0 ? "Unendlich viele Semester anlegen" : "Notendurchschnitt aller Semester").padding(.leading, 10)
                                                Spacer()
                                                
                                            }.padding(.horizontal, 15).padding(.top, 5)
                    
                    HStack {
                                                ZStack {
                                                    Ellipse().foregroundColor(.saleColor)
                                                    Image(systemName: mode == 0 ? "lock.open" : "tag.slash").resizable()
                                                        .aspectRatio(contentMode: .fit).frame(width: 20).foregroundColor(.white)
                                                }.frame(width: 40, height: 40)
                        Text(mode == 0 ? "Semesterübersicht freischalten" : "Keine Werbung").padding(.leading, 10)
                                                Spacer()
                                                
                                            }.padding(.horizontal, 15).padding(.top, 5)
                    
                    if mode != 0 {
                        HStack {
                                                    ZStack {
                                                        Ellipse().foregroundColor(.saleColor)
                                                        Image(systemName: "paintpalette").resizable().aspectRatio(contentMode: .fit)
                                                            .frame(width: 20).foregroundColor(.white)
                                                    }.frame(width: 40, height: 40)
                                                    Text("Individuelle Farbe und App Icon").padding(.leading, 10)
                                                    Spacer()
                                                    
                                                }.padding(.horizontal, 15).padding(.top, 5)
                       
                    }
                    
                    HStack {
                                                ZStack {
                                                    Ellipse().foregroundColor(.saleColor)
                                                    Image(systemName: "checkmark.seal").resizable().aspectRatio(contentMode: .fit)
                                                        .frame(width: 20).foregroundColor(.white)
                                                }.frame(width: 40, height: 40)
                        Text(mode == 0 ? "Starte eine Probewoche" : "End-Note berechnen").padding(.leading, 10)
                                                Spacer()
                                                
                                            }.padding(.horizontal, 15).padding(.top, 5)
                    
                    VStack {
                        Spacer()
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 40).foregroundColor(.saleColor).offset(y: 40)
                            VStack {
                                ZStack {
                                    
                                    BuyButtonRectangle()
                                    HStack {
                                        if checkIfSaleIsActive() {

                                        Text("SALE").foregroundColor(.white)
                                        Text(mode == 0 ? "0,99€ / Jahr" : "1,99€ / Jahr").foregroundColor(.white)
                                        Text("statt").foregroundColor(.white)
                                            Text(mode == 0 ? "1,49€ / Jahr" : "2,99€ / Jahr").foregroundColor(.white).strikethrough()
                                        } else {
                                            Text(mode == 0 ? "1,49€ / Jahr" : "2,99€ / Jahr").foregroundColor(.white)
                                        }
                                       
                                    }
                                    
                                }.onTapGesture {
                                    buy(mode: mode, user: user)

                                }
                                    
                                if mode == 1 {
                                Text("oder").font(.callout).foregroundColor(.white).multilineTextAlignment(.center).padding(.horizontal, 10)
                                }
                                
                                if mode == 1 {
                                    ZStack {
                                        BuyButtonRectangle()
                                        HStack {
                                            if checkIfSaleIsActive() {
                                            Text("SALE").foregroundColor(.white)
                                            Text("2,99€ / einmalig").foregroundColor(.white)
                                            Text("statt").foregroundColor(.white)
                                            Text("4,99€ / einmalig").foregroundColor(.white).strikethrough()
                                            } else {
                                                Text("4,99€ / einmalig").foregroundColor(.white)
                                            }
                                            
                                        }
                                    }.onTapGesture {
                                        buy(mode: mode, user: user)
                                    }
                                }
                                Link(destination: URL(string: "https://415414.8b.io/privacyAndTerms.html")!, label: {
                                    Text("Privacy Policy & Terms Of Use").font(.callout).underline().padding(.top, 5).foregroundColor(.white)
                                })
                                Text("Kauf wiederherstellen").font(.callout).underline().padding(.top, 5)
                                    .foregroundColor(.white).padding(.bottom, 20).onTapGesture {
                                    Products.store.restorePurchases()
                                    if Products.store.isProductPurchased(Products.permanent) || Products.store.isProductPurchased(Products.goldSub) ||
                                        Products.store.isProductPurchased(Products.basicSub) {
                                        user.spendenClicked = false
                                        user.simpleSuccess()
                                    } else {
                                        user.simpleError()
                                    }
                                }
                                Spacer()
                            }

                        }.frame(width: screen.width, height: screen.height * 0.35).padding(.top, 10)
                        
                    }
                
            }
            
            }
        }

    }
}

struct SpendenView_Previews: PreviewProvider {
    static var previews: some View {
        SpendenView()
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
    @Binding var selectedColor: Color
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
                                    Text("SALE").foregroundColor(.white)
                                    Text("1,99€ / Jahr").foregroundColor(.white)
                                    Text("statt").foregroundColor(.white)
                                    Text("2,99€ / Jahr").foregroundColor(.white).strikethrough()
                                } else {
                                    Text("2,99€ / Jahr").foregroundColor(.white)
                                }

                            }

                        }.onTapGesture {

                          buy(mode: 1, user: user)
                        }

                        Text("oder").font(.callout).foregroundColor(.white).multilineTextAlignment(.center).padding(.horizontal, 10)

                        ZStack {
                            BuyButtonRectangle()
                            HStack {
                                if checkIfSaleIsActive() {
                                    Text("SALE").foregroundColor(.white)
                                    Text("2,99€ / einmalig").foregroundColor(.white)
                                    Text("statt").foregroundColor(.white)
                                    Text("4,99€ / einmalig").foregroundColor(.white).strikethrough()
                                } else {
                                    Text("4,99€ / einmalig").foregroundColor(.white)
                                }

                            }
                        }.onTapGesture {
                            buy(mode: 2, user: user)
                        }

                        Link(destination: URL(string: "https://415414.8b.io/privacyAndTerms.html")!, label: {
                            Text("Privacy Policy & Terms Of Use").font(.callout).underline().padding(.top, 5).foregroundColor(.white)
                        })
                        Text("Kauf wiederherstellen").font(.callout).underline().padding(.top, 5)
                            .foregroundColor(.white).padding(.bottom, 20).onTapGesture {
                                Products.store.restorePurchases()
                                if Products.store.isProductPurchased(Products.permanent) ||
                                    Products.store.isProductPurchased(Products.goldSub) ||
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
