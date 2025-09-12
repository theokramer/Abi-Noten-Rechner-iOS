import SwiftUI

// ----------------------------
// Models (Codable für Speicherung)
// ----------------------------
struct SzenarioSemester: Identifiable, Codable {
    let id: UUID
    var name: String
    var note: Double
    var punkte: Double
}

struct SzenarioPruefung: Identifiable, Codable {
    let id: UUID
    var name: String
    var note: Double
}

// AbiturSzenario jetzt mit endNote, damit wir das vollständig persistieren können
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

    // Key für lokale Speicherung (UserDefaults) – Backup
    private let storageKey = "AbiNoten.SzenarioPlaner.v1"
    // Dateiname im Documents-Verzeichnis – primäre Speicherung
    private var scenarioURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("szenario_planer_v1.json")
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {

                    // MARK: Semester
                    sectionCard(title: "Semester") {
                        ForEach(szenario.semester) { semester in
                            itemRow(
                                id: semester.id,
                                name: bindingForSemesterName(id: semester.id),
                                value: bindingForSemesterNote(id: semester.id),
                                placeholder: "Semester"
                            )
                        }
                        addCard(title: "Neues Semester", action: addSemester)
                    }

                    // MARK: Prüfungen
                    sectionCard(title: "Abi Prüfungen") {
                        ForEach(szenario.pruefungen) { fach in
                            itemRow(
                                id: fach.id,
                                name: bindingForPruefungName(id: fach.id),
                                value: bindingForPruefungNote(id: fach.id),
                                placeholder: "Prüfung"
                            )
                        }
                        addCard(title: "Neue Prüfung", action: addPruefung)
                    }

                    // MARK: Endnote
                    VStack(spacing: 8) {
                        Text("Endnote")
                            .font(.title3).bold()
                            .foregroundColor(.secondary)
                        Text(String(format: "%.2f", endNote))
                            .font(.system(size: 42, weight: .heavy, design: .rounded))
                            .foregroundColor(.accentColor)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.accentColor.opacity(0.1))
                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    )
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
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
                // Lade-Prio:
                // 1) Datei im Documents (robust)
                // 2) UserDefaults (Fallback)
                // 3) Falls nichts vorhanden -> initial aus userStore bauen und speichern
                if !loadScenarioFromStorage() {
                    initializeScenarioFromUserStoreAndSave()
                } else {
                    // geladen -> endNote übernehmen
                    endNote = szenario.endNote
                }
            }
        }
    }

    // ----------------------------
    // Persistenz: Laden / Speichern (Datei + Backup in UserDefaults)
    // ----------------------------
    /// Versucht das Szenario aus Datei oder UserDefaults zu laden. Falls erfolgreich: szenario gesetzt und true zurück.
    private func loadScenarioFromStorage() -> Bool {
        // 1) Datei
        if FileManager.default.fileExists(atPath: scenarioURL.path) {
            do {
                let data = try Data(contentsOf: scenarioURL)
                let decoder = JSONDecoder()
                let stored = try decoder.decode(AbiturSzenario.self, from: data)
                self.szenario = stored
                self.endNote = stored.endNote
                return true
            } catch {
                print("Fehler beim Lesen der Szenario-Datei:", error)
                // Falls Datei defekt ist, versuchen wir es mit UserDefaults weiter unten
            }
        }

        // 2) Fallback -> UserDefaults
        if let data = UserDefaults.standard.data(forKey: storageKey) {
            let decoder = JSONDecoder()
            if let stored = try? decoder.decode(AbiturSzenario.self, from: data) {
                self.szenario = stored
                self.endNote = stored.endNote
                return true
            }
        }

        return false
    }

    /// Speichert das aktuelle szenario (inkl. endNote) in Datei (atomar) und als Backup in UserDefaults.
    private func saveScenarioToStorage() {
        var toSave = szenario
        toSave.endNote = endNote
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        do {
            let data = try encoder.encode(toSave)
            // Atomar in Datei schreiben
            try data.write(to: scenarioURL, options: .atomic)
            // Backup in UserDefaults (falls du mal wechseln möchtest)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Fehler beim Speichern des Szenarios:", error)
        }
    }

    /// Initialisiert das Szenario einmalig aus userStore (App-Daten) und speichert es direkt.
    private func initializeScenarioFromUserStoreAndSave() {
        szenario.semester = userStore.semesterArray.map {
            SzenarioSemester(id: $0.id, name: $0.name, note: $0.semesterNote, punkte: $0.semesterPunkte)
        }
        let names = userStore.pruefungsNamenArray
        let notes = userStore.pruefungsNotenArray.compactMap { Double($0) }
        szenario.pruefungen = zip(names, notes).map { SzenarioPruefung(id: UUID(), name: $0.0, note: $0.1) }

        // Endnote: wenn userStore.endNoteAbi gesetzt, nimm das, sonst berechne
        if userStore.endNoteAbi != 0 {
            endNote = userStore.endNoteAbi
        } else {
            berechneEndnote()
        }
        szenario.endNote = endNote
        saveScenarioToStorage()
    }

    private func loadFromUserStore() {
        // Semester übernehmen
        szenario.semester = userStore.semesterArray.map {
            SzenarioSemester(id: $0.id,
                             name: $0.name,
                             note: $0.semesterNote,
                             punkte: $0.semesterPunkte)
        }

        // Abi-Prüfungen übernehmen
        szenario.pruefungen = userStore.aktuellerAbiNotenArray.map {
            SzenarioPruefung(id: $0.id,
                             name: $0.name,
                             note: Double($0.note) ?? 0.0)
        }

        berechneEndnote()
    }

    private func resetSzenario() {
        // Reset für Semester + Abi-Prüfungen
        loadFromUserStore()
        focusedField = nil
        saveChanges()
    }


    // ----------------------------
    // UI Komponenten (wie vorher)
    // ----------------------------
    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title3).bold()
                .foregroundColor(.primary)
                .padding(.horizontal, 4)

            VStack(spacing: 12, content: content)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                )
        }
        .padding(.horizontal)
    }

    private func itemRow(id: UUID, name: Binding<String>, value: Binding<Double>, placeholder: String) -> some View {
        HStack(spacing: 12) {
            TextField(placeholder, text: name)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                .focused($focusedField, equals: id)

            Spacer()

            TextField("Note", value: value, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .frame(width: 70)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                .focused($focusedField, equals: id)
        }
    }

    private func addCard(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text(title)
            }
            .font(.body.bold())
            .foregroundColor(.accentColor)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.accentColor.opacity(0.1))
            )
        }
        .padding(.horizontal)
    }

    // ----------------------------
    // Bindings (speichern Szenario separat)
    // ----------------------------
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

    private func bindingForSemesterNote(id: UUID) -> Binding<Double> {
        Binding(get: {
            szenario.semester.first(where: { $0.id == id })?.note ?? 0.0
        }, set: { newValue in
            if let index = szenario.semester.firstIndex(where: { $0.id == id }) {
                szenario.semester[index].note = max(0, min(newValue, 15))
                berechneEndnote()
                saveChanges()
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

    private func bindingForPruefungNote(id: UUID) -> Binding<Double> {
        Binding(get: {
            szenario.pruefungen.first(where: { $0.id == id })?.note ?? 0.0
        }, set: { newValue in
            if let index = szenario.pruefungen.firstIndex(where: { $0.id == id }) {
                szenario.pruefungen[index].note = max(0, min(newValue, 15))
                berechneEndnote()
                saveChanges()
            }
        })
    }

    // ----------------------------
    // Aktionen (verwenden nun nur noch Szenario-Persistenz)
    // ----------------------------
    private func addSemester() {
        let newSemester = SzenarioSemester(id: UUID(), name: "Neues Semester", note: 0.0, punkte: 0.0)
        szenario.semester.append(newSemester)
        berechneEndnote()
        saveChanges()
        focusedField = newSemester.id
    }

    private func addPruefung() {
        let newFach = SzenarioPruefung(id: UUID(), name: "Neue Prüfung", note: 0.0)
        szenario.pruefungen.append(newFach)
        berechneEndnote()
        saveChanges()
        focusedField = newFach.id
    }

    private func deleteSemester(at offsets: IndexSet) {
        szenario.semester.remove(atOffsets: offsets)
        berechneEndnote()
        saveChanges()
    }

    private func deletePruefung(at offsets: IndexSet) {
        szenario.pruefungen.remove(atOffsets: offsets)
        berechneEndnote()
        saveChanges()
    }

    private func berechneEndnote() {
        let semesterSum = szenario.semester.reduce(0.0) { $0 + $1.note }
        let pruefungsSum = szenario.pruefungen.reduce(0.0) { $0 + $1.note }
        let count = Double(szenario.semester.count + szenario.pruefungen.count)
        withAnimation {
            endNote = count > 0 ? (semesterSum + pruefungsSum) / count : 0.0
        }
    }

    /// Speichert nur das Szenario (Datei + Backup in UserDefaults)
    private func saveChanges() {
        szenario.endNote = endNote
        saveScenarioToStorage()
    }
}
