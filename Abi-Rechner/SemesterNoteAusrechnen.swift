//
//  SemesterNoteAusrechnen.swift
//  Abi-Rechner
//
//  Created by Theo Kramer on 23.01.21.
//

import SwiftUI
import CoreData
import WidgetKit

@available(iOS 15.0, *)
struct SemesterNoteAusrechnen: View {
    @Environment(\.dismiss) private var dismiss // <- hinzufügen
    @State private var showDeleteAlert = false
    @State private var errorCalc = false
    @EnvironmentObject var user: UserStore
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.scenePhase) var scenePhase

    // MARK: - Funktionen
    
    private func warnUser() {
        showDeleteAlert = true
        hideKeyboard()
        user.simpleWarning()
    }
    
    private func clearAll() {
        user.aktuellerNotenName = ""
        user.aktuellerFaecherArray.removeAll()
        hideKeyboard()
    }
    
    private func calcPunkte() -> Double? {
        var sum = 0.0
        var count = 0.0
        for f in user.aktuellerFaecherArray where !f.note.isEmpty {
            guard let val = Double(f.note), val <= 15 else { return nil }
            sum += val
            count += (f.gewichtung == "2" ? 2 : 1)
        }
        return count > 0 ? sum / count : nil
    }
    
    private func calcNote(punkte: Double) -> Double {
        return punkte != 0 ? (17 - punkte)/3 : 6.0
    }
    
    private func deleteCurrentSemester() {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Semesternote")
        do {
            let results = try viewContext.fetch(request)
            for result in results {
                if let res = result as? NSManagedObject,
                   let thisID = res.value(forKey: "id") as? UUID,
                   thisID.uuidString == user.aktuelleID {
                    viewContext.delete(res)
                }
            }
            try viewContext.save()
            // HomeScreen update
            user.semesterArray = fetchAllSemesterNoten(viewContext: viewContext) ?? []
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func saveSemester(punkte: Double, note: Double) {
        let isUpdate = user.updateMode
        
        if isUpdate {
            // Bestehendes Semester löschen und neu erstellen
            deleteCurrentSemester()
        }
        
        let neueNote = Semesternote(context: viewContext)
        neueNote.id = UUID()
        user.aktuelleID = neueNote.id!.uuidString
        
        // Nur bei neuem Semester und leerem Namen automatisch nummerieren
        if !isUpdate && user.aktuellerNotenName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let nextNumber = (user.semesterArray.count) + 1
            neueNote.name = "\(nextNumber). Semester"
        } else {
            neueNote.name = user.aktuellerNotenName
        }
        
        neueNote.date = Date()
        neueNote.semesterPunkte = punkte
        neueNote.semesterNote = note
        
        for f in user.aktuellerFaecherArray {
            let neuesFach = Fach(context: viewContext)
            neuesFach.id = f.id
            neuesFach.name = f.name
            neuesFach.note = f.note
            neuesFach.gewichtung = Int64(f.gewichtung) ?? 1
            neuesFach.position = f.position
            neuesFach.alsSemesterFach = neueNote
        }
        
        do {
            try viewContext.save()
            // Direkt nach dem Speichern UserStore aktualisieren
            user.semesterArray = fetchAllSemesterNoten(viewContext: viewContext) ?? []
            
            
            
            // Widget Update
            if let userDefaults = UserDefaults(suiteName: "group.notenRechner.widgetcache") {
                let noteRounded = Double(round(100*note)/100)
                userDefaults.set(noteRounded, forKey: "text")
            }
            WidgetCenter.shared.reloadAllTimelines()
            
        } catch {
            print(error.localizedDescription)
        }
    }

    
    private func checkIfTrue(quick: Bool) {
        guard let punkte = calcPunkte() else {
            errorCalc = true
            user.simpleError()
            return
        }
        let note = calcNote(punkte: punkte)
        if note > 0 {
            saveSemester(punkte: punkte, note: note)
            user.aktuelleNote = note
            user.aktuellePunkte = punkte
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
        } else {
            deleteCurrentSemester()
            if !quick {
                user.ausrechnen = false
                user.updateMode = false
                user.simpleSuccess()
            }
        }
    }
    
    private func handleAppGoesToBackground() {
        guard let punkte = calcPunkte() else { return }
        let note = calcNote(punkte: punkte)
        saveSemester(punkte: punkte, note: note)
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            Color.modeColor.ignoresSafeArea().onTapGesture { hideKeyboard() }
            
            VStack(spacing: 16) {
            
                
                // Semester Name
                TextField("Name: z.B. 1. Semester", text: $user.aktuellerNotenName)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 8).stroke(Color.gray))
                    .padding(.horizontal)
                
                // Fächerliste
                ScrollView {
                    VStack(spacing: 10) {
                        // Beispiel innerhalb deiner ForEach für Fächer
                        ForEach(user.aktuellerFaecherArray.indices, id: \.self) { index in
                            HStack(spacing: 10) {
                                // Fachname
                                TextField("Fachname", text: $user.aktuellerFaecherArray[index].name)
                                    .padding(8)
                                    .background(RoundedRectangle(cornerRadius: 6).stroke(Color.gray))
                                    .frame(maxWidth: .infinity)
                                
                                // Punkte
                                TextField("0", text: Binding(
                                    get: { user.aktuellerFaecherArray[index].note },
                                    set: { newValue in
                                        // Nur Zahlen zwischen 0 und 15 erlauben
                                        let filtered = newValue.filter { "0123456789.".contains($0) }
                                        if let doubleValue = Double(filtered), doubleValue >= 0, doubleValue <= 15 {
                                            user.aktuellerFaecherArray[index].note = filtered
                                        } else if filtered.isEmpty {
                                            user.aktuellerFaecherArray[index].note = ""
                                        }
                                        // sonst nicht übernehmen (ungültige Eingabe ignorieren)
                                    }
                                ))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.center)
                                .padding(6)
                                .background(RoundedRectangle(cornerRadius: 6).stroke(Color.gray))
                                .frame(width: 50)
                                
                                // Gewichtung Picker
                                Picker("", selection: $user.aktuellerFaecherArray[index].gewichtung) {
                                    Text("1x").tag("1")
                                    Text("2x").tag("2")
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 70)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemBackground).opacity(0.1)))
                        }

                        
                        // + Fach hinzufügen
                        Button(action: {
                            user.aktuellerFaecherArray.append(
                                FachItem(id: UUID(), name: "", note: "", gewichtung: "1", position: Int64(user.aktuellerFaecherArray.count + 1))
                            )
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Fach hinzufügen")
                            }
                            .foregroundColor(.accentColor)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(RoundedRectangle(cornerRadius: 10).stroke(Color.accentColor))
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 4)
                }
                
                // Buttons
                HStack(spacing: 16) {
                    Button(action: warnUser) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Zurücksetzen")
                        }
                        .foregroundColor(.mainColor)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).stroke(Color.mainColor))
                    }
                    .alert(isPresented: $showDeleteAlert) {
                        Alert(title: Text("Zurücksetzen"),
                              message: Text("Möchtest du diese Seite wirklich zurücksetzen?"),
                              primaryButton: .destructive(Text("Ja"), action: clearAll),
                              secondaryButton: .cancel())
                    }
                    
                    Button(action: {dismiss();  checkIfTrue(quick: false) }) {
                        Text(user.updateMode ? "Aktualisieren" : "Ausrechnen")
                            .foregroundColor(.modeColor)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.mainColor))
                    }
                    .alert(isPresented: $errorCalc) {
                        Alert(title: Text("Falsche Punktzahl"),
                              message: Text("Es sieht so aus als hättest du irgendwo eine falsche Punktzahl oder gar keine eingegeben"),
                              dismissButton: .cancel())
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Banner Ad
                if !user.userHasGoldPremium {
                    BannerADView(bannerID: "ca-app-pub-3263827122305139/3463838331")
                        .frame(height: 60)
                        .padding(.top, 10)
                }
            }.padding(.top, 20)
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .inactive { handleAppGoesToBackground() }
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

struct FachItem: Identifiable, Codable {
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
    var numbers: [FachItem] = []
    // mindestens 1 Fach
    for i in 1..<2 {
        numbers.append(FachItem(id: UUID(), name: "", note: "", gewichtung: "1", position: Int64(i)))
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
