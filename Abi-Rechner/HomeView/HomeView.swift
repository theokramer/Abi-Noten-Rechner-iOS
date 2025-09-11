//
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
    
    private func resetForNewSemester() {
        user.ausrechnen = true
        user.updateMode = false
        user.aktuellerFaecherArray = []
        user.aktuellerNotenName = ""
        user.aktuelleID = ""
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(spacing: 24) {
                        
                        // MARK: - Aktuelles Semester
                        if let currentSemester = user.semesterArray.first {
                            VStack(spacing: 12) {
                                HStack {
                                    Text(currentSemester.name.isEmpty ? "Aktuelles Semester" : currentSemester.name)
                                        .font(.title2).bold()
                                    Spacer()
                                    Button(action: { viewModel.noteTeilenClicked = true }) {
                                        Image(systemName: "square.and.arrow.up")
                                            .foregroundColor(.accentColor)
                                    }
                                }
                                
                                HStack {
                                    statItem(title: "Note", value: String(format: "%.2f", currentSemester.semesterNote), color: colorForNote(currentSemester.semesterNote))
                                    Divider().frame(height: 28)
                                    statItem(title: "Punkte", value: String(format: "%.1f", currentSemester.semesterPunkte))
                                }
                                
                                Button {
                                    openSemester(item: currentSemester)
                                } label: {
                                    Text("Semester bearbeiten")
                                        .font(.subheadline.weight(.semibold))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                }
                                .buttonStyle(.automatic)
                            }
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 16).fill(Color.blue.opacity(0.05)))
                            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
                            .padding(.horizontal)
                        } else {
                            VStack(spacing: 12) {
                                Text("Noch kein Semester angelegt")
                                    .font(.title3).bold()
                                    .foregroundColor(.secondary)
                                
                                NavigationLink(destination: SemesterNoteAusrechnen().environmentObject(user)) {
                                    FeatureCard(title: "Neues Semester anlegen", icon: "plus.circle.fill", active: true)
                                }.onTapGesture {
                                    resetForNewSemester()
                                }
                            }
                            .cardStyle()
                            .padding(.horizontal)
                        }
                        
                        // MARK: - Übersicht aller Semester
                        if !user.semesterArray.isEmpty {
                            let sortedSemesters = user.semesterArray.sorted { $0.date < $1.date }
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("Deine Semester")
                                        .font(.headline)
                                    Spacer()
                                    if user.userHasGoldPremium, let avg = overallAverage {
                                        Text("Ø \(String(format: "%.2f", avg))")
                                            .font(.subheadline).bold()
                                            .foregroundColor(user.userHasGoldPremium ? .secondary : .gray)
                                        
                                    }
                                }
                                
                                LazyVStack(spacing: 12) {
                                    ForEach(sortedSemesters.indices, id: \.self) { idx in
                                        let item = sortedSemesters[idx]
                                        
                                        SemesterRowView(index: idx, item: item) {
                                            // Semester bearbeiten immer erlaubt
                                            openSemester(item: item)
                                        }
                                    }
                                }
                                
                                
                                
                                // Neues Semester anlegen
                                    if user.userHasGoldPremium {
                                        NavigationLink(destination: SemesterNoteAusrechnen().environmentObject(user)) {
                                            FeatureCard(title: "Neues Semester anlegen", icon: "plus.circle.fill", active: true)
                                        }.onTapGesture {
                                            resetForNewSemester()
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    } else {
                                        Button(action: {
                                            user.spendenClicked = true
                                        }) {
                                            FeatureCard(title: "Neues Semester anlegen", icon: "plus.circle.fill", active: false)
                                        }
                                    }
                                
                            }
                            .cardStyle()
                            .padding(.horizontal)
                        }
                        
                        
                        VStack(spacing: 16) {
                            if user.userHasGoldPremium {
                                NavigationLink(destination: AbiClicked()
                                                .environmentObject(user)) {
                                    FeatureCard(title: "Endnote berechnen", icon: "star.circle.fill", active: true)
                                }
                                .buttonStyle(PlainButtonStyle())
                            } else {
                                Button(action: {
                                    user.spendenClicked = true
                                }) {
                                    FeatureCard(title: "Endnote berechnen", icon: "star.circle.fill", active: false)
                                }
                            }
                        }
                        .padding(.horizontal)

                        
                        Color.clear.frame(height: 100)
                        
                    }
                    .padding(.top)
                    
                    
                    
                }
                VStack {
                                Spacer()
                                HStack(spacing: 16) {
                                    PremiumButton()
                                        .environmentObject(user)
                                    ShareNoteButton(viewModel: viewModel)
                                        .environmentObject(user)
                                    
                                }
                                .padding()
                                
                                .padding(.horizontal)
                                .padding(.bottom)

                            }
            }
            .navigationTitle("Abi Noten Rechner")
            .onAppear {
                // Lade zuerst Core Data
                viewModel.loadSemesterNoten(context: viewContext)
                
                // Synchronisiere mit UserStore
                user.semesterArray = viewModel.semesterNoten
            }
            .sheet(isPresented: $viewModel.noteTeilenClicked) {
                NoteSharingSheet(viewModel: viewModel)
                    .environmentObject(user)
            }
        }
    }
    
    // MARK: - Helpers
    private var overallAverage: Double? {
        guard !viewModel.semesterNoten.isEmpty else { return nil }
        let sum = viewModel.semesterNoten.reduce(0.0) { $0 + $1.semesterNote }
        return sum / Double(viewModel.semesterNoten.count)
    }
    
    private func openSemester(item: SemesternotenItem) {
        user.ausrechnen = true
        user.siteOpened = 1
        user.aktuellerFaecherArray = fetchAllFaecherFromSemesternote(id: item.id, viewContext: viewContext)
        user.aktuellerNotenName = item.name
        user.aktuelleID = item.id.uuidString
        user.updateMode = true
    }
    
    private func statItem(title: String, value: String, color: Color = .primary) -> some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
                .bold()
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func colorForNote(_ note: Double) -> Color {
        switch note {
        case 0..<2.0: return .modeColorSwitch
        case 2.0..<3.5: return .modeColorSwitch
        default: return .modeColorSwitch
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
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
            .shadow(color: .black.opacity(0.03), radius: 3, x: 0, y: 1)
        
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
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(active ? .accentColor : .gray)
            Text(title)
                .font(.subheadline.weight(.semibold))
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemBackground)))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .foregroundColor(active ? .accentColor : .gray)
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

// MARK: - Card Style Modifier
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
