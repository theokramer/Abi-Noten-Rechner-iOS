//
//  EndGrade.swift
//  NotenRechner
//
//  Created by Theo Kramer on 11.09.25.
//

import SwiftUI
import CoreData

struct AbiClicked: View {
    
    @EnvironmentObject var user: UserStore
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var selectedSemesters: [UUID] = []
    @State private var endPunkteSchnitt: Double = -1
    @State private var shareNote: SemesternotenItem = SemesternotenItem(id: UUID(), name: "", semesterNote: -1, semesterPunkte: 0.0, date: Date())
    @State private var shareEndnote = false
    @State private var showShareSheet = false
    
    var body: some View {
        List {
                    // MARK: - Semesternoten Section
                    Section(header: Text("Semesternoten")
                        .font(.title3).bold()
                        .foregroundColor(.modeColorSwitch)
                    ) {
                        ForEach(user.semesterArray) { item in
                            SemesterCard(item: item, isSelected: selectedSemesters.contains(item.id)) {
                                toggleSemester(item: item)
                                updateEndnote()
                            }
                        }
                    }
                    
                    // MARK: - Abi-Prüfungen Section
                    Section(header: Text("Abi-Prüfungen")
                        .font(.title3).bold()
                        .foregroundColor(.modeColorSwitch)
                    ) {
                        ForEach(user.aktuellerAbiNotenArray.indices, id: \.self) { index in
                            FachRow(fach: $user.aktuellerAbiNotenArray[index])
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        user.aktuellerAbiNotenArray.remove(at: index)
                                        updateEndnote()
                                    } label: {
                                        Label("Löschen", systemImage: "trash")
                                    }
                                }.onChange(of: user.aktuellerAbiNotenArray[index].note) { _ in
                                    updateEndnote()
                                }
                        }
                        
                        // + Button zum Hinzufügen neuer Fächer
                        Button {
                            user.aktuellerAbiNotenArray.append(AbiItem(id: UUID(), name: "", note: ""))
                        } label: {
                            HStack {
                                Spacer()
                                Image(systemName: "plus.circle")
                                Text("Fach hinzufügen")
                                Spacer()
                            }
                            .padding(8)
                        }
                    }
                    
                    // MARK: - Endnoten Anzeige Section
                    Section {
                        VStack(spacing: 12) {
                            Text("Dein Abi-Ergebnis")
                                .font(.headline)
                                .foregroundColor(.modeColorSwitch)
                            
                            if selectedSemesters.count == 4 {
                                VStack(spacing: 8) {
                                    HStack {
                                        Text("Endpunkte")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text(String(format: "%.2f", endPunkteSchnitt))
                                            .font(.title2)
                                            .bold()
                                            .foregroundColor(.mainColor)
                                    }
                                    
                                    HStack {
                                        Text("Endnote")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text(String(format: "%.2f", user.endNoteAbi))
                                            .font(.title2)
                                            .bold()
                                            .foregroundColor(.mainColor)
                                    }
                                }
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 16).fill(Color.modeColor.opacity(0.15)))
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
                                                            } else {
                                Text("Endnote kann noch nicht berechnet werden")
                                    .foregroundColor(.gray)
                                    .italic()
                            }
                            
                            // Teilen Button
                            Button(action: shareCurrentNote) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Endnote teilen")
                                        .bold()
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .background(RoundedRectangle(cornerRadius: 16).fill(Color.mainColor))
                                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 5)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                .listStyle(.insetGrouped)
                .sheet(isPresented: $showShareSheet) {
                    ShareSheet(items: [shareText()])
                }
                .onAppear {
                    updateEndnote()
                }
            }
    
    // MARK: - Funktionen
    private func toggleSemester(item: SemesternotenItem) {
        if let index = selectedSemesters.firstIndex(of: item.id) {
            selectedSemesters.remove(at: index)
        } else if selectedSemesters.count < 4 {
            selectedSemesters.append(item.id)
        }
    }
    
    private func calcEndNoteValue() -> Double? {
        guard selectedSemesters.count == 4,
              !user.aktuellerAbiNotenArray.filter({ !$0.note.isEmpty }).isEmpty else {
            return nil
        }

        // Durchschnitt Semester
        let semesterPunkte = user.semesterArray
            .filter { selectedSemesters.contains($0.id) }
            .map { $0.semesterPunkte }
        let semesterAverage = semesterPunkte.reduce(0, +) / Double(semesterPunkte.count)

        // Durchschnitt Abi-Prüfungen
        let abiPunkte = user.aktuellerAbiNotenArray
            .compactMap { Double($0.note) }
        let abiAverage = abiPunkte.isEmpty ? 0 : abiPunkte.reduce(0, +) / Double(abiPunkte.count)

        // Endpunkte nach Gewichtung: Semester 2/3, Abi 1/3
        return semesterAverage * (2.0/3.0) + abiAverage * (1.0/3.0)
    }
    
    private func calcEndpunkte() -> Double? {
        guard selectedSemesters.count == 4
               else {
            return nil
        }

        let semesterPunkte = user.semesterArray
            .filter { selectedSemesters.contains($0.id) }
            .map { $0.semesterPunkte }
        let semesterAverage = semesterPunkte.reduce(0, +) / Double(semesterPunkte.count)
        let abiPunkte = user.aktuellerAbiNotenArray.compactMap { Double($0.note) }.isEmpty ? semesterPunkte : user.aktuellerAbiNotenArray.compactMap { Double($0.note) }
        let abiAverage = abiPunkte.reduce(0, +) / Double(abiPunkte.count)

        // Gewichtung: Semester 2/3, Abi 1/3
        return semesterAverage * (2.0/3.0) + abiAverage * (1.0/3.0)
    }

    private func punkteZuNote(punkte: Double) -> Double {
        // 15 Punkte = 1, 0 Punkte = 6 (lineare Skalierung)
        return max(1, min(6, (17 - punkte)/3))
    }


    
    private func updateEndnote() {
        guard let endpunkte = calcEndpunkte() else { return }
        endPunkteSchnitt = endpunkte
        user.endPunkteAbi = endpunkte
        user.endNoteAbi = punkteZuNote(punkte: endpunkte)
    }



    
    private func calcNote(punkte: Double) -> Double {
        return punkte != 0 ? (17 - punkte)/3 : 6.0
    }
    
    private func shareCurrentNote() {
        guard let _ = calcEndNoteValue() else { return }
        shareNote = SemesternotenItem(id: UUID(), name: "Endnote", semesterNote: endPunkteSchnitt, semesterPunkte: endPunkteSchnitt, date: Date())
        shareEndnote = true
        showShareSheet = true
    }
    
    private func shareText() -> String {
        return "Hi, ich habe gerade \(shareEndnote ? "meine Endnote" : "eine Semesternote") mit dem Abi Noten Rechner ausgerechnet. Mein Notenschnitt ist \(String(format: "%.2f", shareNote.semesterNote))!"
    }
}

struct FaecherList: View {
    @Binding var faecher: [AbiItem]
    var updateEndnote: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(faecher.indices, id: \.self) { index in
                        FachRow(fach: $faecher[index])
                            .onChange(of: faecher[index].note) { _ in updateEndnote() }
                            .onChange(of: faecher[index].name) { _ in updateEndnote() }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteFach(at: index)
                                } label: {
                                    Label("Löschen", systemImage: "trash")
                                }
                            }
                    }
                    
                    // + Button
                    Button {
                        addFach()
                    } label: {
                        HStack {
                            Spacer()
                            Image(systemName: "plus.circle")
                                .font(.title2)
                            Text("Fach hinzufügen")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 4)
                }
                .padding(.horizontal)
            }
            .frame(maxHeight: 400) // oder dynamisch
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6).opacity(0.2)))
        }
    }
    
    private func deleteFach(at index: Int) {
        faecher.remove(at: index)
        updateEndnote()
    }
    
    private func addFach() {
        faecher.append(AbiItem(id: UUID(), name: "", note: ""))
        updateEndnote()
    }
}


struct FachRow: View {
    @Binding var fach: AbiItem
    
    var body: some View {
        HStack(spacing: 10) {
            TextField("Fachname", text: $fach.name)
                .padding(10)
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
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
            .padding(10)
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
            .frame(width: 60)
            
            
        }
        .padding(4)
    }
}

struct AddFachButton: View {
    @Binding var faecher: [AbiItem]
    
    var body: some View {
        HStack {
            Spacer()
            Button {
                faecher.append(AbiItem(id: UUID(), name: "", note: ""))
            } label: {
                Image(systemName: "plus.circle")
                    .font(.title2)
                    .foregroundColor(.modeColor)
            }
            .buttonStyle(.plain)
        }
        .padding(.trailing)
    }
}


// MARK: - Subview
struct SemesterCard: View {
    var item: SemesternotenItem
    var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.name.isEmpty ? "Semester" : item.name)
                        .bold()
                        .foregroundColor(.modeColorSwitch)
                    Text("Note: \(String(format: "%.2f", item.semesterNote))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .mainColor : .gray)
                    .font(.title2)
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.modeColor.opacity(0.1)))
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 5)
            .padding(.horizontal)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
