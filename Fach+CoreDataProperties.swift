//
//  Fach+CoreDataProperties.swift
//  Abi-Rechner
//
//  Created by Theo Kramer on 29.01.21.
//
//

import Foundation
import CoreData

extension Fach {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Fach> {
        return NSFetchRequest<Fach>(entityName: "Fach")
    }

    @NSManaged public var gewichtung: Int64
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var note: String?
    @NSManaged public var position: Int64
    @NSManaged public var alsSemesterFach: Semesternote?

}
