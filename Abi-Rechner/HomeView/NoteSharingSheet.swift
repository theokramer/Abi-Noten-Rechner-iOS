//
//  NoteSharingSheet.swift
//  NotenRechner
//
//  Created by Theo Kramer on 10.09.25.
//


import SwiftUI

struct NoteSharingSheet: View {
    @EnvironmentObject var user: UserStore
    @ObservedObject var viewModel: HomeViewModel
    
    @State private var showShareSheet = false
    @State private var shareText = ""
    
    var body: some View {
        VStack(spacing: 16) {
            // Grabber für iPhone Sheet
            RoundedRectangle(cornerRadius: 4)
                .frame(width: 37, height: 6)
                .foregroundColor(.gray)
                .padding(.top, 8)
                .onTapGesture {
                    viewModel.noteTeilenClicked = false
                }

            Text("Note teilen")
                .font(.title)
                .bold()
            
            Text("Wähle jetzt eine Note aus, die du teilen möchtest.")
                .padding(.horizontal)
                .multilineTextAlignment(.center)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    // Endnote auswählen
                    if user.endNoteAbi != 0 {
                        NoteSelectionRow(
                            title: "Endnote",
                            note: user.endNoteAbi,
                            points: user.endPunkteAbi,
                            selected: viewModel.shareNoteEndnote
                        )
                        .onTapGesture {
                            viewModel.shareNote = SemesternotenItem(
                                id: UUID(),
                                name: "Endnote",
                                semesterNote: user.endNoteAbi,
                                semesterPunkte: user.endPunkteAbi,
                                date: Date()
                            )
                            viewModel.shareNoteEndnote = true
                        }
                    }
                    
                    // SemesterNoten auswählen
                    ForEach(viewModel.semesterNoten, id: \.id) { item in
                        NoteSelectionRow(
                            title: item.name,
                            note: item.semesterNote,
                            points: item.semesterPunkte,
                            selected: viewModel.shareNote.id == item.id
                        )
                        .onTapGesture {
                            viewModel.shareNote = item
                            viewModel.shareNoteEndnote = false
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            .frame(maxHeight: 300)
            
            // Button zum Teilen
            Button(action: {
                shareNote()
            }) {
                Text("Teilen")
                    .foregroundColor(.modeColor)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.mainColor))
                    .font(.headline)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [shareText])
        }
        .padding(.bottom, 16)
    }
    
    // MARK: - Helper Funktion
    private func shareNote() {
        guard viewModel.shareNote.semesterNote != -1 else {
            user.simpleError()
            return
        }
        
        user.simpleSuccess()
        viewModel.noteTeilenClicked = false
        
        shareText = "Hi, ich habe gerade \(viewModel.shareNoteEndnote ? "meine Endnote" : "eine Semesternote") mit dem Abi Noten Rechner ausgerechnet. Ich habe einen Notenschnitt von \(String(format: "%.2f", viewModel.shareNote.semesterNote))! Wenn du auch deine Noten ausrechnen möchtest, kannst du dir den Abi Noten Rechner kostenlos im App Store herunterladen: https://apps.apple.com/us/app/abi-noten-rechner/id1550466460"
        
        showShareSheet = true
    }
}

// MARK: - Subview für jede Note
struct NoteSelectionRow: View {
    var title: String
    var note: Double
    var points: Double
    var selected: Bool
    
    
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .foregroundColor(selected ? .mainColor : .mainColor.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(selected ? Color.mainColor : Color.gray, lineWidth: 1)
                )
            HStack {
                Text(title.isEmpty ? "1. Semester" : title) // Placeholder wenn leer
                Spacer()
                Text(String(format: "%.2f", note))
            }
            .padding(.horizontal)
            .foregroundColor(selected ? .modeColor : .modeColorSwitch)
        }
        .frame(height: 60)
        .padding(.horizontal)
    }
}


// MARK: - ShareSheet Wrapper für UIKit
struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
