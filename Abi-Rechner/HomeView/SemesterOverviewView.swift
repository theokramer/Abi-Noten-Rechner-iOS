//
//  SemesterOverviewView.swift
//  NotenRechner
//
//  Created by Theo Kramer on 10.09.25.
//

import SwiftUI
import CoreData

struct SemesterOverviewView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var user: UserStore

    @State private var semesterNoten: [SemesternotenItem] = []

    var body: some View {
        VStack(spacing: 16) {
            // Header mit Gesamtschnitt
            VStack(spacing: 6) {
                Text("Semester-Übersicht")
                    .font(.title2).bold()

                if let avg = overallAverage {
                    HStack {
                        Text("Notenschnitt aller Semester")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "%.2f", avg))
                            .font(.title3).bold()
                    }
                    .padding(.horizontal)
                } else {
                    Text("Noch keine Semesternoten vorhanden.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top)

            // Liste der Semester
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(semesterNoten.indices, id: \.self) { idx in
                        let item = semesterNoten[idx]
                        SemesterRowView(index: idx, item: item)
                            .onTapGesture {
                                openSemester(item: item)
                            }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .background(Color(.systemGroupedBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .onAppear(perform: load)
    }

    // MARK: - Helpers

    private var overallAverage: Double? {
        guard !semesterNoten.isEmpty else { return nil }
        // Berechne einfachen Mittelwert über semesterNote
        let sum = semesterNoten.reduce(0.0) { partial, item in
            partial + item.semesterNote
        }
        let avg = sum / Double(semesterNoten.count)
        return avg
    }

    private func load() {
        semesterNoten = fetchAllSemesterNoten(viewContext: viewContext) ?? []
    }

    private func openSemester(item: SemesternotenItem) {
        user.ausrechnen = true
        user.siteOpened = 1
        user.aktuellerFaecherArray = fetchAllFaecherFromSemesternote(id: item.id, viewContext: viewContext)
        user.aktuellerNotenName = item.name
        user.aktuelleID = item.id.uuidString
        user.updateMode = true
    }
}

// Kleine Row-View für ein Semester
private struct SemesterRowView: View {
    let index: Int
    let item: SemesternotenItem

    var displayName: String {
        if item.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "\(index + 1). Semester"
        } else {
            return item.name
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(displayName)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text("\(formattedSubjectsCount(item: item)) Fächer")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(String(format: "%.2f", item.semesterNote))
                .font(.headline)
                .bold()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .padding(.leading, 6)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
    }

    // versucht, die Anzahl der Fächer aus dem SemesternotenItem zu schätzen,
    // falls du dafür ein Feld hast, passe die Implementation an.
    private func formattedSubjectsCount(item: SemesternotenItem) -> String {
        // Fallback: falls du keine Fächeranzahl in SemesternotenItem hast, gib "-" zurück
        // Wenn dein SemesternotenItem ein Feld mit Anzahl hat, verwende das hier.
        return "-"
    }
}

// Preview (benutzt Dummy-Daten)
struct SemesterOverviewView_Previews: PreviewProvider {
    static var previews: some View {
        // Dummy UserStore und Dummy Data für Vorschau
        let user = UserStore()
        let vm = PersistenceController.preview.container.viewContext

        // Sample SemesternotenItem ist vermutlich ein struct in deinem Projekt.
        // Für Preview kannst du Beispiele bauen, falls nötig.
        return SemesterOverviewView()
            .environment(\.managedObjectContext, vm)
            .environmentObject(user)
    }
}
