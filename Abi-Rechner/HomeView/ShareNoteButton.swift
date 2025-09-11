//
//  ShareNoteButton.swift
//  NotenRechner
//
//  Created by Theo Kramer on 10.09.25.
//

import SwiftUI

struct ShareNoteButton: View {
    @EnvironmentObject var user: UserStore
    @ObservedObject var viewModel: HomeViewModel
    
    var body: some View {
        HStack {
            Image(systemName: "square.and.arrow.up")
            Text("Note Teilen")
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.blue.opacity(0.2)))
        .onTapGesture {
            viewModel.noteTeilenClicked = true
        }
    }
}



