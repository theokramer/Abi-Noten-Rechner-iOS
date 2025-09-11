import SwiftUI
import CoreData

struct NewSemesterCard: View {
    @EnvironmentObject var user: UserStore
    var viewContext: NSManagedObjectContext
    
    var body: some View {
    
                
            Button {
                if canCreateSemester {
                    createNewSemester()
                }
                
                    else { user.spendenClicked = true }
            } label: {
                Label("Neues Semester hinzufügen", systemImage: "plus.circle")
            }
            .buttonStyle(.automatic)
            .padding(.top, 8)
        
        
    }
    
    private var canCreateSemester: Bool {
        let semesterCount = fetchAllSemesterNoten(viewContext: viewContext)?.count ?? 0
        return semesterCount < 1 || user.userHasBasicPremium || user.userHasGoldPremium
    }
    
    private func createNewSemester() {
        user.ausrechnen = true
        user.siteOpened = 1
        user.updateMode = false
        user.aktuellerFaecherArray = fetchMap()
        user.aktuellerNotenName = ""
        hideKeyboard()
    }
}
