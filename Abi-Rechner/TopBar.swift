//
//  TabletTopBar.swift
//  Abi-Rechner
//
//  Created by Theo Kramer on 23.01.21.
//

import SwiftUI
import CoreData

struct TabletTopBar: View {
    @EnvironmentObject var user: UserStore
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        VStack {
            ZStack {
                Text("Abi Noten Rechner").font(.title)
                VStack {
                    HStack {
                        Image(systemName: "star")
                        Text("Premium")
                        Spacer()
                    }.padding().onTapGesture {
                        user.spendenClicked = true
                        user.siteOpened = 3
                        user.simpleSuccess()
                }
                    HStack {
                        Image(systemName: "questionmark.circle")
                        Text("Support").foregroundColor(.modeColorSwitch)
                        Spacer()
                    }.padding(.leading).onTapGesture {
                        user.supportClicked = true
                        user.siteOpened = 5
                    }
                }
            }
            HStack {
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 10).foregroundColor(.mainColor).opacity(!user.verlauf ? 1 : 0)
                    Text("Semesternote ausrechnen").foregroundColor(!user.verlauf ? .modeColor : .gray)
                }.frame(width: 300, height: 55).padding(.horizontal).onTapGesture {
                    user.verlauf = false
                    user.siteOpened = 0
                    hideKeyboard()
                }
                ZStack {
                    RoundedRectangle(cornerRadius: 10).foregroundColor(.mainColor).opacity(user.verlauf ? 1 : 0)
                    Text("Semesterübersicht").foregroundColor(user.verlauf ? .modeColor : .gray)
                    if !(user.userHasBasicPremium || user.userHasGoldPremium) {
                        RoundedRectangle(cornerRadius: 10).foregroundColor(.gray).opacity(0.5)
                        Image(systemName: "lock").resizable().aspectRatio(contentMode: .fit).frame(width: 25)
                            .onTapGesture {
                            user.spendenClicked = true
                            user.siteOpened = 3
                        }
                    }
                }.frame(width: 300, height: 55).padding(.horizontal).onTapGesture {
                    if user.userHasGoldPremium || user.userHasBasicPremium {
                        user.verlauf = true
                        user.siteOpened = 2
                        hideKeyboard()
                    } else {
                        user.siteOpened = 3
                    }
                }
                Spacer()
            }
            Rectangle().frame(width: screen.width, height: 0.5).foregroundColor(.gray).padding(.top, 10)
            if checkIfSaleIsActive() {
                if !(user.userHasBasicPremium || user.userHasGoldPremium) {
                SaleView()
            }
            }
        }

    }
}

struct TabletTopBar_Previews: PreviewProvider {
    static var previews: some View {
        TabletTopBar().environmentObject(UserStore())
    }
}
