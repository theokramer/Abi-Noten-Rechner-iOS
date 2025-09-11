//
//  PremiumButton.swift
//  NotenRechner
//
//  Created by Theo Kramer on 10.09.25.
//

import SwiftUI

struct PremiumButton: View {
    @EnvironmentObject var user: UserStore
    
    var body: some View {
        HStack {
            Image(systemName: "star.fill")
            Text("Premium")
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.yellow.opacity(0.2)))
        .onTapGesture {
            user.spendenClicked = true
        }
    }
}

struct PremiumButton_Previews: PreviewProvider {
    static var previews: some View {
        PremiumButton()
            .environmentObject(UserStore())
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
