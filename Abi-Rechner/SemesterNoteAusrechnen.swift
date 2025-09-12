//
//  SemesterNoteAusrechnen.swift
//  Abi-Rechner
//
//  Created by Theo Kramer on 23.01.21.
//

import SwiftUI
import CoreData
import WidgetKit
import Combine

class KeyboardObserver: ObservableObject {
    @Published var isKeyboardVisible: Bool = false
    private var cancellables = Set<AnyCancellable>()

    init() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .sink { [weak self] _ in self?.isKeyboardVisible = true }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .sink { [weak self] _ in self?.isKeyboardVisible = false }
            .store(in: &cancellables)
    }
}

@available(iOS 15.0, *)
struct SemesterNoteAusrechnen: View {
    @StateObject private var keyboard = KeyboardObserver()

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var user: UserStore
    @Environment(\.managedObjectContext) private var viewContext
    
    var semesterToEdit: SemesternotenItem? // Neu
    
    @State private var showDeleteAlert = false
    @State private var errorCalc = false
    
    init(semesterToEdit: SemesternotenItem? = nil) {
        self.semesterToEdit = semesterToEdit
    }
    
    // MARK: - OnAppear: initialisieren
    private func initialize() {
        if let semester = semesterToEdit {
            user.aktuellerFaecherArray = fetchAllFaecherFromSemesternote(id: semester.id, viewContext: viewContext)
            user.aktuellerNotenName = semester.name
            user.aktuelleID = semester.id.uuidString
            user.updateMode = true
        } else {
            // Neues Semester
            user.aktuellerFaecherArray = [FachItem(id: UUID(), name: "", note: "", gewichtung: "1", position: 1)]
            user.aktuellerNotenName = ""
            user.aktuelleID = ""
            user.updateMode = false
        }
    }
    
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
        var weightSum = 0.0
        
        for f in user.aktuellerFaecherArray where !f.note.isEmpty {
            guard let val = Double(f.note), val <= 15 else { return nil }
            let weight = Double(f.gewichtung) ?? 1
            sum += val * weight          // Note mit Gewichtung multiplizieren
            weightSum += weight          // Summe der Gewichtungen
        }
        
        return weightSum > 0 ? sum / weightSum : nil
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
            user.refreshSemesterArray()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func saveSemester(punkte: Double, note: Double) {
        if user.updateMode, let uuid = UUID(uuidString: user.aktuelleID) {
            let request = NSFetchRequest<Semesternote>(entityName: "Semesternote")
            request.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
            
            do {
                if let semesterObj = try viewContext.fetch(request).first {
                    // Alte Fächer löschen
                    if let fächer = semesterObj.faecher as? Set<Fach> {
                        for fach in fächer { viewContext.delete(fach) }
                    }
                    
                    // Semester aktualisieren
                    semesterObj.name = user.aktuellerNotenName
                    semesterObj.semesterNote = note
                    semesterObj.semesterPunkte = punkte
                    semesterObj.date = Date()
                    
                    // Neue Fächer hinzufügen
                    for f in user.aktuellerFaecherArray {
                        let neuesFach = Fach(context: viewContext)
                        neuesFach.id = f.id
                        neuesFach.name = f.name
                        neuesFach.note = f.note
                        neuesFach.gewichtung = Int64(f.gewichtung) ?? 1
                        neuesFach.position = f.position
                        neuesFach.alsSemesterFach = semesterObj
                    }
                    
                    try viewContext.save()
                    user.semesterArray = fetchAllSemesterNoten(viewContext: viewContext) ?? []
                    user.refreshSemesterArray()
                    return // Wichtig: return, damit nicht unten ein neues Semester erstellt wird
                }
            } catch {
                print(error.localizedDescription)
            }
        }
        
        // Wenn kein Update, neues Semester erstellen
        let neueNote = Semesternote(context: viewContext)
        neueNote.id = UUID()
        user.aktuelleID = neueNote.id!.uuidString
        neueNote.name = user.aktuellerNotenName.isEmpty
        ? "\(user.semesterArray.count + 1). Semester"
        : user.aktuellerNotenName
        neueNote.date = Date()
        neueNote.semesterNote = note
        neueNote.semesterPunkte = punkte
        
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
            user.semesterArray = fetchAllSemesterNoten(viewContext: viewContext) ?? []
            user.refreshSemesterArray()
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
            Color.modeColor
                .ignoresSafeArea()
                .onTapGesture { hideKeyboard() }
            
            VStack(spacing: 20) {
                // 1. Semester Name
                SemesterNameInput(name: $user.aktuellerNotenName)
                
                // 2. Fächerliste
                GeometryReader { geo in
                        FaecherList(faecher: $user.aktuellerFaecherArray)
                        .frame(height: geo.size.height).onTapGesture { hideKeyboard() } // füllt den Platz zwischen Überschrift und Buttons
                    }
                
                
                
                // 3. + Fach hinzufügen
                AddFachButton(faecher: $user.aktuellerFaecherArray).padding(.bottom, keyboard.isKeyboardVisible ?  20 : 0)
                
                // 4. Buttons
                if !keyboard.isKeyboardVisible {
                    ActionButtons(
                        showDeleteAlert: $showDeleteAlert,
                        errorCalc: $errorCalc,
                        warnUser: warnUser,
                        clearAll: clearAll,
                        checkIfTrue: checkIfTrue,
                        dismiss: { dismiss() },
                        updateMode: user.updateMode
                    )
                }

                
                
                
                // 5. Banner Ad
                if !user.userHasGoldPremium {
                    BannerADView(bannerID: "ca-app-pub-3263827122305139/3463838331")
                        .frame(height: 60)
                        .padding(.top, 10)
                }
            }
            .padding(.horizontal)
            .padding(.top, 10)
        }
        .onAppear { initialize() }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .inactive { handleAppGoesToBackground() }
        }}
    
    // MARK: - Subviews
    
    struct SemesterNameInput: View {
        @Binding var name: String
        var body: some View {
            TextField("Name: z.B. 1. Semester", text: $name)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
                .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
        }
    }
    
    struct FaecherList: View {
        @Binding var faecher: [FachItem]
        
        var body: some View {
            List {
                ForEach(faecher.indices, id: \.self) { index in
                    FachRow(fach: $faecher[index])
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) { faecher.remove(at: index) } label: {
                                Label("Löschen", systemImage: "trash")
                            }
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color(.systemGray6).opacity(0.3))
                }
            }
            .listStyle(.plain)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.03), radius: 3, x: 0, y: 2)
        }
    }
    
    
    
    
    struct FachRow: View {
        @Binding var fach: FachItem
        
        var body: some View {
            HStack(spacing: 10) {
                TextField("Fachname", text: $fach.name)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 6).stroke(Color.gray))
                    .frame(maxWidth: .infinity)
                
                TextField("0", text: Binding(
                    get: { fach.note },
                    set: { newValue in
                        let filtered = newValue.filter { "0123456789.".contains($0) }
                        if let val = Double(filtered), val >= 0, val <= 15 {
                            fach.note = filtered
                        } else if filtered.isEmpty { fach.note = "" }
                    }
                ))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .padding(6)
                .background(RoundedRectangle(cornerRadius: 6).stroke(Color.gray))
                .frame(width: 50)
                
                Picker("", selection: $fach.gewichtung) {
                    Text("1x").tag("1")
                    Text("2x").tag("2")
                }
                .pickerStyle(.segmented)
                .frame(width: 90)
            }
            .padding(.vertical, 4)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemBackground).opacity(0.1)))
        }
    }
    
    
    
    
    struct AddFachButton: View {
        @Binding var faecher: [FachItem]
        
        var body: some View {
            Button {
                faecher.append(FachItem(id: UUID(), name: "", note: "", gewichtung: "1", position: Int64(faecher.count + 1)))
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Fach hinzufügen")
                }
                .foregroundColor(.mainColor)
                .padding(10)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 12).stroke(Color.mainColor))
            }
        }
    }
    
    struct ActionButtons: View {
        @Binding var showDeleteAlert: Bool
        @Binding var errorCalc: Bool
        var warnUser: () -> Void
        var clearAll: () -> Void
        var checkIfTrue: (Bool) -> Void
        var dismiss: () -> Void
        var updateMode: Bool
        
        var body: some View {
            HStack(spacing: 12) {
                Button(action: warnUser) {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).stroke(Color.mainColor))
                        .foregroundColor(.mainColor)
                }
                .alert(isPresented: $showDeleteAlert) {
                    Alert(
                        title: Text("Reset"),
                        message: Text("Möchtest du diese Seite wirklich zurücksetzen?"),
                        primaryButton: .destructive(Text("Ja"), action: clearAll),
                        secondaryButton: .cancel()
                    )
                }
                
                Button(action: { dismiss(); checkIfTrue(false) }) {
                    Text(updateMode ? "Aktualisieren" : "Ausrechnen")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.mainColor))
                        .foregroundColor(.modeColor)
                }
                .alert(isPresented: $errorCalc) {
                    Alert(title: Text("Falsche Punktzahl"),
                          message: Text("Es sieht so aus als hättest du irgendwo eine falsche Punktzahl oder gar keine eingegeben"),
                          dismissButton: .cancel())
                }
            }
        }
    }}




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

struct AbiItem: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var note: String
}

func fetchMap() -> [FachItem] {
    var numbers: [FachItem] = []
    // mindestens 1 Fach
    for i in 1..<1 {
        numbers.append(FachItem(id: UUID(), name: "", note: "", gewichtung: "1", position: Int64(i)))
    }
    return numbers
}

func fetchMapAbi() -> [AbiItem] {
var numbers: [AbiItem] = []
    for _ in 1..<1 {
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
