//
//  GlobalFuncs.swift
//  NotenRechner
//
//  Created by Theo Kramer on 02.02.22.
//

import SwiftUI
import CoreData

func countdown(date2: Date) -> DateComponents {
    var dateComponents = DateComponents()
    dateComponents.calendar = Calendar.current
    dateComponents.year = 2022
    dateComponents.month = 1
    dateComponents.day = 20
    dateComponents.hour = 00
    
    let date: Date = dateComponents.date ?? Date()
    
    let components = Calendar.current.dateComponents([.day, .hour, .minute, .second], from: date2, to: date)
    
    return components
}

func updateDifferenceBetweenDates() {
    let day = (countdown(date2: Date()).day ?? 0)
    let hour = (countdown(date2: Date()).hour ?? 0)
    let minute = (countdown(date2: Date()).minute ?? 0)
    let second = (countdown(date2: Date()).second ?? 0)
    var dayString = ""
    var hourString = ""
    var minuteString = ""
    var secondString = ""
    
    if day < 10 {
       dayString += "0"
        
    }
    dayString += String(day)
    if hour < 10 {
        hourString += "0"
        
    }
    hourString += String(hour)
    if minute < 10 {
        minuteString += "0"
        
    }
    minuteString += String(minute)
    if second < 10 {
        secondString += "0"
        
    }
    secondString += String(second)
    UserStore().differenceBetweenDates =  "\(dayString):\(hourString):\(minuteString):\(secondString)"
}

func fetchAllSemesterNoten(viewContext: NSManagedObjectContext) -> [SemesternotenItem]? {
    var semesternoten: [SemesternotenItem] = []
    let semesternotenRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Semesternote")
    do {
        let results = try viewContext.fetch(semesternotenRequest)
        if !results.isEmpty {
            for i in results {
                if let result = i as? NSManagedObject {
                    if result.value(forKey: "id") != nil {
                        guard let thisID = result.value(forKey: "id") as? UUID else {
                            return nil
                        }
                        guard let name = result.value(forKey: "name") as? String else {
                            return nil
                        }

                        guard let semesterNote = result.value(forKey: "semesterNote") as? Double else {
                            return nil
                        }
                        guard let semesterPunkte = result.value(forKey: "semesterPunkte") as? Double else {
                            return nil
                        }
                        guard let date = result.value(forKey: "date") as? Date else {
                            return nil
                        }

                        let semesternote = SemesternotenItem(id: thisID, name: name,
                        semesterNote: semesterNote, semesterPunkte: semesterPunkte, date: date)
                        semesternoten.append(semesternote)
                    }

                }
            }
            semesternoten = semesternoten.sorted(by: {$0.date.compare($1.date) == .orderedDescending})
        }
        } catch {
            print(error.localizedDescription)
        }
    if semesternoten.isEmpty {
        return nil
    } else {
        return semesternoten
    }

}

func fetchAllFaecherFromSemesternote(id: UUID, viewContext: NSManagedObjectContext) -> [FachItem] {
    var faecher: [FachItem] = []
    let fachRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Fach")
    do {
        let results = try viewContext.fetch(fachRequest)
        if !results.isEmpty {
            for i in results {
                if let result = i as? NSManagedObject {
                    if result.value(forKey: "id") != nil {
                        if result.value(forKey: "alsSemesterFach") != nil {
                            guard let semesternote = result.value(forKey: "alsSemesterFach") as? Semesternote else {
                                return [FachItem(id: UUID(), name: "", note: "", gewichtung: "1", position: 1)]
                            }

                                if semesternote.id == id {
                                    let fachID = result.value(forKey: "id") as? UUID ?? UUID()
                                    let fachName = result.value(forKey: "name") as? String ?? ""
                                    let fachNote = result.value(forKey: "note") as? String ?? ""
                                    let fachGewichtung = result.value(forKey: "gewichtung") as? Int64 ?? 1

                                        let fachPosition  = result.value(forKey: "position") as? Int64 ?? 1

                                    let newFach = FachItem(
                                        id: fachID, name: fachName, note: fachNote,
                                        gewichtung: "\(fachGewichtung)", position: Int64(fachPosition))
                                    faecher.append(newFach)
                                }

                        }

                    }

                }
            }
        }
            faecher = faecher.sorted(by: {$0.position < $1.position})
        } catch {
            print(error.localizedDescription)
        }

    return faecher
}
