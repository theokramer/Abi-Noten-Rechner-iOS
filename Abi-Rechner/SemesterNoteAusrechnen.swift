//
//  SemesterNoteAusrechnen.swift
//  Abi-Rechner
//
//  Created by Theo Kramer on 23.01.21.
//

import SwiftUI
import CoreData
import WidgetKit
import GoogleMobileAds

struct SemesterNoteAusrechnen: View {
    @State var showDeleteAlert = false
    @State var errorCalc = false
    @EnvironmentObject var user: UserStore
    
    func warnUser() {
        showDeleteAlert = true
        hideKeyboard()
        user.simpleWarning()
    }
    
    func checkIfTrue(quick: Bool) {
        if calcPunkte() == nil {
            errorCalc = true
            user.simpleError()
        } else {
            if calcNote(punkte: calcPunkte()!) > 0 {
                if saveSemesterNoten(punkte: calcPunkte()!, note: calcNote(punkte: calcPunkte()!)) {
                    user.aktuelleNote = calcNote(punkte: calcPunkte()!)
                    user.aktuellePunkte = calcPunkte()!
                    user.aktuellerName = user.aktuellerNotenName
                    if !quick {
                        user.updateMode = false
                        user.schnitt = true
                        user.siteOpened = 0
                        user.ausrechnen = false
                        user.showAd = true
                        hideKeyboard()
                        user.simpleSuccess()
                    }
                    print("Hallo")
                    let note = Double(round(100*user.aktuelleNote)/100)
                    
                    if let userDefaults = UserDefaults(suiteName: "group.notenRechner.widgetcache") {
                        userDefaults.setValue(note, forKey: "text")
                    }
                    
                    WidgetCenter.shared.reloadAllTimelines()
                    print("Geschafft")
                    
                }
                
            } else {
                let semesterRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Semesternote")
                do {
                    let results = try viewContext.fetch(semesterRequest)
                    if !results.isEmpty {
                        for i in results {
                            if let result = i as? NSManagedObject {
                                if result.value(forKey: "id") != nil {
                                    guard let thisID = result.value(forKey: "id") as? UUID else {
                                        return
                                    }
                                    if thisID.uuidString == user.aktuelleID {
                                        viewContext.delete(result)
                                    }
                                }
                            }
                        }
                    }
                } catch {
                    print(error.localizedDescription)
                }
                do {
                    try viewContext.save()
                } catch {
                    print(error.localizedDescription)
                }
                if !quick {
                    user.ausrechnen = false
                    user.updateMode = false
                    user.simpleSuccess()
                }

                
            }
            
        }
    }
    
    @Environment(\.managedObjectContext) private var viewContext
    func clearAll() {
        user.aktuellerNotenName = ""
        user.aktuellerFaecherArray.removeAll()
        user.aktuellerFaecherArray = fetchMap()
        hideKeyboard()
    }
    func calcPunkte() -> Double? {
        var punkteSchnitt = 0.0
        var count = 0.0
        var alarm = true
        
        for i in user.aktuellerFaecherArray where !i.note.isEmpty {

                if Double(i.note)! > 15 {
                    return nil
                } else {
                    punkteSchnitt += Double(i.note)!
                    count += 1
                    if i.gewichtung == "2" {
                        punkteSchnitt += Double(i.note)!
                        count += 1
                    }
                    
                }
                alarm = false
            
        }
        if alarm == true {
            print("huhu")
            return nil
        }
        punkteSchnitt /= count
        return punkteSchnitt
    }
    func calcNote(punkte: Double) -> Double {
        var notenSchnitt = 0.0
        if punkte != 0 {
            notenSchnitt = (17 - punkte)/3
        } else {
            notenSchnitt = 6.0
        }
        
        return notenSchnitt
    }
    
    func saveSemesterNoten(punkte: Double, note: Double) -> Bool {
        
        if user.updateMode {
            let semesterRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Semesternote")
            do {
                let results = try viewContext.fetch(semesterRequest)
                if !results.isEmpty {
                    for i in results {
                        if let result = i as? NSManagedObject {
                            if result.value(forKey: "id") != nil {
                                guard let thisID = result.value(forKey: "id") as? UUID else {
                                    return false
                                }
                                if thisID.uuidString == user.aktuelleID {
                                    viewContext.delete(result)
                                    
                                    let neueNote = Semesternote(context: viewContext)
                                    neueNote.id = UUID()
                                    
                                    neueNote.name = user.aktuellerNotenName
                                    neueNote.date = Date()
                                    neueNote.semesterPunkte = punkte
                                    neueNote.semesterNote = note
                                    var neueFaecher = [Fach(context: viewContext)]
                                    for j in user.aktuellerFaecherArray {
                            //            if i.note != "" {
                                            let neuesFach = Fach(context: viewContext)
                                            neuesFach.id = j.id
                                            neuesFach.name = j.name
                                            neuesFach.gewichtung = Int64(j.gewichtung)!
                                            neuesFach.note = j.note
                                            neuesFach.alsSemesterFach = neueNote
                                            neuesFach.position = j.position
                                            neueFaecher.append(neuesFach)
                                            
                            //            }
                                        
                                    }
                                    neueNote.faecher?.adding(neueFaecher)
                                    do {
                                        try viewContext.save()
                                        return true
                                    } catch {
                                        print(error.localizedDescription)
                                        return false
                                    }
                                
                            }
                            
                        }
                    }
                }
                }

            do {
                try viewContext.save()
                return true
            } catch {
                print(error.localizedDescription)
                return false
            }
            } catch {
                print(error.localizedDescription)
                return false
            }
            
        } else {
            let neueNote = Semesternote(context: viewContext)
            neueNote.id = UUID()
            user.aktuelleID = neueNote.id!.uuidString
            neueNote.name = user.aktuellerNotenName
            neueNote.date = Date()
            neueNote.semesterPunkte = punkte
            neueNote.semesterNote = note
            var neueFaecher = [Fach(context: viewContext)]
            for i in user.aktuellerFaecherArray {
    //            if i.note != "" {
                    let neuesFach = Fach(context: viewContext)
                    neuesFach.id = i.id
                    neuesFach.name = i.name
                    neuesFach.gewichtung = Int64(i.gewichtung)!
                    neuesFach.note = i.note
                    neuesFach.position = i.position
                    neuesFach.alsSemesterFach = neueNote
                    neueFaecher.append(neuesFach)
                    
    //            }
                
            }
            neueNote.faecher?.adding(neueFaecher)
            do {
                try viewContext.save()
                return true
            } catch {
                print(error.localizedDescription)
                return false
            }
        }
        
    }
    
    
    
    @Environment(\.scenePhase) var scenePhase

    
    var body: some View {
        ZStack {
            Color.modeColor.onTapGesture {
                hideKeyboard()
            }
            VStack {
                if tablet {
                    TabletTopBar()
                } else {
                            VStack {
                                ZStack {
                                    HStack {
                                        ZStack {
                                            Rectangle().frame(width: 20, height: 20).foregroundColor(.modeColor)
                                            ArrowLeft().onTapGesture {
                                                user.ausrechnen = false
                                            }
                                        }.onTapGesture {
                                            
                                            if calcNote(punkte: calcPunkte()!) > 0 {
                                                
                                            } else {
                                                let semesterRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Semesternote")
                                                do {
                                                    let results = try viewContext.fetch(semesterRequest)
                                                    if !results.isEmpty {
                                                        for i in results {
                                                            if let result = i as? NSManagedObject {
                                                                if result.value(forKey: "id") != nil {
                                                                    guard let thisID = result.value(forKey: "id") as? UUID else {
                                                                        return 
                                                                    }
                                                                    if thisID.uuidString == user.aktuelleID {
                                                                        viewContext.delete(result)
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                } catch {
                                                    print(error.localizedDescription)
                                                }
                                                do {
                                                    try viewContext.save()
                                                } catch {
                                                    print(error.localizedDescription)
                                                }
                                                
                                            }
                                            
                                            user.ausrechnen = false
                                            user.updateMode = false
                                            hideKeyboard()
                                        }
                                        Spacer()
                                    }
                                    Text(user.updateMode ? "\(user.aktuellerNotenName) bearbeiten" : "Neues Semester anlegen")
                                }
                                Rectangle().frame(width: screen.width, height: 0.5).foregroundColor(.gray)
                    
                            }
                }
                if !(user.userHasGoldPremium) {
                            BannerADView(bannerID: "ca-app-pub-3263827122305139/3463838331")
                        .frame(width: screen.width, height: 60).edgesIgnoringSafeArea(.bottom)
                        }
                HStack {
                    VStack {
                        TextField("Name: z.B. 1. Semester", text: $user.aktuellerNotenName).font(.title3)
                        HStack {
                            Rectangle().frame(width: tablet ? 300 : screen.width * 0.7, height: 0.5).padding(.top, -6).foregroundColor(.gray)
                            Spacer()
                        }
                    }
                    Spacer()
                }.padding(.top, 20).padding(.horizontal, 20)
                
                ZStack {
                    ZStack {
                        
                        HStack {
                            Spacer()
                            Text("Punkte").font(.caption)
                            Spacer()
                        }
                    }.frame(width: 80, height: 30)
                    
                        HStack {
                            Spacer()
                            
                            Text("Gewichtung").padding(.trailing, tablet ? 100 : 20).font(.caption)
                            
                        }
                        
                }
                ScrollView {
                    ForEach(0..<user.aktuellerFaecherArray.count) { index in
                        ZStack {
                            Color.modeColor.onTapGesture {
                                hideKeyboard()
                            }
                            ZStack {
                                RoundedRectangle(cornerRadius: 5).stroke(Color.gray, lineWidth: 0.5).foregroundColor(.modeColor)
                                HStack {
                                    Spacer()
                                    TextField("0", text: $user.aktuellerFaecherArray[index].note)
                                        .multilineTextAlignment(.center).keyboardType(.numberPad)
                                    Spacer()
                                }
                            }.frame(width: 40, height: 30)
                            HStack {
                                    VStack {
                                        TextField("\(index + 1). Fach", text: $user.aktuellerFaecherArray[index].name).font(.headline)
                                        HStack {
                                            Rectangle().frame(height: 0.5).padding(.top, -6).foregroundColor(.gray)
                                            Spacer()
                                        }
                                    }.frame(width: screen.width * 0.35).padding(.leading, 10)
                                    
                                    Spacer()
                            }.offset(y: 5)
                            
                                HStack {
                                    Spacer()
                                    ZStack {
                                        Color.modeColor
                                        RoundedRectangle(cornerRadius: 5).stroke(Color.gray, lineWidth: 0.5).foregroundColor(.modeColor)
                                        HStack {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 5).foregroundColor(.mainColor).frame(width: 40)
                                                    .opacity(user.aktuellerFaecherArray[index].gewichtung == "1" ? 1 : 0)
                                                if user.aktuellerFaecherArray[index].gewichtung == "1" {
                                                    Text("1x").foregroundColor(.modeColor)
                                                } else {
                                                    Text("1x").foregroundColor(.gray)
                                                }
                                                
                                            }
                                            Spacer()
                                        }
                                        HStack {
                                            Spacer()
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 5).foregroundColor(.mainColor).frame(width: 40)
                                                    .opacity(user.aktuellerFaecherArray[index].gewichtung == "2" ? 1 : 0)
                                                if user.aktuellerFaecherArray[index].gewichtung == "2" {
                                                    Text("2x").foregroundColor(.modeColor)
                                                } else {
                                                    Text("2x").foregroundColor(.gray)
                                                }
                                            }
                                            
                                        }
                                        
                                    }.frame(width: 80, height: 30).padding(.trailing, tablet ? 100 : 20).onTapGesture {
                                        if user.aktuellerFaecherArray[index].gewichtung == "1" {
                                            user.aktuellerFaecherArray[index].gewichtung = "2"
                                            return
                                        }
                                        if user.aktuellerFaecherArray[index].gewichtung == "2" {
                                            user.aktuellerFaecherArray[index].gewichtung = "1"
                                        }
                                        
                                    }
                                }
                            
                        }.padding(.top, tablet ? 20 : 5)
                    }
                }
                
                HStack {
                    Spacer()
                    ZStack {
                        RoundedRectangle(cornerRadius: 10).stroke(Color.mainColor, lineWidth: 0.5).foregroundColor(.modeColor)
                        HStack {
                            Image(systemName: "arrow.counterclockwise").resizable().aspectRatio(contentMode: .fit)
                                .frame(width: tablet ? 22 : 17).padding(.leading, 3).foregroundColor(.mainColor)
                            Spacer()
                            Text("Zurücksetzen").foregroundColor(.mainColor).padding(.trailing).font(tablet ? .title : .headline)
                            
                        }.padding(.horizontal, tablet ? 10 : 3)
                    }.frame(width: tablet ? 250 : 160, height: tablet ? 50 : 40).onTapGesture(perform: warnUser)
                        .alert(isPresented: $showDeleteAlert) {
                        Alert(title: Text("Zurücksetzen"), message: Text("Möchtest du diese Seite wirklich zurücksetzen?"),
                              primaryButton: .destructive(Text("Ja"), action: clearAll),
                              secondaryButton: .cancel(Text("Nein")))
                }
                    Spacer()
                    ZStack {
                        RoundedRectangle(cornerRadius: 10).foregroundColor(.mainColor)
                        Text(user.updateMode ? "Aktualisieren" : "Ausrechnen").foregroundColor(.modeColor).font(tablet ? .title : .headline)
                    }.frame(width: tablet ? 250 : 120, height: tablet ? 50 : 40).onTapGesture(perform: {checkIfTrue(quick: false)}).alert(isPresented: $errorCalc) {
                        Alert(title: Text("Falsche Punktzahl"),
                              message: Text("Es sieht so aus als hättest du irgendwo eine falsche Punktzahl oder gar keine eingegeben"),
                              dismissButton: .cancel())
                    }
                    Spacer()
                }.padding(.top)
                Spacer()
            }
            
        }.onAppear {
            
        }
        
    }
}

struct SemesterNoteAusrechnen_Previews: PreviewProvider {
    static var previews: some View {
        SemesterNoteAusrechnen()
            .previewDevice("iPhone 8")
            .environmentObject(UserStore())
    }
}

struct FachItem: Identifiable {
    var id: UUID
    var name: String
    var note: String
    var gewichtung: String
    var position: Int64
}

struct AbiItem: Identifiable {
    var id: UUID
    var name: String
    var note: String
}

func fetchMap() -> [FachItem] {
    print("ICH FETCHE!")
var numbers: [FachItem] = []
    for i in 1..<15 {
        numbers.append(FachItem.init(id: UUID(), name: "", note: "", gewichtung: "1", position: Int64(i)))
    }
return numbers
}

func fetchMapAbi() -> [AbiItem] {
var numbers: [AbiItem] = []
    for _ in 1..<6 {
        numbers.append(AbiItem.init(id: UUID(), name: "", note: ""))
    }
return numbers
}

struct ArrowLeft: View {
    var body: some View {
        ZStack {
            Rectangle().frame(width: 20, height: 20).foregroundColor(.modeColor)
            Image(systemName: "chevron.left").resizable().aspectRatio(contentMode: .fit).frame(width: 14).foregroundColor(.gray).padding(.leading)
        }
    }
}
