//
//  SemesterNotenVerlauf.swift
//  Abi-Rechner
//
//  Created by Theo Kramer on 23.01.21.
//

import SwiftUI
import CoreData

extension String {
    func toDate() -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy  hh:mm"
        return formatter.date(from: self)
    }
}

extension Date {
    func toStringDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .none
        formatter.dateStyle = .medium
        formatter.timeZone = TimeZone.current
        let dateString = formatter.string(from: date)
        return dateString
    }
}

struct SemesterNotenVerlauf: View {
    @EnvironmentObject var user: UserStore
    @State var id = ""
    @Environment(\.managedObjectContext) private var viewContext
    
    @State var noteTeilenClicked = false
    
    @State var abiSemesterNoten = [SemesternotenItem]()
    @State var shareNote = SemesternotenItem(id: UUID(), name: "", semesterNote: -1, semesterPunkte: 0.0, date: Date())
    @State var shareNoteEndnote = false
    @State var openSHareWindow = false
    
    func deleteSemesternote(semesternotenItem: SemesternotenItem) {
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
                            if thisID.uuidString == semesternotenItem.id.uuidString {
                                viewContext.delete(result)
                                
                        }
                        
                    }
                }
            }
            }

        do {
            try viewContext.save()
        } catch {
            print(error.localizedDescription)
            
        }
        } catch {
            print(error.localizedDescription)
            
        }
    }
    
    func gesamtNotenSchnitt() -> Double {
        var gesamtSchnitt = 0.0
        var count = 0
        for i in fetchAllSemesterNoten(viewContext: viewContext) ?? [] {
            gesamtSchnitt += i.semesterNote
            count += 1
        }
        gesamtSchnitt /= Double(count)
        return gesamtSchnitt
    }

    func gesamtPunkteSchnitt() -> Double {
        var gesamtSchnitt = 0.0
        var count = 0
        for i in fetchAllSemesterNoten(viewContext: viewContext) ?? [] {
            gesamtSchnitt += i.semesterPunkte
            count += 1
        }
        gesamtSchnitt /= Double(count)
        return gesamtSchnitt
    }
    
    func gesamtPunkteSchnittAbi() -> Double {
        var gesamtSchnitt = 0.0
        var count = 0
        for i in fetchAllSemesterNoten(viewContext: viewContext) ?? [] {
           if checkIfItemIsInArray(array: abiSemesterNoten, item: i) {
                gesamtSchnitt += i.semesterPunkte
                count += 1
            }
        }
        gesamtSchnitt /= Double(count)
        return gesamtSchnitt
    }
    
    func calcPunkte() -> Double? {
        var punkteSchnitt = 0.0
        var count = 0.0
        
        for i in user.aktuellerAbiNotenArray where !i.note.isEmpty {

                if Double(i.note)! > 15 {
                    return nil
                } else {
                    punkteSchnitt += Double(i.note)!
                    count += 1
                }

        }
        punkteSchnitt /= count
        return punkteSchnitt
    }
    
    func checkIfAbiNotenArrayIsValid() -> Bool {
        for i in user.aktuellerAbiNotenArray {
            if !i.note.isEmpty {
                return false
            } else {
                return true
            }
        }
        return true
    }
    
    func calcEndPunkteSchnitt() -> Double? {
        var punkteSchnitt = 0.0
        let semesterPunkteSchnitt = calcPunkte()
        let abiPunkteSchnitt = gesamtPunkteSchnittAbi()
        
        if abiSemesterNoten.count != 4 || !checkIfAbiNotenArrayIsValid() || semesterPunkteSchnitt == nil {
            return nil
        } else {
            punkteSchnitt += semesterPunkteSchnitt!
            punkteSchnitt += abiPunkteSchnitt * 2
            punkteSchnitt /= 3
        }
    
        return punkteSchnitt
    }
    
    func stoppBearbeitung() {
        user.itemClicked = false
    }
    
    func calcNote(punkte: Double) -> Double? {
        var notenSchnitt = 0.0
        
        if punkte == -1 {
            return nil
        }
        
        if punkte != 0 {
            notenSchnitt = (17 - punkte)/3
        } else {
            notenSchnitt = 6.0
        }
        
        return notenSchnitt
    }
    
    func checkIfItemIsInArray(array: [SemesternotenItem], item: SemesternotenItem) -> Bool {
        if array.contains(where: {$0.id == item.id}) {
            return true
        
        } else {
    return false
    }
         
    }
    
    @State var endPunkteSchnitt = -1.0
    @State var calcSchnittFailed = false
    @State var trashClicked = false
    @State var actItem: SemesternotenItem = SemesternotenItem(id: UUID(), name: "", semesterNote: 0.0, semesterPunkte: 0.0, date: Date())
    
    func warnUserTrash(item: SemesternotenItem) {
        trashClicked = true
        actItem = item
        print(trashClicked)
        user.simpleWarning()
    }
    
    var body: some View {
        ZStack {
            Color.modeColor
            VStack {
                if tablet {
                    TabletTopBar()
                } else {
                            VStack {
                                ZStack {

                                    HStack {
                                        ArrowLeft().onTapGesture {
                                            user.verlauf = false
                                        }
                                        Spacer()
                                    }
                                    Text("Semesterübersicht")
                                }.onTapGesture {
                                    user.verlauf = false

                                }
                                Rectangle().frame(width: screen.width, height: 0.5).foregroundColor(.gray)
                    
                            }
                }
                
                    ScrollView(showsIndicators: false) {
                        ForEach(user.semesterNoten, id: \.id) { item in
                            ZStack {
                                Color.modeColor
                                HStack {
                                    Image(systemName: "trash").resizable().aspectRatio(contentMode: .fit)
                                        .frame(width: 25).padding(.leading, 10).onTapGesture {
                                        warnUserTrash(item: item)
                                    }
                                    HStack {
                                        Text(item.name).font(.title).padding(.leading)
                                        Spacer()
                                        VStack {
                                            Text("\(String(format: "%.2f", item.semesterNote))").font(.title2).bold()
                                            Text("am \(item.date.toStringDate(date: item.date))").font(.footnote).fontWeight(.light)
                                        }
                                        Image(systemName: "chevron.right").foregroundColor(.modeColorSwitch).padding(.trailing).onTapGesture {

                                        }
                                    }.onTapGesture {
                                        user.itemClicked = true
                                        user.verlaufFaecherArray.removeAll()
                                        user.verlaufFaecherArray = fetchAllFaecherFromSemesternote(id: item.id, viewContext: viewContext)
                                        user.verlaufName = item.name
                                        user.verlaufNotenName = item.name
                                        hideKeyboard()
                                        id = item.id.uuidString
                                }
                                    
                                }
                            }
                            Rectangle().frame(width: screen.width, height: 0.5).foregroundColor(.gray)
                        }
                    }.alert(isPresented: $trashClicked, content: {
                        Alert(title: Text("Löschen"), message: Text("Möchtest du diese Note wirklich unwiderruflich löschen?"),
                              primaryButton: .destructive(Text("Ja"), action: {
                            deleteSemesternote(semesternotenItem: actItem)
                            user.semesterNoten = fetchAllSemesterNoten(viewContext: viewContext) ?? []
                        }),
                              secondaryButton: .cancel(Text("Nein")))
                        
                    })
                
                Spacer()
            }
            VStack {
                Spacer()
                
                ZStack {
                    ZStack {
                        Rectangle().frame(width: screen.width, height: 50).foregroundColor(.modeColor)
                        VStack {
                            Rectangle().frame(width: screen.width, height: 0.5).foregroundColor(.gray)
                            HStack {
                                Text("Abitur-Notenschnitt: ").font(.title2).padding(.leading)
                                Spacer()
                                Text("\(String(format: "%.2f", user.endNoteAbi))").font(.title2)
                                Image(systemName: "chevron.right").foregroundColor(.modeColorSwitch).padding(.trailing).onTapGesture {
                                    user.siteOpened = 4
                                }
                            }.foregroundColor(.modeColorSwitch).onTapGesture {
                                user.siteOpened = 4
                                user.abiClicked = true
                            }
                            
                        }.foregroundColor(.white)
                        
                    }.blur(radius: (user.premium || Products.store.isProductPurchased(Products.goldSub) ||
                                    Products.store.isProductPurchased(Products.permanent)) ? 0 : 7)
                    
                    Image(systemName: "lock").resizable().aspectRatio(contentMode: .fit).frame(width: 25)
                        .opacity((user.premium || Products.store.isProductPurchased(Products.goldSub) ||
                                  Products.store.isProductPurchased(Products.permanent)) ? 0 : 1)
                }.onTapGesture {
                    if !(user.premium || Products.store.isProductPurchased(Products.goldSub) ||
                         Products.store.isProductPurchased(Products.permanent)) {
                        user.spendenClicked = true
                        user.siteOpened = 3
                    } else {
                        user.abiClicked = true
                    }
                   
                }
                
                ZStack {
                    ZStack {
                        Rectangle().frame(width: screen.width, height: 100).foregroundColor(.mainColor)
                        VStack {
                           
                            HStack {
                                Text("Gesamtnotenschnitt: ").font(.title2)
                                Spacer()
                                Text("\(String(format: "%.2f", gesamtNotenSchnitt()))").font(.title).bold()
                            }.padding(.horizontal)
                            HStack {
                                Text("Gesamtpunkteschnitt: ").font(.title2)
                                Spacer()
                                Text("\(String(format: "%.2f", gesamtPunkteSchnitt()))").font(.title).bold()
                            }.padding(.horizontal).padding(.top, 7)
                            
                        }.foregroundColor(.white)
                        
                    }.blur(radius: (user.premium || Products.store.isProductPurchased(Products.goldSub) ||
                                    Products.store.isProductPurchased(Products.permanent)) ? 0 : 7)
                    
                    Image(systemName: "lock").resizable().aspectRatio(contentMode: .fit).frame(width: 25)
                        .opacity((user.premium || Products.store.isProductPurchased(Products.goldSub) ||
                                  Products.store.isProductPurchased(Products.permanent)) ? 0 : 1)
                }.onTapGesture {
                    if !(user.premium || Products.store.isProductPurchased(Products.goldSub) ||
                         Products.store.isProductPurchased(Products.permanent)) {
                        user.spendenClicked = true
                        user.siteOpened = 3
                    }
                   
                }
            }.edgesIgnoringSafeArea(.all)
            
            if user.itemClicked {
                SemesterNoteAusrechnenVerlauf(itemClicked: $user.itemClicked, id: id)
            }
            
//            if user.abiClicked {
//                AbiClicked()
//        }
        }.onChange(of: openSHareWindow) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                if openSHareWindow {
                    
                        var shareText: String? {
                            // swiftlint:disable:next line_length
                            return "Hi, ich habe gerade \(shareNoteEndnote ? "meine Endnote" : "eine Semesternote") mit dem Abi Noten Rechner ausgerechnet. Ich habe einen Notenschnitt von \(String(format: "%.2f", shareNote.semesterNote))! Wenn du auch deine Noten ausrechnen möchtest, kannst du dir den Abi Noten Rechner kostenlos im App Store herunterladen: https://apps.apple.com/us/app/abi-noten-rechner/id1550466460"
                       }
                               guard let data = shareText else { return }
                               let av = UIActivityViewController(activityItems: [data], applicationActivities: nil)
                               UIApplication.shared.windows.first?.rootViewController?.present(av, animated: true, completion: nil)
                           openSHareWindow = false
                    user.simpleSuccess()
                    }
                }
            
        }.sheet(isPresented: $noteTeilenClicked) {
            VStack {
                if !tablet {
                    RoundedRectangle(cornerRadius: 4).frame(width: 37, height: 6).foregroundColor(.gray).padding(.top, 8).onTapGesture {
                        noteTeilenClicked = false
                        
                    }
                    Text("Note teilen").font(.title).bold().padding(.top, 10)
                    Text("Wähle jetzt eine Note aus, die du teilen möchtest.").padding(.top).padding(.horizontal, 25)
                        .multilineTextAlignment(.center).padding(.bottom, 20)
                    
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
                                    shareNote = SemesternotenItem(id: UUID(), name: "Endnote",
                                                                  semesterNote: user.endNoteAbi, semesterPunkte: user.endPunkteAbi, date: Date.now)
                                } else {
                                    // Fallback on earlier versions
                                }
                                shareNoteEndnote = true
                            }
                        }
                        
                        ForEach(user.semesterNoten, id: \.id) { item in
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
                            noteTeilenClicked = false
                            openSHareWindow = true
                        }
                        
                    }
                }
                    Spacer()
                }
        }.onAppear {
            print("Hi")
            user.semesterNoten = fetchAllSemesterNoten(viewContext: viewContext) ?? []
            print(user.semesterNoten.count)
            if user.semesterNoten.count >= 4 {
                for i in 0..<4 {
                    abiSemesterNoten.append(user.semesterNoten[i])
                }
            } else {
                abiSemesterNoten = user.semesterNoten
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
//        .highPriorityGesture(DragGesture().onEnded({
//            if handleSwipe(translation: $0.translation.width) {
//                if user.itemClicked && user.NachSpeichernFragenStopp == false {
//                    user.frageNachSpeichern = true
//                }
//                if user.itemClicked && user.NachSpeichernFragenStopp {
//                    user.itemClicked = false
//                }
//                if user.itemClicked == false {
//                    user.verlauf = false
//                }
//
//            }
//        }))
        
    }
}

struct SemesterNotenVerlauf_Previews: PreviewProvider {
    static var previews: some View {
        SemesterNotenVerlauf()
            .previewDevice("iPhone 8")
    }
}

struct SemesternotenItem: Identifiable {
    var id: UUID
    var name: String
    var semesterNote: Double
    var semesterPunkte: Double
    var date: Date
}

struct SemesterNoteAusrechnenVerlauf: View {
    @Binding var itemClicked: Bool
    var id: String
    @State var showDeleteAlert = false
    @State var errorCalc = false
    @State var schnittClicked = false
    @EnvironmentObject var user: UserStore
    @Environment(\.managedObjectContext) private var viewContext
    
    func clearAll() {
        user.verlaufName = ""
        user.verlaufNotenName = ""
        user.verlaufFaecherArray.removeAll()
        user.verlaufFaecherArray = fetchMap()
        hideKeyboard()
    }
    func calcPunkte() -> Double? {
        var punkteSchnitt = 0.0
        var count = 0.0
        var alarm = true
        
        for i in user.verlaufFaecherArray where !i.note.isEmpty {

                if Double(i.note)! > 15 {
                    return nil
                } else {
                    punkteSchnitt += Double(i.note)!
                    count += 1
                    if i.gewichtung == "2" {
                        punkteSchnitt += Double(i.note)!
                        count += 1
                    }
                    alarm = false
                }

        }
        if alarm == true {
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

    func saveSemesterNotenVerlauf(punkte: Double, note: Double) -> Bool {

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
                                if thisID.uuidString == id {
                                    viewContext.delete(result)
                                    
                                    let neueNote = Semesternote(context: viewContext)
                                    neueNote.id = UUID()
                                    
                                    neueNote.name = user.verlaufNotenName
                                    neueNote.date = Date()
                                    neueNote.semesterPunkte = punkte
                                    neueNote.semesterNote = note
                                    var neueFaecher = [Fach(context: viewContext)]
                                    for j in user.verlaufFaecherArray {
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
        
    }
    
    var body: some View {
        ZStack {
            Color.modeColor.onTapGesture {
                hideKeyboard()
            }.edgesIgnoringSafeArea(.all)
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
                                                itemClicked = false
                                                
                                            hideKeyboard()
                                        }
                                        }.onTapGesture {
                                            
                                            itemClicked = false
                                            hideKeyboard()
                                        }
                                        Spacer()
                                    }
                                    Text("\(user.verlaufNotenName) bearbeiten")
                                }
                                Rectangle().frame(width: screen.width, height: 0.5).foregroundColor(.gray)
                    
                            }
                }
                HStack {
                    VStack {
                        TextField("Name: z.B. 1. Semester", text: $user.verlaufNotenName).font(.title3)
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
                    ForEach(0..<user.verlaufFaecherArray.count) { index in
                        ZStack {
                            Color.modeColor.onTapGesture {
                                hideKeyboard()
                            }
                            ZStack {
                                RoundedRectangle(cornerRadius: 5).stroke(Color.gray, lineWidth: 0.5).foregroundColor(.modeColor)
                                HStack {
                                    Spacer()
                                    TextField("0", text: $user.verlaufFaecherArray[index].note)
                                        .multilineTextAlignment(.center).keyboardType(.numberPad)
                                    Spacer()
                                }
                            }.frame(width: 40, height: 30)
                            HStack {
                                    VStack {
                                        TextField("\(index + 1). Fach", text: $user.verlaufFaecherArray[index].name).font(.headline)
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
                                                    .opacity(user.verlaufFaecherArray[index].gewichtung == "1" ? 1 : 0)
                                                Text("1x").foregroundColor(user.verlaufFaecherArray[index].gewichtung == "1" ? .modeColor : .gray)
                                            }
                                            Spacer()
                                        }
                                        HStack {
                                            Spacer()
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 5).foregroundColor(.mainColor).frame(width: 40)
                                                    .opacity(user.verlaufFaecherArray[index].gewichtung == "2" ? 1 : 0)
                                                Text("2x").foregroundColor(user.verlaufFaecherArray[index].gewichtung == "2" ? .modeColor : .gray)
                                            }
                                            
                                        }
                                        
                                    }.frame(width: 80, height: 30).padding(.trailing, tablet ? 100 : 20).onTapGesture {
                                        if user.verlaufFaecherArray[index].gewichtung == "1" {
                                            user.verlaufFaecherArray[index].gewichtung = "2"
                                            return
                                        }
                                        if user.verlaufFaecherArray[index].gewichtung == "2" {
                                            user.verlaufFaecherArray[index].gewichtung = "1"
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
                    }.frame(width: tablet ? 250 : 160, height: tablet ? 50 : 40).onTapGesture {
                        user.simpleWarning()
                        showDeleteAlert = true
                        hideKeyboard()
                        print("hi")
                    }.alert(isPresented: $showDeleteAlert) {
                        Alert(title: Text("Zurücksetzen"), message: Text("Möchtest du diese Seite wirklich zurücksetzen?"),
                              primaryButton: .destructive(Text("Ja"), action: clearAll),
                              secondaryButton: .cancel(Text("Nein")))
                    }
                    Spacer()
                    ZStack {
                        RoundedRectangle(cornerRadius: 10).foregroundColor(.mainColor)
                        Text("Aktualisieren").foregroundColor(.modeColor).font(tablet ? .title : .headline)
                    }.frame(width: tablet ? 250 : 120, height: tablet ? 50 : 40).onTapGesture {
                        if calcPunkte() == nil {
                            errorCalc = true
                            user.simpleError()
                            print("ERROR")
                        } else {
                            if calcNote(punkte: calcPunkte()!) > 0 {
                                if saveSemesterNotenVerlauf(punkte: calcPunkte()!, note: calcNote(punkte: calcPunkte()!)) {
                                    user.verlaufNote = calcNote(punkte: calcPunkte()!)
                                    user.verlaufPunkte = calcPunkte()!
                                    user.verlaufName = user.verlaufNotenName
                                    user.semesterNoten = fetchAllSemesterNoten(viewContext: viewContext) ?? []
                                    schnittClicked = true
                                    user.simpleSuccess()
                                    hideKeyboard()
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
                                                    if thisID.uuidString == id {
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
                                itemClicked = false
                            }
                        }
                    }.alert(isPresented: $errorCalc) {
                        Alert(title: Text("Falsche Punktzahl"), message:
                                Text("Es sieht so aus als hättest du keine oder irgendwo eine falsche Punktzahl eingegeben"),
                              dismissButton: .cancel())
                    }
                    Spacer()
                }.padding(.top)
                Spacer()
            }
            
        }
        if schnittClicked {
            
            AuswertungVerlauf(clicked: $schnittClicked, schnittClicked: $itemClicked).onAppear {
                user.updateVerlauf = true
            }
        }
    }
}

struct AuswertungVerlauf: View {
    @EnvironmentObject var user: UserStore
    @Binding var clicked: Bool
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var schnittClicked: Bool
    @State var noteTeilenClicked = false
    @State var abiSemesterNoten = [SemesternotenItem]()
    @State var shareNote = SemesternotenItem(id: UUID(), name: "", semesterNote: -1, semesterPunkte: 0.0, date: Date())
    @State var shareNoteEndnote = false
    @State var openSHareWindow = false
    @State var semesterNoten = [SemesternotenItem]()
    
    var body: some View {
        ZStack {
            Color.modeColor
            VStack {
                if tablet {
                    TabletTopBar()
                } else {
                            VStack {
                                ZStack {
                                    
                                    Text("Ergebnis")
                                }
                                Rectangle().frame(width: screen.width, height: 0.5).foregroundColor(.gray)
                    
                            }
                }
                
                Text(user.verlaufName).font(.title2).bold().padding(.top, 10).padding(.bottom)
                HStack {
                    Text("Punkte-Durchschnitt").font(.title3)
                    Text("\(String(format: "%.2f", user.verlaufPunkte))").font(.title3).fontWeight(.semibold)
                }.padding(.horizontal)
                HStack {
                    Text("Noten-Durchschnitt").font(.title3)
                    Text("\(String(format: "%.2f", user.verlaufNote))").font(.title3).fontWeight(.semibold)
                }.padding(.horizontal).padding(.top, 5)
                
                .padding(.horizontal, 15).onTapGesture {
                    user.ausrechnen = true
                    user.siteOpened = 1
                    
                }
                
                ZStack {
                    RoundedRectangle(cornerRadius: 10).foregroundColor(.mainColor)
                    HStack {
                        Text("Neues Semester anlegen").foregroundColor(.modeColor)
                        Spacer()
                        Image(systemName: "chevron.right").foregroundColor(.modeColor)
                    }.padding(.horizontal)
                }.frame(width: tablet ? 300 : screen.width * 0.85, height: 55).padding(.horizontal).onTapGesture {
                    user.aktuellerFaecherArray.removeAll()
                    user.aktuellerNotenName = ""
                    user.aktuellerFaecherArray = fetchMap()
                    schnittClicked = false
                    user.verlauf = false
                    user.ausrechnen = true
                    user.siteOpened = 1
                    user.updateMode = false
                }.padding(.top)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 10).stroke(Color.mainColor, lineWidth: 0.5)
                    HStack {
                        Text("\(user.verlaufNotenName) bearbeiten").foregroundColor(.mainColor)
                        Spacer()
                        Image(systemName: "chevron.right").foregroundColor(.mainColor)
                    }.padding(.horizontal)
                }.frame(width: tablet ? 300 : screen.width * 0.85, height: 55).padding(.horizontal).onTapGesture {
                    clicked = false
                }.padding(.top)
                
                ZStack {
                        RoundedRectangle(cornerRadius: 10).foregroundColor(.modeColorSwitch)
                        HStack {
                            Text("Endnote berechnen").foregroundColor(.mainColor )
                            Spacer()
                            Image(systemName: "chevron.right").foregroundColor(.mainColor)
                        }.padding(.horizontal, 15).onTapGesture {
                            if user.premium || Products.store.isProductPurchased(Products.goldSub) ||
                                Products.store.isProductPurchased(Products.permanent) {
                            
                            user.verlauf = true
                            user.abiClicked = true
                            user.updateMode = false
                            hideKeyboard()
                            }
                        }
                    if !(user.premium || Products.store.isProductPurchased(Products.goldSub) ||
                         Products.store.isProductPurchased(Products.permanent)) {
                        RoundedRectangle(cornerRadius: 10).foregroundColor(.gray).opacity(0.5)
                            .frame(width: tablet ? 300 : screen.width * 0.85, height: 55)
                        Image(systemName: "lock").resizable().aspectRatio(contentMode: .fit)
                            .frame(width: 25).foregroundColor(.modeColor).onTapGesture {
                            user.spendenClicked = true
                            
                        }
                    }
                }.frame(width: tablet ? 300 : screen.width * 0.85, height: 55).padding(.horizontal).padding(.top)
                
                HStack {
                    Text(tablet ? "Zurück zur Übersicht" : "Semesterübersicht").onTapGesture {
                        user.verlauf = true
                        user.siteOpened = 2
                        user.updateMode = false
                        user.itemClicked = false
                        hideKeyboard()
                    }
                    Image(systemName: "chevron.right").padding(.leading, 10)
                }.padding(.top, 12).foregroundColor(.gray)
                
                Spacer()
                if !tablet {
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
            }.onChange(of: openSHareWindow) { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
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
                
            }.sheet(isPresented: $noteTeilenClicked) {
                VStack {
                    if !tablet {
                        RoundedRectangle(cornerRadius: 4).frame(width: 37, height: 6).foregroundColor(.gray).padding(.top, 8).onTapGesture {
                            noteTeilenClicked = false
                            
                        }
                        Text("Note teilen").font(.title).bold().padding(.top, 10)
                        Text("Wähle jetzt eine Note aus, die du teilen möchtest.").padding(.top).padding(.horizontal, 25)
                            .multilineTextAlignment(.center).padding(.bottom, 20)
                        
                        ScrollView(showsIndicators: false) {
                            if user.endNoteAbi != 0 {
                                ZStack {
                                    if shareNoteEndnote {
                                        RoundedRectangle(cornerRadius: 10).foregroundColor(.mainColor)
                                    } else {
                                        RoundedRectangle(cornerRadius: 5).stroke(Color.gray, lineWidth: 0.5).foregroundColor(.modeColor)
                                    }
                                    
                                    Text("Endnote: \(String(format: "%.2f", user.endNoteAbi))")
                                        .foregroundColor(shareNoteEndnote ? .modeColor : .modeColorSwitch)
                                }.frame(width: 200, height: 60).onTapGesture {
                                    if #available(iOS 15, *) {
                                        shareNote = SemesternotenItem(
                                            id: UUID(), name: "Endnote", semesterNote: user.endNoteAbi,
                                            semesterPunkte: user.endPunkteAbi, date: Date.now)
                                    } else {
                                        // Fallback on earlier versions
                                    }
                                    shareNoteEndnote = true
                                }
                            }
                            
                            ForEach(semesterNoten, id: \.id) { item in
                                ZStack {
                                    
                                    if shareNote.id == item.id {
                                        RoundedRectangle(cornerRadius: 10).foregroundColor(.mainColor)
                                    } else {
                                        RoundedRectangle(cornerRadius: 5).stroke(Color.gray, lineWidth: 0.5).foregroundColor(.modeColor)
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

struct AbiClicked: View {
    
    @State var endPunkteSchnitt = -1.0
    @State var calcSchnittFailed = false
    @State var trashClicked = false
    @State var actItem: SemesternotenItem = SemesternotenItem(id: UUID(), name: "", semesterNote: 0.0, semesterPunkte: 0.0, date: Date())
    
    func warnUserTrash(item: SemesternotenItem) {
        trashClicked = true
        actItem = item
        print(trashClicked)
        user.simpleWarning()
    }

    @EnvironmentObject var user: UserStore
    @State var id = ""
    @Environment(\.managedObjectContext) private var viewContext
    
    @State var noteTeilenClicked = false
    
    @State var abiSemesterNoten = [SemesternotenItem]()
    @State var shareNote = SemesternotenItem(id: UUID(), name: "", semesterNote: -1, semesterPunkte: 0.0, date: Date())
    @State var shareNoteEndnote = false
    @State var openSHareWindow = false
    
    func deleteSemesternote(semesterNotenItem: SemesternotenItem) {
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
                            if thisID.uuidString == semesterNotenItem.id.uuidString {
                                viewContext.delete(result)
                                
                        }
                        
                    }
                }
            }
            }

        do {
            try viewContext.save()
        } catch {
            print(error.localizedDescription)
            
        }
        } catch {
            print(error.localizedDescription)
            
        }
    }
    
    func gesamtNotenSchnitt() -> Double {
        var gesamtSchnitt = 0.0
        var count = 0
        for i in fetchAllSemesterNoten(viewContext: viewContext) ?? [] {
            gesamtSchnitt += i.semesterNote
            count += 1
        }
        gesamtSchnitt /= Double(count)
        return gesamtSchnitt
    }

    func gesamtPunkteSchnitt() -> Double {
        var gesamtSchnitt = 0.0
        var count = 0
        for i in fetchAllSemesterNoten(viewContext: viewContext) ?? [] {
            gesamtSchnitt += i.semesterPunkte
            count += 1
        }
        gesamtSchnitt /= Double(count)
        return gesamtSchnitt
    }
    
    func gesamtPunkteSchnittAbi() -> Double {
        var gesamtSchnitt = 0.0
        var count = 0
        for i in fetchAllSemesterNoten(viewContext: viewContext) ?? [] {
           if checkIfItemIsInArray(array: abiSemesterNoten, item: i) {
                gesamtSchnitt += i.semesterPunkte
                count += 1
            }
        }
        gesamtSchnitt /= Double(count)
        return gesamtSchnitt
    }
    
    func calcPunkte() -> Double? {
        var punkteSchnitt = 0.0
        var count = 0.0
        
        for i in user.aktuellerAbiNotenArray where !i.note.isEmpty {

                if Double(i.note)! > 15 {
                    return nil
                } else {
                    punkteSchnitt += Double(i.note)!
                    count += 1
                }

        }
        punkteSchnitt /= count
        return punkteSchnitt
    }
    
    func checkIfAbiNotenArrayIsValid() -> Bool {
        for i in user.aktuellerAbiNotenArray {
            if !i.note.isEmpty {
                return false
            } else {
                return true
            }
        }
        return true
    }
    
    func calcEndPunkteSchnitt() -> Double? {
        var punkteSchnitt = 0.0
        let semesterPunkteSchnitt = calcPunkte()
        let abiPunkteSchnitt = gesamtPunkteSchnittAbi()
        
        if abiSemesterNoten.count != 4 || !checkIfAbiNotenArrayIsValid() || semesterPunkteSchnitt == nil {
            return nil
        } else {
            punkteSchnitt += semesterPunkteSchnitt!
            punkteSchnitt += abiPunkteSchnitt * 2
            punkteSchnitt /= 3
        }
    
        return punkteSchnitt
    }
    
    func stoppBearbeitung() {
        user.itemClicked = false
    }
    
    func calcNote(punkte: Double) -> Double? {
        var notenSchnitt = 0.0
        
        if punkte == -1 {
            return nil
        }
        
        if punkte != 0 {
            notenSchnitt = (17 - punkte)/3
        } else {
            notenSchnitt = 6.0
        }
        
        return notenSchnitt
    }
    
    func checkIfItemIsInArray(array: [SemesternotenItem], item: SemesternotenItem) -> Bool {
        if array.contains(where: {$0.id == item.id}) {
            return true
        
        } else {
    return false
    }
         
    }
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
                            Color.modeColor.onTapGesture {
                                user.abiClicked = false
                                print("hi")
                            }
                            HStack {
                                ArrowLeft().onTapGesture {
                                    user.abiClicked = false
                                    print("hi")
                                }
                                Spacer()
                            }
                            Text("Abi-Schnitt")
                        }
                        Rectangle().frame(width: screen.width, height: 0.5).foregroundColor(.gray)
                        
                    }
                }
                
                if tablet {
                    ZStack {
                        Color.modeColor
                        HStack {
                            
                            Image(systemName: "xmark").resizable().aspectRatio(contentMode: .fit).frame(width: 50).padding()
                            Spacer()
                        }
                    }.frame(width: screen.width, height: 50).onTapGesture {
                        print("hi")
                        user.abiClicked = false
                        user.siteOpened = 2
                    }
                }
                
                Text("Semesternoten einbringen (4x)").font(.title2)
                ScrollView(showsIndicators: false) {
                    ForEach(user.semesterNoten, id: \.id) { item in
                        ZStack {
                            Color.modeColor.onTapGesture {
                                hideKeyboard()
                            }
                            HStack {
                                HStack {
                                    Image(systemName: checkIfItemIsInArray(array: abiSemesterNoten, item: item) ? "checkmark.square" :  "square")
                                        .resizable().aspectRatio(contentMode: .fit).frame(width: 25)
                                    
                                    Text(item.name).font(.title3).padding(.leading)
                                    Spacer()
                                }.padding(.horizontal).onTapGesture {
                                    
                                    if checkIfItemIsInArray(array: abiSemesterNoten, item: item) {
                                        
                                        for i in 0..<abiSemesterNoten.count {
                                            print(i)
                                            if abiSemesterNoten[i].id == item.id {
                                                
                                                abiSemesterNoten.remove(at: i)
                                                break
                                            }
                                            
                                        }
                                        
                                    } else {
                                        abiSemesterNoten.append(item)
                                    }
                                    print(abiSemesterNoten)
                                }
                                
                            }
                        }
                    }
                }.frame(height: screen.height * 0.25)
                Spacer()
                
                Rectangle().frame(width: screen.width, height: 0.5).foregroundColor(.gray)
                Text("Abi-Prüfungen").font(.title2)
                
                ScrollView(showsIndicators: false) {
                    ForEach(0..<user.aktuellerAbiNotenArray.count) { index in
                        
                        HStack {
                            
                            ZStack {
                                Color.modeColor.onTapGesture {
                                    hideKeyboard()
                                }
                                HStack {
                                    VStack {
                                        TextField("\(index + 1). Fach", text: $user.aktuellerAbiNotenArray[index].name).font(.headline)
                                        HStack {
                                            Rectangle().frame(height: 0.5).padding(.top, -6).foregroundColor(.gray)
                                            Spacer()
                                        }
                                    }.frame(width: screen.width * 0.35).padding(.leading, 10)
                                    
                                    Spacer()
                                }.offset(y: 5).padding(.bottom, 10)
                            }
                            ZStack {
                                RoundedRectangle(cornerRadius: 5).stroke(Color.gray, lineWidth: 0.5).foregroundColor(.modeColor)
                                HStack {
                                    Spacer()
                                    TextField("0", text: $user.aktuellerAbiNotenArray[index].note)
                                        .multilineTextAlignment(.center).keyboardType(.numberPad)
                                    Spacer()
                                }
                            }.frame(width: 40, height: 30)
                        }.padding(.horizontal)
                        
                    }
                }.frame(height: screen.height * 0.4)
                
                if calcNote(punkte: Double(endPunkteSchnitt)) == nil {
                    if user.endNoteAbi != 0 {
                        Text("End-Note: \(String(format: "%.2f", user.endNoteAbi))").bold().foregroundColor(.mainColor).font(.title2).padding(.bottom)
                    }
                    
                } else {
                    Text("End-Note: \(String(format: "%.2f", calcNote(punkte: Double(endPunkteSchnitt))!))")
                        .bold().foregroundColor(.mainColor).font(.title2).padding(.bottom)
                }
                
                VStack {
                    Spacer()
                    HStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10).foregroundColor(.mainColor)
                            Text("Ausrechnen").foregroundColor(.modeColor).font(tablet ? .title : .headline).alert(isPresented: $calcSchnittFailed) {
                                Alert(title: Text("Fehler"),
                                      message: Text("Du brauchst genau 4 Semesternoten und 5 Prüfungsnoten, um deine End-Note auszurechnnen."),
                                      dismissButton: .cancel(Text("Okay")))
                            }.frame(width: tablet ? 250 : 120, height: tablet ? 50 : 40).onTapGesture {
                                if abiSemesterNoten.count != 4 || !checkIfAbiNotenArrayIsValid() {
                                    print("failed2")
                                    calcSchnittFailed = true
                                    user.simpleError()
                                } else {
                                    if calcEndPunkteSchnitt() == nil {
                                        print("failed")
                                        user.simpleError()
                                    } else {
                                        endPunkteSchnitt = Double(calcEndPunkteSchnitt()!)
                                        user.simpleSuccess()
                                    }
                                    
                                    user.endPunkteAbi = endPunkteSchnitt
                                    user.endNoteAbi = calcNote(punkte: Double(endPunkteSchnitt)) ?? -1
                                    user.pruefungsNamenArray.removeAll()
                                    user.pruefungsNotenArray.removeAll()
                                    for i in user.aktuellerAbiNotenArray.indices {
                                        user.pruefungsNamenArray.append(user.aktuellerAbiNotenArray[i].name)
                                        user.pruefungsNotenArray.append(user.aktuellerAbiNotenArray[i].note)
                                    }
                                    
                                }
                            }
                            
                        }.padding()
                        Spacer()
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 10).stroke(Color.mainColor, lineWidth: 0.5)
                            HStack {
                                Image(systemName: "square.and.arrow.up").resizable().aspectRatio(contentMode: .fit)
                                    .frame(width: 20).foregroundColor(.mainColor).padding(.trailing, 3)
                                Text("Note Teilen").foregroundColor(.mainColor).font(tablet ? .title : .headline)
                            }
                        }.frame(width: tablet ? 280 : 150, height: tablet ? 50 : 40).padding().onTapGesture {
                            
                            if user.endNoteAbi != 0 {
                                shareNoteEndnote = true
                                if #available(iOS 15, *) {
                                    shareNote = SemesternotenItem(
                                        id: UUID(), name: "Endnote", semesterNote: user.endNoteAbi,
                                        semesterPunkte: user.endPunkteAbi, date: Date.now)
                                } else {
                                    // Fallback on earlier versions
                                }
                            }
                            noteTeilenClicked = true
                            
                        }
                    }
                }
            }
        }.edgesIgnoringSafeArea(.bottom)
    }
}
