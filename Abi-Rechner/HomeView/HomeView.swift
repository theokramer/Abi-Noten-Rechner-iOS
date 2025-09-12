////
//  PhoneHomeView.swift
//  Abi-Rechner
//
//  Created by Theo Kramer on 23.01.21.
//
import SwiftUI
import CoreData
import GoogleMobileAds

struct HomeView: View {
    @EnvironmentObject var user: UserStore
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = HomeViewModel()
    
    @State private var selectedSemester: SemesternotenItem? = nil
    @State private var semesterToDelete: SemesternotenItem? = nil
    
    var body: some View {
        NavigationView {
            List {
                // MARK: - Aktuelles Semester Section
                Section(
                    
                ) {
                    if let currentSemester = currentSemester,
                       let index = user.semesterArray.firstIndex(where: { $0.id == currentSemester.id }) {
                        let bindingSemester = $user.semesterArray[index]
                        CurrentSemesterCardContent(currentSemester: bindingSemester, viewModel: viewModel, user: user)
                    } else {
                        EmptySemesterCard(user: user)
                    }
                }
                
                // MARK: - Alle Semester Section
                if !user.semesterArray.isEmpty {
                    Section(header: Text("Alle Semester")
                        .font(.title3).bold()
                        .foregroundColor(.modeColorSwitch)
                    ) {
                        ForEach(user.semesterArray.sorted { $0.date < $1.date }) { item in
                            NavigationLink(
                                destination: SemesterNoteAusrechnen(semesterToEdit: item)
                                    .environmentObject(user),
                                tag: item,
                                selection: $selectedSemester
                            ) {
                                SemesterRowView(index: user.semesterArray.firstIndex(of: item) ?? 0, item: item) {
                                    selectedSemester = item
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                // Löschen-Button
                                Button(role: .destructive) {
                                    deleteSemester(item)
                                } label: {
                                    Label("Löschen", systemImage: "trash")
                                }

                                // Teilen-Button
                                Button() {
                                    shareNote(item: item)
                                } label: {
                                    Label("Teilen", systemImage: "square.and.arrow.up")
                                }
                                .tint(.blue)
                            }
                        }
                        NewSemesterButton(user: user)
                    }
                }
                
                // MARK: - Endnote Section
                Section {
                    EndnoteSection(user: user)
                }
                
                
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Abi Noten Rechner")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    
                        Button(action: { user.spendenClicked = true }) {
                            Image(systemName: "crown.fill") // professionelles Premium-Icon
                                .font(.title3)
                                .foregroundColor(.mainColor)
                                .shadow(radius: 1)
                        }
                    
                }
            }
            
            .onAppear {
                viewModel.loadSemesterNoten(context: viewContext)
                user.semesterArray = viewModel.semesterNoten
            }
        }
    }
    private func shareNote(item: SemesternotenItem) {
        let text = """
        Hi, ich habe gerade das \(item.name) mit dem Abi Noten Rechner ausgerechnet. 
        Ich habe einen Notenschnitt von \(String(format: "%.2f", item.semesterNote)). 
        Wenn du auch deine Noten ausrechnen möchtest, kannst du dir den Abi Noten Rechner kostenlos im App Store herunterladen: https://apps.apple.com/us/app/abi-noten-rechner/id1550466460
        """
        
        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        UIApplication.shared.windows.first?.rootViewController?.present(av, animated: true, completion: nil)
    }



    
    // MARK: - Helpers
    private var currentSemester: SemesternotenItem? {
        if let id = UUID(uuidString: user.aktuelleID),
           let sem = user.semesterArray.first(where: { $0.id == id }) {
            return sem
        }
        return user.semesterArray.max(by: { $0.date < $1.date })
    }
    
    private func deleteSemester(_ sem: SemesternotenItem) {
        if let object = fetchSemesterObject(by: sem.id, context: viewContext) {
            viewContext.delete(object)
            do {
                try viewContext.save()
            } catch {
                print("Fehler beim Speichern: \(error.localizedDescription)")
            }
        }
        user.semesterArray.removeAll { $0.id == sem.id }
    }
    
    private func fetchSemesterObject(by id: UUID, context: NSManagedObjectContext) -> NSManagedObject? {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Semesternote")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return (try? context.fetch(request))?.first as? NSManagedObject
    }
}

// MARK: - Current Semester Card Content
struct CurrentSemesterCardContent: View {
    @Binding var currentSemester: SemesternotenItem
    @ObservedObject var viewModel: HomeViewModel
    @ObservedObject var user: UserStore
    
    var body: some View {
        VStack(spacing: 12) {
            HeaderRow(currentSemester: $currentSemester, viewModel: viewModel)
            StatsRow(currentSemester: $currentSemester)
            NavigationLink(
                destination: SemesterNoteAusrechnen(semesterToEdit: currentSemester)
                    .environmentObject(user)
            ) {
                Text("Semester bearbeiten")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.mainColor.opacity(0.2)))
                    .foregroundColor(.mainColor)
            }
            .buttonStyle(.plain) // entfernt den Chevron
        }
        .cardStyle()
    }
}






struct AllSemestersSection: View {
    @ObservedObject var user: UserStore
    @ObservedObject var viewModel: HomeViewModel
    var viewContext: NSManagedObjectContext

    @State private var selectedSemester: SemesternotenItem? = nil
    @State private var semesterToDelete: SemesternotenItem? = nil
    @State private var showDeleteAlert = false

    private var sortedSemesters: [SemesternotenItem] {
        user.semesterArray.sorted { $0.date < $1.date }
    }

    var body: some View {
        if !user.semesterArray.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                SemesterListHeader(user: user, avg: overallAverage)

                List {
                    ForEach(sortedSemesters) { item in
                        NavigationLink(
                            destination: SemesterNoteAusrechnen(semesterToEdit: item)
                                .environmentObject(user),
                            tag: item,
                            selection: $selectedSemester
                        ) {
                            SemesterRowView(
                                index: sortedSemesters.firstIndex(of: item) ?? 0,
                                item: item
                            ) {
                                selectedSemester = item
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                semesterToDelete = item
                                deleteSemester(semesterToDelete!)

                            } label: {
                                Label("Löschen", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .frame(height: 80 + CGFloat(sortedSemesters.count) * 35) // Höhe anpassen falls nötig
               
                NewSemesterButton(user: user)
            }
            .cardStyle()
            .padding(.horizontal)
        }
    }

    private var overallAverage: Double? {
        guard !viewModel.semesterNoten.isEmpty else { return nil }
        let sum = viewModel.semesterNoten.reduce(0.0) { $0 + $1.semesterNote }
        return sum / Double(viewModel.semesterNoten.count)
    }

    private func deleteSemester(_ sem: SemesternotenItem) {
        if let object = fetchSemesterObject(by: sem.id, context: viewContext) {
            viewContext.delete(object)
            do {
                try viewContext.save()
                print("Semester gelöscht und gespeichert")
            } catch {
                print("Fehler beim Speichern: \(error.localizedDescription)")
            }
        }
        // nur UserStore aktualisieren
        user.semesterArray.removeAll { $0.id == sem.id }
    }



    private func fetchSemesterObject(by id: UUID, context: NSManagedObjectContext) -> NSManagedObject? {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Semesternote")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return (try? context.fetch(request))?.first as? NSManagedObject
    }
}



struct EndnoteSection: View {
    @ObservedObject var user: UserStore

    var body: some View {
        VStack(spacing: 16) {
            if user.userHasGoldPremium {
                NavigationLink(destination: AbiClicked().environmentObject(user)) {
                    FeatureCard(title: "Endnote berechnen", icon: "graduationcap.fill", active: true)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                Button(action: { user.spendenClicked = true }) {
                    FeatureCard(title: "Endnote berechnen", icon: "graduationcap.fill", active: false)
                }
            }
        }
        .padding(.horizontal)
    }
}


struct SemesterListHeader: View {
    @ObservedObject var user: UserStore
    let avg: Double?

    var body: some View {
        HStack {
            Text("Deine Semester")
                .font(.headline)
            Spacer()
            if user.userHasGoldPremium, let avg = avg {
                Text("Ø \(String(format: "%.2f", avg))")
                    .font(.subheadline).bold()
                    .foregroundColor(.secondary)
            }
        }
    }
}


struct NewSemesterButton: View {
    @ObservedObject var user: UserStore
    @State private var navigateToSemester = false

    private func resetForNewSemester() {
        user.updateMode = false
        user.aktuellerFaecherArray = []
        user.aktuellerNotenName = ""
        user.aktuelleID = ""
    }

    var body: some View {
        NavigationLink(destination: SemesterNoteAusrechnen().environmentObject(user),
                       isActive: $navigateToSemester) {
            Button {
                resetForNewSemester()
                navigateToSemester = true
            } label: {
                FeatureCard(title: "Neues Semester anlegen",
                            icon: "plus.circle.fill",
                            active: user.userHasGoldPremium,
                            showChevron: false)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}




struct HeaderRow: View {
    @Binding var currentSemester: SemesternotenItem
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        HStack {
            Text(currentSemester.name.isEmpty ? "Aktuelles Semester" : currentSemester.name)
                .font(.title2).bold()
            Spacer()
            
        }
    }
}

struct StatsRow: View {
    @Binding var currentSemester: SemesternotenItem

    var body: some View {
        HStack {
            statItem(title: "Note", value: String(format: "%.2f", currentSemester.semesterNote))
            Divider().frame(height: 28)
            statItem(title: "Punkte", value: String(format: "%.1f", currentSemester.semesterPunkte))
        }
    }

    private func statItem(title: String, value: String) -> some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
                .bold()
        }
        .frame(maxWidth: .infinity)
    }
}



struct EditSemesterButton: View {
    let item: SemesternotenItem
    @ObservedObject var user: UserStore
    var viewContext: NSManagedObjectContext

    var body: some View {
        Button {
            openSemester(item: item)
        } label: {
            Text("Semester bearbeiten")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
        .buttonStyle(.automatic)
    }

    private func openSemester(item: SemesternotenItem) {
        user.aktuellerFaecherArray = fetchAllFaecherFromSemesternote(id: item.id, viewContext: viewContext)
        user.aktuellerNotenName = item.name
        user.aktuelleID = item.id.uuidString
        user.updateMode = true
    }
}


struct EmptySemesterCard: View {
    @ObservedObject var user: UserStore

    private func resetForNewSemester() {
        user.updateMode = false
        user.aktuellerFaecherArray = []
        user.aktuellerNotenName = ""
        user.aktuelleID = ""
    }

    var body: some View {
        NavigationLink(destination: SemesterNoteAusrechnen().environmentObject(user)
                       ) {
            Button {
                resetForNewSemester()
            } label: {
                FeatureCard(title: "Neues Semester anlegen",
                            icon: "plus.circle.fill",
                            active: true)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}




// MARK: - Kleine Row-View
private struct SemesterRowView: View {
    let index: Int
    let item: SemesternotenItem
    var onTap: () -> Void

    var displayName: String {
        item.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        ? "\(index + 1). Semester"
        : item.name
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(displayName)
                    .font(.headline)
                Text(item.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(String(format: "%.2f", item.semesterNote))
                .bold()
                .foregroundColor(colorForNote(item.semesterNote))
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
        .shadow(color: .black.opacity(0.03), radius: 3, x: 0, y: 1)
        .onTapGesture { onTap() }
    }
    
    private func colorForNote(_ note: Double) -> Color {
        switch note {
        case 0..<2.0: return .modeColorSwitch
        case 2.0..<3.5: return .modeColorSwitch
        default: return .modeColorSwitch
        }
    }
}


// MARK: - Extra Feature Card
private struct FeatureCard: View {
    let title: String
    let icon: String
    let active: Bool
    let showChevron: Bool // neu

    init(title: String, icon: String, active: Bool, showChevron: Bool = false) {
        self.title = title
        self.icon = icon
        self.active = active
        self.showChevron = showChevron
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(active ? .mainColor : .gray)
            Text(title)
                .font(.subheadline.weight(.semibold)).foregroundColor(active ? .mainColor : .gray)
            Spacer()
            if showChevron && active { Image(systemName: "chevron.right").foregroundColor(.secondary) }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemBackground)))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}


// MARK: - ViewModel
class HomeViewModel: ObservableObject {
    @Published var semesterNoten: [SemesternotenItem] = []
    @Published var abiSemesterNoten: [SemesternotenItem] = []
    @Published var noteTeilenClicked = false
    @Published var shareNote = SemesternotenItem(id: UUID(), name: "", semesterNote: -1, semesterPunkte: 0.0, date: Date())
    @Published var shareNoteEndnote = false
    
    var firstSemester: SemesternotenItem? {
        semesterNoten.first
    }
    
    func loadSemesterNoten(context: NSManagedObjectContext) {
        semesterNoten = fetchAllSemesterNoten(viewContext: context) ?? []
        abiSemesterNoten = Array(semesterNoten.prefix(4))
    }
}

extension View {
    func cardStyle() -> some View {
        self
            .padding()
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemBackground)))
            .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
    }
}






struct BannerADView: UIViewRepresentable {
    
    var bannerID: String
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: UIViewRepresentableContext<BannerADView>) -> GADBannerView {
        let banner = GADBannerView(adSize: GADAdSizeBanner)
        banner.adUnitID = bannerID
        banner.rootViewController = UIApplication.shared.windows.first?.rootViewController
        banner.load(GADRequest())
        banner.delegate = context.coordinator
        return banner
        
    }
    func updateUIView(_ uiView: GADBannerView, context: UIViewRepresentableContext<BannerADView>) {
    }
    
    class Coordinator: NSObject, GADBannerViewDelegate {
        var parent: BannerADView
        init(_ parent: BannerADView) {
            self.parent = parent
        }
        func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
            print("Did Receive Ad")
            
        }
        func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
            print("Failed Receive Ad")
        }
    }
    
}

struct PhoneHomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
