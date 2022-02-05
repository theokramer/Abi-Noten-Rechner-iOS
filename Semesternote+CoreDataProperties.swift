//
//  Semesternote+CoreDataProperties.swift
//  Abi-Rechner
//
//  Created by Theo Kramer on 29.01.21.
//
//

import Foundation
import CoreData

extension Semesternote {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Semesternote> {
        return NSFetchRequest<Semesternote>(entityName: "Semesternote")
    }

    @NSManaged public var date: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var semesterNote: Double
    @NSManaged public var semesterPunkte: Double
    @NSManaged public var faecher: NSSet?

}

// MARK: Generated accessors for faecher
extension Semesternote {

    @objc(addFaecherObject:)
    @NSManaged public func addToFaecher(_ value: Fach)

    @objc(removeFaecherObject:)
    @NSManaged public func removeFromFaecher(_ value: Fach)

    @objc(addFaecher:)
    @NSManaged public func addToFaecher(_ values: NSSet)

    @objc(removeFaecher:)
    @NSManaged public func removeFromFaecher(_ values: NSSet)

}

extension Semesternote: Identifiable {

}
