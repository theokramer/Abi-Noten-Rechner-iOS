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
    @State private var showWarningAlert = false

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var user: UserStore
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.scenePhase) var scenePhase
    @State private var lastAddedFachID: UUID?


    var semesterToEdit: SemesternotenItem?
    @State private var showDeleteAlert = false

    init(semesterToEdit: SemesternotenItem? = nil) {
        self.semesterToEdit = semesterToEdit
    }
    
    private func notesValid() -> Bool {
        for f in user.aktuellerFaecherArray {
            // Leer gelassene Notenfelder sind gültig
            if !f.note.isEmpty {
                guard let noteValue = Double(f.note), noteValue <= 15 else {
                    return false
                }
            }
        }
        return true
    }

    private func calcPunkte() -> Double? {
        var sum = 0.0
        var weightSum = 0.0

        for f in user.aktuellerFaecherArray {
            // Nur wenn eine Note vorhanden ist
            if let val = Double(f.note), !f.note.isEmpty, val <= 15 {
                let weight = Double(f.gewichtung) ?? 1
                sum += val * weight
                weightSum += weight
            }
        }
        return weightSum > 0 ? sum / weightSum : nil
    }

    
    private func attemptDismiss() {
        if notesValid() {
            saveAndDismiss()
        } else {
            showWarningAlert = true
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

    // MARK: - OnAppear: initialisieren
    private func initialize() {
        if let semester = semesterToEdit {
            user.aktuellerFaecherArray = fetchAllFaecherFromSemesternote(id: semester.id, viewContext: viewContext)
            user.aktuellerNotenName = semester.name
            user.aktuelleID = semester.id.uuidString
            user.updateMode = true
        } else {
            user.aktuellerFaecherArray = [FachItem(id: UUID(), name: "", note: "", gewichtung: "1", position: 1)]
            user.aktuellerNotenName = ""
            user.aktuelleID = ""
            user.updateMode = false
        }
    }



    private func calcNote(punkte: Double) -> Double {
        return punkte != 0 ? (17 - punkte)/3 : 6.0
    }

    // MARK: - Speichern
    private func saveAndDismiss() {
        guard let punkte = calcPunkte() else {
            user.simpleError()
            return
        }
        let note = calcNote(punkte: punkte)
        saveSemester(punkte: punkte, note: note)
        dismiss() // Zurück zum Homescreen
    }

    private func handleAppGoesToBackground() {
        if let punkte = calcPunkte() {
            saveSemester(punkte: punkte, note: calcNote(punkte: punkte))
        }
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            Color.modeColor
                .ignoresSafeArea()
                .onTapGesture { hideKeyboard() }

            VStack(spacing: 20) {
                SemesterNameInput(name: $user.aktuellerNotenName)

                GeometryReader { geo in
                    FaecherList(faecher: $user.aktuellerFaecherArray, lastAddedFachID: $lastAddedFachID)
                        .frame(height: geo.size.height)
                        .onTapGesture { hideKeyboard() }
                }

                AddFachButton(faecher: $user.aktuellerFaecherArray, lastAddedFachID: $lastAddedFachID)
                    .padding(.bottom, keyboard.isKeyboardVisible ? 20 : 0)

                if !keyboard.isKeyboardVisible {
                    HStack {
                        Button(action: attemptDismiss) {
                            Text("Speichern")
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.mainColor))
                                .foregroundColor(.modeColor)
                        }
                    }
                    
                }

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
        .navigationBarBackButtonHidden(true) // Standard Back-Button ausblenden
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            attemptDismiss() // Alert prüfen
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Speichern")
                            }
                        }
                    }
                }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .inactive { handleAppGoesToBackground() }
        }
        .alert(isPresented: $showWarningAlert) {
            Alert(
                title: Text("Ungültige Noten"),
                message: Text("Einige Noten sind ungültig. Möchtest du Änderungen verwerfen oder weiter bearbeiten?"),
                primaryButton: .destructive(Text("Änderungen verwerfen")) {
                    dismiss()
                },
                secondaryButton: .cancel(Text("Weiter bearbeiten"))
            )
        }
    }
}

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
    @FocusState private var focusedFachID: UUID?

    // Das lastAddedFachID kommt jetzt vom Button über Binding
    @Binding var lastAddedFachID: UUID?

    var body: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(faecher.indices, id: \.self) { index in
                    FachRow(fach: $faecher[index])
                        .id(faecher[index].id)
                        .focused($focusedFachID, equals: faecher[index].id)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                faecher.remove(at: index)
                            } label: {
                                Label("Löschen", systemImage: "trash")
                            }
                        }
                }
            }
            .listStyle(.plain)
            .onChange(of: faecher) { newValue in
                if let newID = lastAddedFachID, newValue.contains(where: { $0.id == newID }) {
                    withAnimation {
                        proxy.scrollTo(newID, anchor: .bottom)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        focusedFachID = newID
                        lastAddedFachID = nil
                    }
                }
            }
        }
    }
}



struct FachRow: View {
    @Binding var fach: FachItem
    @FocusState var isFocused: Bool   // Fokus-State für diesen TextField

    private var noteValid: Bool {
        // Leere Notenfelder sind gültig
        if fach.note.isEmpty { return true }
        
        if let val = Double(fach.note), val <= 15 {
            return true
        }
        return false
    }


    var body: some View {
        HStack(spacing: 10) {
            TextField("Fachname", text: $fach.name)
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 6).stroke(Color.gray))
                .frame(maxWidth: .infinity)
                .focused($isFocused)  // <-- Fokus hier binden

            TextField("0", text: $fach.note)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .padding(6)
                .background(RoundedRectangle(cornerRadius: 6).stroke(noteValid ? Color.gray : Color.red, lineWidth: 1))
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


// 2. AddFachButton anpassen
struct AddFachButton: View {
    @Binding var faecher: [FachItem]
    @Binding var lastAddedFachID: UUID? 
    var body: some View {
        Button {
            let newFach = FachItem(id: UUID(), name: "", note: "", gewichtung: "1", position: Int64(faecher.count + 1))
            faecher.append(newFach)
            lastAddedFachID = newFach.id
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
        var warnUser: () -> Void
        var clearAll: () -> Void
        var checkIfTrue: (Bool) -> Void
        var dismiss: () -> Void
        var updateMode: Bool
        
        var body: some View {
            HStack(spacing: 12) {
                
                Button(action: { dismiss(); checkIfTrue(false) }) {
                    Text("Speichern")
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.mainColor))
                        .foregroundColor(.modeColor)
                }
               
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

struct FachItem: Identifiable, Codable, Equatable {
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
