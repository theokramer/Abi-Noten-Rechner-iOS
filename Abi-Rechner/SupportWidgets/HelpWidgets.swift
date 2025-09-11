//
//  HelpWidgets.swift
//  NotenRechner
//
//  Created by Theo Kramer on 02.02.22.
//

import Foundation
import SwiftUI

struct SaleView: View {
    @EnvironmentObject var user: UserStore
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    var body: some View {
        ZStack {
            Rectangle().foregroundColor(.saleColor).onTapGesture {
                user.spendenClicked = true
            }
            VStack {
                HStack {
                    Image(systemName: "heart").resizable().aspectRatio(contentMode: .fit).frame(width: 25).foregroundColor(.white)
                    VStack {
                        HStack {
                            Text("Wintersale bis zu 30%").foregroundColor(.white).bold()
                            Spacer()
                        }
                        
                        HStack {
                            Text("Endet in \(user.differenceBetweenDates)").foregroundColor(.white).onAppear {
                                user.differenceBetweenDates = updateDifferenceBetweenDates()
                            }.onReceive(timer) { _ in
                                user.differenceBetweenDates = updateDifferenceBetweenDates()
                            }
                            Spacer()
                        }
                    }.padding(.leading, 10)
                    Spacer()
                    Image(systemName: "chevron.right").foregroundColor(.white)
                }.padding(.horizontal, 15).onTapGesture {
                    if !(user.basicPremium || Products.store.isProductPurchased(Products.basicSub) ||
                         user.premium || Products.store.isProductPurchased(Products.permanent) ||
                         Products.store.isProductPurchased(Products.goldSub)) {
                        
                        user.spendenClicked = true
                    }
                }
                
            }
            
        }.frame(width: screen.width, height: 50)
    }
}
