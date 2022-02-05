//
//  PhoneHomeView.swift
//  Abi-Rechner
//
//  Created by Theo Kramer on 23.01.21.
//
import CoreData
import SwiftUI
import GoogleMobileAds
import WidgetKit

struct HomeView: View {
    @EnvironmentObject var user: UserStore
    @Environment(\.managedObjectContext) private var viewContext
    @State var noteTeilenClicked = false
    @State var semesterNoten = [SemesternotenItem]()
    @State var abiSemesterNoten = [SemesternotenItem]()
    @State var shareNote = SemesternotenItem(id: UUID(), name: "", semesterNote: -1, semesterPunkte: 0.0, date: Date())
    @State var shareNoteEndnote = false
    @State var openSHareWindow = false
    
    var body: some View {
        ZStack {
            VStack {
                if !tablet {
                    ZStack {
                        Text("Abi Noten Rechner")
                        HStack {
                            Spacer()
                            Image(systemName: "questionmark.circle")
                        }.padding(.trailing, 10).onTapGesture {
                            user.supportClicked = true
                        }
                    }
                    Rectangle().frame(width: screen.width, height: 0.5).foregroundColor(.gray)
                    
                } else {
                    TabletTopBar()
                }
                
                if !checkIfSaleIsActive() && !tablet {
                    if !(user.userHasGoldPremium || user.userHasBasicPremium) {
                    SaleView()
                }
                }
                
                if user.aktuelleNote != 0 {
                    VStack {
                        Text(user.aktuellerName ?? "").font(.title2).bold().padding(.top, 10).padding(.bottom)
                        HStack {
                            Text("Punkte-Durchschnitt").font(.title3)
                            Text("\(String(format: "%.2f", user.aktuellePunkte))").font(.title3).fontWeight(.semibold)
                        }.padding(.horizontal)
                        HStack {
                            Text("Noten-Durchschnitt").font(.title3)
                            Text("\(String(format: "%.2f", user.aktuelleNote))").font(.title3).fontWeight(.semibold)
                        }.padding(.horizontal).padding(.top, 5)
                    }
                }
                
                    ZStack {
                            RoundedRectangle(cornerRadius: 10).foregroundColor(.mainColor)
                            HStack {
                                Text("Neues Semester anlegen").foregroundColor(.modeColor)
                                Spacer()
                                Image(systemName: "chevron.right").foregroundColor(.modeColor)
                            }.padding(.horizontal, 15).onTapGesture {
                                if fetchAllSemesterNoten(viewContext: viewContext)?.count ?? 0 < 1 ||
                                    user.userHasBasicPremium || user.userHasGoldPremium {
                                user.ausrechnen = true
                                    user.siteOpened = 1
                                user.updateMode = false
                                user.aktuellerFaecherArray = fetchMap()
                                user.aktuellerNotenName = ""
                                hideKeyboard()
                                }
                            }
                        if !(fetchAllSemesterNoten(viewContext: viewContext)?.count ?? 0 < 1 || user.userHasBasicPremium || user.userHasGoldPremium) {
                            RoundedRectangle(cornerRadius: 10).foregroundColor(.white).opacity(0.5)
                                .frame(width: tablet ? 300 : screen.width * 0.85, height: 55)
                            Image(systemName: "lock").resizable().aspectRatio(contentMode: .fit).frame(width: 25).onTapGesture {
                                user.spendenClicked = true
                            }
                        }
                    }.frame(width: tablet ? 300 : screen.width * 0.85, height: 55).padding(.horizontal).padding(.top, 12)
                
                if fetchAllSemesterNoten(viewContext: viewContext)?[0] != nil {
                    ZStack {
                        Color.modeColor
                        RoundedRectangle(cornerRadius: 10).stroke(Color.mainColor, lineWidth: 0.5)
                        HStack {
                            Text("\(fetchAllSemesterNoten(viewContext: viewContext)![0].name) bearbeiten").foregroundColor(.mainColor)
                            Spacer()
                            Image(systemName: "chevron.right").foregroundColor(.mainColor)
                        }.padding(.horizontal)
                    }.frame(width: tablet ? 300 : screen.width * 0.85, height: 55).padding(.horizontal).onTapGesture {
                        user.ausrechnen = true
                        user.siteOpened = 1
                        user.aktuellerFaecherArray = fetchAllFaecherFromSemesternote(
                            id: fetchAllSemesterNoten(viewContext: viewContext)![0].id, viewContext: viewContext)
                        user.aktuellerNotenName = fetchAllSemesterNoten(viewContext: viewContext)![0].name
                        user.aktuelleID = fetchAllSemesterNoten(viewContext: viewContext)![0].id.uuidString
                        user.updateMode = true
                    }.padding(.top, 12)
                    
                }
                if !tablet {
                
                ZStack {
                        RoundedRectangle(cornerRadius: 10).foregroundColor(.modeColorSwitch)
                        HStack {
                            Text("Endnote berechnen").foregroundColor(.mainColor )
                            Spacer()
                            Image(systemName: "chevron.right").foregroundColor(.mainColor)
                        }.padding(.horizontal, 15).onTapGesture {
                            if user.userHasGoldPremium {
                            user.abiClicked = true
                            user.updateMode = false
                                user.schnitt = false
                                
                            hideKeyboard()
                            }
                        }
                    if !(user.userHasGoldPremium) {
                        RoundedRectangle(cornerRadius: 10).foregroundColor(.gray)
                            .opacity(0.5).frame(width: tablet ? 300 : screen.width * 0.85, height: 55)
                        Image(systemName: "lock").resizable().aspectRatio(contentMode: .fit)
                            .frame(width: 25).foregroundColor(.modeColor).onTapGesture {
                            user.spendenClicked = true
                        }
                    }
                }.frame(width: tablet ? 300 : screen.width * 0.85, height: 55).padding(.horizontal).padding(.top, 12)
                
                VStack {
                    
                        ZStack {
                            HStack {
                                Text("Semesterübersicht").onTapGesture {
                                    
                                    if user.userHasGoldPremium || user.userHasBasicPremium {
                                    user.verlauf = true
                                        user.schnitt = false
                                    user.updateMode = false
                                        
                                    hideKeyboard()
                                    }
                                }
                                Image(systemName: "chevron.right").padding(.leading, 10)
                            }.foregroundColor(.gray)
                            
                            if !(user.userHasGoldPremium || user.userHasBasicPremium) {
                                RoundedRectangle(cornerRadius: 10).foregroundColor(.gray).opacity(0.5)
                                    .frame(width: tablet ? 300 : screen.width * 0.85, height: 55)
                                Image(systemName: "lock").resizable().aspectRatio(contentMode: .fit).frame(width: 25).onTapGesture {
                                    user.spendenClicked = true
                                    
                                }
                            }
                            
                        }.padding(.top, 12)

                    Spacer()
                    HStack {
                        
                        HStack {
                            Image(systemName: "star")
                            Text("Premium")
                        }.onTapGesture {
                            user.spendenClicked = true
                        }
                        Spacer()
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Note Teilen").foregroundColor(.modeColorSwitch)
                        }.onTapGesture {
                            noteTeilenClicked = true
                            
                        }
                    }.padding()
                }
                }
                if tablet {
                    Spacer()
                }
                if !(user.userHasGoldPremium) {
                            BannerADView(bannerID: "ca-app-pub-3263827122305139/2985316177")
                        .frame(width: screen.width, height: 60).edgesIgnoringSafeArea(.bottom)
                        }
            }
            
        }.sheet(isPresented: $noteTeilenClicked) {
            VStack {
                if !tablet {
                    RoundedRectangle(cornerRadius: 4).frame(width: 37, height: 6).foregroundColor(.gray).padding(.top, 8).onTapGesture {
                        noteTeilenClicked = false
                        
                    }
                    Text("Note teilen").font(.title).bold().padding(.top, 10)
                    Text("Wähle jetzt eine Note aus, die du teilen möchtest.")
                        .padding(.top).padding(.horizontal, 25).multilineTextAlignment(.center).padding(.bottom, 20)
                    
                    ScrollView(showsIndicators: false) {
                        if user.endNoteAbi != 0 {
                            ZStack {
                                if shareNoteEndnote {
                                    RoundedRectangle(cornerRadius: 10).foregroundColor(.mainColor2)
                                } else {
                                    RoundedRectangle(cornerRadius: 5).stroke(Color.gray, lineWidth: 0.5).foregroundColor(.mainColor2)
                                }
                                
                                Text("Endnote: \(String(format: "%.2f", user.endNoteAbi))")
                                    .foregroundColor(shareNoteEndnote ? .modeColor : .modeColorSwitch)
                            }.frame(width: 200, height: 60).onTapGesture {
                                if #available(iOS 15, *) {
                                    shareNote = SemesternotenItem(id: UUID(), name: "Endnote", semesterNote: user.endNoteAbi,
                                                                  semesterPunkte: user.endPunkteAbi, date: Date.now)
                                } else {
                                }
                                shareNoteEndnote = true
                            }
                        }
                        
                        ForEach(semesterNoten, id: \.id) { item in
                            ZStack {
                                
                                if shareNote.id == item.id {
                                    RoundedRectangle(cornerRadius: 10).foregroundColor(.mainColor2)
                                } else {
                                    RoundedRectangle(cornerRadius: 5).stroke(Color.gray, lineWidth: 0.5).foregroundColor(.mainColor2)
                                }
                                
                                HStack {
                                    Text(item.name)
                                    Text("\(String(format: "%.2f", item.semesterNote))")
                                    
                                }.foregroundColor(shareNote.id == item.id ? .modeColor : .modeColorSwitch)
                            }.frame(width: 200, height: 60).onTapGesture {
                                shareNote = item
                                shareNoteEndnote = false
                            }
                        }
                    }
                    ZStack {
                        RoundedRectangle(cornerRadius: 10).foregroundColor(.mainColor2)
                        Text("Teilen").foregroundColor(.modeColor).font(tablet ? .title : .headline)
                    }.frame(width: tablet ? 280 : 150, height: tablet ? 80 : 50).onTapGesture {
                        
                        if shareNote.semesterNote != -1 {
                            user.simpleSuccess()
                            noteTeilenClicked = false
                            openSHareWindow = true
                        } else {
                            user.simpleError()
                        }
                    }
                    Spacer()
                }
            }
        }.onChange(of: user.sendEmail) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                if user.sendEmail {
                    EmailService.shared.sendEmail(subject: "Support-Anfrage", body: "Hallo liebes Abi Noten Rechner Team,", to: "noten.rechner@t-online.de") { (isWorked) in
                                    if !isWorked { // if mail couldn't be presented
                                        // do action
                                    }
                    }
                }
            }
        }.onAppear {
            semesterNoten = fetchAllSemesterNoten(viewContext: viewContext) ?? semesterNoten
            print(semesterNoten.count)
            if semesterNoten.count >= 4 {
                for i in 0..<4 {
                    abiSemesterNoten.append(semesterNoten[i])
                }
            } else {
                abiSemesterNoten = semesterNoten
            }
            for i in user.aktuellerAbiNotenArray.indices {
                if user.pruefungsNamenArray != [] {
                    user.aktuellerAbiNotenArray[i].name = user.pruefungsNamenArray[i]
                }
                if user.pruefungsNotenArray != [] {
                    user.aktuellerAbiNotenArray[i].note = user.pruefungsNotenArray[i]
                }
            }
        }.onChange(of: openSHareWindow) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                if openSHareWindow {

                        var shareText: String? {
                            // swiftlint:disable:next line_length
                            return "Hi, ich habe gerade \(shareNoteEndnote ? "meine Endnote" : "eine Semesternote") mit dem Abi Noten Rechner ausgerechnet. Ich habe einen Notenschnitt von \(String(format: "%.2f", shareNote.semesterNote))! Wenn du auch deine Noten ausrechnen möchtest, kannst du dir den Abi Noten Rechner kostenlos im App Store herunterladen: https://apps.apple.com/us/app/abi-noten-rechner/id1550466460"
                       }
                               guard let data = shareText else { return }
                               let av = UIActivityViewController(activityItems: [data], applicationActivities: nil)
                               UIApplication.shared.windows.first?.rootViewController?.present(av, animated: true, completion: nil)
                           openSHareWindow = false
                    }
                }
            
        }.onChange(of: noteTeilenClicked) { _ in
            semesterNoten = fetchAllSemesterNoten(viewContext: viewContext) ?? semesterNoten
            print(semesterNoten.count)
            if semesterNoten.count >= 4 {
                for i in 0..<4 {
                    abiSemesterNoten.append(semesterNoten[i])
                }
            } else {
                abiSemesterNoten = semesterNoten
            }
            for i in user.aktuellerAbiNotenArray.indices {
                if user.pruefungsNamenArray != [] {
                    user.aktuellerAbiNotenArray[i].name = user.pruefungsNamenArray[i]
                }
                if user.pruefungsNotenArray != [] {
                    user.aktuellerAbiNotenArray[i].note = user.pruefungsNotenArray[i]
                }
                
            }
        }
    }
}

struct BannerADView: UIViewRepresentable {
    
    var bannerID: String
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: UIViewRepresentableContext<BannerADView>) -> GADBannerView {
        let banner = GADBannerView(adSize: kGADAdSizeBanner)
        banner.adUnitID = bannerID
        banner.rootViewController = UIApplication.shared.windows.first?.rootViewController
        banner.load(GADRequest())
        banner.delegate = context.coordinator
        return banner
        
    }
    func updateUIView(_ uiView: GADBannerView, context: UIViewRepresentableContext<BannerADView>) {
    }
    
    class Coordinator: NSObject, GADBannerViewDelegate {
        var parent: BannerADView
        init(_ parent: BannerADView) {
            self.parent = parent
        }
        func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
            print("Did Receive Ad")
            
        }
        func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
            print("Failed Receive Ad")
        }
    }
    
}

struct PhoneHomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
