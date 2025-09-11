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
        
        VStack(spacing: 16) {
            
            ScrollView {
                VStack(spacing: 24) {
                    
                    // MARK: - Semesternoten Auswahl
                    Section(header: Text("Semesternoten einbringen (max 4)")
                        .font(.title3).bold().foregroundColor(.modeColorSwitch).padding(.horizontal)) {
                        ForEach(user.semesterArray) { item in
                            SemesterSelectionRow(item: item, isSelected: selectedSemesters.contains(item.id)) {
                                toggleSemester(item: item)
                            }
                        }
                    }
                    
                    Divider().background(Color.gray)
                    
                    // MARK: - Abi Prüfungen
                    Section(header: Text("Abi-Prüfungen")
                        .font(.title3).bold().foregroundColor(.modeColorSwitch).padding(.horizontal)) {
                        ForEach($user.aktuellerAbiNotenArray) { $fach in
                            HStack {
                                TextField("Fachname", text: $fach.name)
                                    .frame(maxWidth: .infinity)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                
                                TextField("Punkte", text: Binding(
                                    get: { fach.note },
                                    set: { newValue in
                                        let filtered = newValue.filter { "0123456789.".contains($0) }
                                        if let val = Double(filtered), val >= 0, val <= 15 {
                                            fach.note = filtered
                                        } else if filtered.isEmpty {
                                            fach.note = ""
                                        }
                                    }
                                ))
                                .keyboardType(.decimalPad)
                                .frame(width: 50)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Divider().background(Color.gray)
                    
                    // MARK: - Endnote Anzeige
                    if let endNote = calcEndNote() {
                        Text("Endnote: \(String(format: "%.2f", endNote))")
                            .bold()
                            .foregroundColor(.mainColor)
                            .font(.title2)
                    } else {
                        Text("Endnote kann noch nicht berechnet werden")
                            .foregroundColor(.gray)
                            .italic()
                    }
                    
                    // MARK: - Teilen Button
                    Button(action: shareCurrentNote) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title2)
                            Text("Note Teilen")
                                .font(.headline)
                        }
                        .foregroundColor(.modeColor)
                        .frame(maxWidth: .infinity, minHeight: 60)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.mainColor))
                        .padding(.horizontal)
                    }
                    
                }
                .padding(.vertical)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [shareText()])
        }
        .padding(.top)
        .onAppear {
            // Berechnung direkt beim Öffnen
            _ = calcEndNote()
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
    
    private func calcEndNote() -> Double? {
        guard !selectedSemesters.isEmpty, user.aktuellerAbiNotenArray.allSatisfy({ Double($0.note) != nil && !$0.note.isEmpty }) else {
            return nil
        }
        
        let semesterPunkte = user.semesterArray.filter { selectedSemesters.contains($0.id) }
            .map { $0.semesterPunkte }
        let semesterAverage = semesterPunkte.reduce(0, +) / Double(semesterPunkte.count)
        
        let abiPunkte = user.aktuellerAbiNotenArray.compactMap { Double($0.note) }
        let abiAverage = abiPunkte.reduce(0, +) / Double(abiPunkte.count)
        
        let endpunkte = (semesterAverage + 2 * abiAverage) / 3
        endPunkteSchnitt = endpunkte
        user.endPunkteAbi = endpunkte
        user.endNoteAbi = calcNote(punkte: endpunkte)
        return endpunkte
    }
    
    private func calcNote(punkte: Double) -> Double {
        return punkte != 0 ? (17 - punkte)/3 : 6.0
    }
    
    private func shareCurrentNote() {
        guard let _ = calcEndNote() else { return }
        shareNote = SemesternotenItem(id: UUID(), name: "Endnote", semesterNote: endPunkteSchnitt, semesterPunkte: endPunkteSchnitt, date: Date())
        shareEndnote = true
        showShareSheet = true
    }
    
    private func shareText() -> String {
        return "Hi, ich habe gerade \(shareEndnote ? "meine Endnote" : "eine Semesternote") mit dem Abi Noten Rechner ausgerechnet. Mein Notenschnitt ist \(String(format: "%.2f", shareNote.semesterNote))!"
    }
}

// MARK: - Subview
struct SemesterSelectionRow: View {
    var item: SemesternotenItem
    var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(.modeColorSwitch)
                Text(item.name.isEmpty ? "Semester" : item.name)
                    .foregroundColor(.modeColorSwitch)
                Spacer()
                Text(String(format: "%.2f", item.semesterNote))
                    .foregroundColor(.modeColorSwitch)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.modeColor.opacity(0.1)))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

