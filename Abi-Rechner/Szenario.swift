import SwiftUI

// ----------------------------
// Models
// ----------------------------
struct SzenarioSemester: Identifiable, Codable {
    let id: UUID
    var name: String
    var note: String
    var punkte: Double
}

struct SzenarioPruefung: Identifiable, Codable {
    let id: UUID
    var name: String
    var note: String
}

struct AbiturSzenario: Identifiable, Codable {
    let id: UUID
    var semester: [SzenarioSemester]
    var pruefungen: [SzenarioPruefung]
    var endNote: Double
}

// ----------------------------
// View
// ----------------------------
struct SzenarioPlanerView: View {
    @ObservedObject var userStore: UserStore

    @State private var szenario: AbiturSzenario = AbiturSzenario(id: UUID(), semester: [], pruefungen: [], endNote: 0.0)
    @State private var endNote: Double = 0.0
    @FocusState private var focusedField: UUID?

    private let storageKey = "AbiNoten.SzenarioPlaner.v1"

    var body: some View {
        NavigationView {
            List {
                // MARK: Semester Section
                Section(header: Text("Semester").font(.title3).bold()) {
                    ForEach(szenario.semester) { semester in
                        itemRow(
                            id: semester.id,
                            name: bindingForSemesterName(id: semester.id),
                            value: bindingForSemesterNote(id: semester.id),
                            placeholder: "Semester"
                        )
                    }
                    .onDelete(perform: deleteSemester)

                    Button {
                        addSemester()
                    } label: {
                        Label("Neues Semester", systemImage: "plus.circle.fill")
                            .foregroundColor(.accentColor)
                    }
                }

                // MARK: Abi Prüfungen Section
                Section(header: Text("Abi Prüfungen").font(.title3).bold()) {
                    ForEach(szenario.pruefungen) { fach in
                        itemRow(
                            id: fach.id,
                            name: bindingForPruefungName(id: fach.id),
                            value: bindingForPruefungNote(id: fach.id),
                            placeholder: "Prüfung"
                        )
                    }
                    .onDelete(perform: deletePruefung)

                    Button {
                        addPruefung()
                    } label: {
                        Label("Neue Prüfung", systemImage: "plus.circle.fill")
                            .foregroundColor(.accentColor)
                    }
                }

                // MARK: Endnote Section
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Text("Mögliche Endnote")
                                .font(.title3).bold()
                                .foregroundColor(.secondary)
                            Text(String(format: "%.2f", endNote))
                                .font(.system(size: 42, weight: .heavy, design: .rounded))
                                .foregroundColor(.accentColor)
                        }
                        Spacer()
                    }
                    .padding()
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Szenario Planung")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Zurücksetzen", role: .destructive) {
                        resetSzenario()
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Fertig") { hideKeyboard() }
                }
            }
            .onAppear {
                if !loadScenarioFromStorage() {
                    initializeScenarioFromUserStoreAndSave()
                }
            }
        }
    }

    // MARK: - UI Row
    private func itemRow(id: UUID, name: Binding<String>, value: Binding<String>, placeholder: String) -> some View {
        HStack(spacing: 12) {
            TextField(placeholder, text: name)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                .focused($focusedField, equals: id)

            Spacer()

            TextField("Punkte", text: value)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .frame(width: 70)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                .focused($focusedField, equals: id)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Add/Delete
    private func addSemester() {
        let newSemester = SzenarioSemester(id: UUID(), name: "", note: "", punkte: 0.0)
        szenario.semester.append(newSemester)
        focusedField = newSemester.id
        saveChanges()
    }

    private func addPruefung() {
        let newFach = SzenarioPruefung(id: UUID(), name: "", note: "")
        szenario.pruefungen.append(newFach)
        focusedField = newFach.id
        saveChanges()
    }

    private func deleteSemester(at offsets: IndexSet) {
        szenario.semester.remove(atOffsets: offsets)
        berechneEndnote()
    }

    private func deletePruefung(at offsets: IndexSet) {
        szenario.pruefungen.remove(atOffsets: offsets)
        berechneEndnote()
    }

    // MARK: - Bindings
    private func bindingForSemesterName(id: UUID) -> Binding<String> {
        Binding(get: {
            szenario.semester.first(where: { $0.id == id })?.name ?? ""
        }, set: { newValue in
            if let index = szenario.semester.firstIndex(where: { $0.id == id }) {
                szenario.semester[index].name = newValue
                saveChanges()
            }
        })
    }

    private func bindingForSemesterNote(id: UUID) -> Binding<String> {
        Binding(get: {
            let punkte = szenario.semester.first(where: { $0.id == id })?.punkte ?? 0.0
            // Anzeige immer mit Komma
            return String(format: "%.1f", punkte).replacingOccurrences(of: ".", with: ",")
        }, set: { newValue in
            if let index = szenario.semester.firstIndex(where: { $0.id == id }) {
                // Nur Zahlen und , oder . erlauben
                let filtered = newValue.filter { "0123456789,.".contains($0) }
                // Komma in Punkt umwandeln
                let standardized = filtered.replacingOccurrences(of: ",", with: ".")
                // Konvertieren zu Double
                if let value = Double(standardized) {
                    // Wertebereich zwischen 0 und 15
                    szenario.semester[index].punkte = min(max(value, 0.0), 15.0)
                } else {
                    szenario.semester[index].punkte = 0.0
                }
                berechneEndnote()
            }
        })
    }



    private func bindingForPruefungName(id: UUID) -> Binding<String> {
        Binding(get: {
            szenario.pruefungen.first(where: { $0.id == id })?.name ?? ""
        }, set: { newValue in
            if let index = szenario.pruefungen.firstIndex(where: { $0.id == id }) {
                szenario.pruefungen[index].name = newValue
                saveChanges()
            }
        })
    }

    private func bindingForPruefungNote(id: UUID) -> Binding<String> {
        Binding(get: {
            szenario.pruefungen.first(where: { $0.id == id })?.note ?? ""
        }, set: { newValue in
            if let index = szenario.pruefungen.firstIndex(where: { $0.id == id }) {
                let filtered = newValue.filter { "0123456789.".contains($0) }
                szenario.pruefungen[index].note = filtered
                berechneEndnote()
            }
        })
    }

    // MARK: - Endnote
    @discardableResult
    private func berechneEndnote() -> Double {
        // Semesterpunkte der ausgewählten Semester (hier nehmen wir alle)
        let semesterValues = szenario.semester.map { $0.punkte }
        let semesterAverage = semesterValues.isEmpty ? 0.0 : semesterValues.reduce(0, +) / Double(semesterValues.count)
        
        // Abi-Prüfungenpunkte als Double
        let pruefungsValues = szenario.pruefungen.compactMap { Double($0.note) }
        let pruefungsAverage = pruefungsValues.isEmpty ? 0.0 : pruefungsValues.reduce(0, +) / Double(pruefungsValues.count)
        
        // Gewichtete Endpunkte wie in AbiClicked
        let endPunkte = semesterAverage * (2.0 / 3.0) + pruefungsAverage * (1.0 / 3.0)
        
        // Punkte -> Note
        endNote = punkteZuNote(punkte: endPunkte)
        szenario.endNote = endNote
        saveChanges()
        return endNote
    }

    // Punkte -> Note wie bei AbiClicked
    private func punkteZuNote(punkte: Double) -> Double {
        return max(1.0, min(6.0, (17.0 - punkte) / 3.0))
    }


    // MARK: - Persistenz (UserDefaults)
    private func saveChanges() {
        szenario.endNote = endNote
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(szenario) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func loadScenarioFromStorage() -> Bool {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return false }
        let decoder = JSONDecoder()
        if let stored = try? decoder.decode(AbiturSzenario.self, from: data) {
            self.szenario = stored
            self.endNote = stored.endNote
            return true
        }
        return false
    }

    private func initializeScenarioFromUserStoreAndSave() {
        szenario.semester = userStore.semesterArray.map {
            SzenarioSemester(
                id: $0.id,
                name: $0.name,
                note: String(format: "%.1f", $0.semesterNote),
                punkte: $0.semesterPunkte
            )
        }

        szenario.pruefungen = zip(userStore.pruefungsNamenArray,
                                   userStore.pruefungsNotenArray.compactMap { Double($0) })
            .map { SzenarioPruefung(id: UUID(), name: $0.0, note: String($0.1)) }


        endNote = userStore.endNoteAbi != 0 ? userStore.endNoteAbi : berechneEndnote()
        szenario.endNote = endNote
        saveChanges()
    }

    private func resetSzenario() {
        // Semester aus UserStore übernehmen
        szenario.semester = userStore.semesterArray.map {
            SzenarioSemester(
                id: $0.id,
                name: $0.name,
                note: String(format: "%.1f", $0.semesterNote),
                punkte: $0.semesterPunkte
            )
        }

        // Prüfungen aus UserStore übernehmen
        szenario.pruefungen = userStore.aktuellerAbiNotenArray.map {
            SzenarioPruefung(
                id: UUID(),
                name: $0.name,
                note: String(format: "%.0f", Double($0.note) ?? 0)
            )
        }


        // Endnote sauber berechnen oder aus UserStore übernehmen
        if userStore.endNoteAbi != 0 {
            endNote = userStore.endNoteAbi
        } else {
            endNote = berechneEndnote()
        }
        szenario.endNote = endNote

        saveChanges()
        focusedField = nil
    }

}
