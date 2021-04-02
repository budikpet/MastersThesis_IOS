//
//  FilterClasses.swift
//  MastersThesisIOS
//
//  Created by Petr Budík on 29/03/2021.
//  Copyright © 2021 Petr Budík. All rights reserved.
//

import RealmSwift

class AnimalFilter: Object {
    /** Type name of the filter which says which AnimalData attribute it is supposed to filter (class, continent etc.) */
    @objc dynamic public var type: String = "-"

    /** Value of the filtered attribute. */
    public let values = List<String>()

    override public static func primaryKey() -> String? {
        return "type"
    }

    public convenience init(_ fetchedAnimalFilter: FetchedAnimalFilter) {
        self.init()
        self.type = fetchedAnimalFilter.type
        self.values.append(objectsIn: fetchedAnimalFilter.values)
    }
}

struct FetchedAnimalFilter {
    /** Type name of the filter which says which AnimalData attribute it is supposed to filter (class, continent etc.) */
    let type: String

    /** All values of the given filter type. */
    let values: [String]

    init(ofType type: String, _ values: [String]) {
        self.type = type
        self.values = values
    }
}
