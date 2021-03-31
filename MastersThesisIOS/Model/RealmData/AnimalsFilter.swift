//
//  FilterClasses.swift
//  MastersThesisIOS
//
//  Created by Petr Budík on 29/03/2021.
//  Copyright © 2021 Petr Budík. All rights reserved.
//

import RealmSwift

class AnimalsFilter: Object {
    @objc dynamic public var _id: Int = 0

    /** Type name of the filter which says which AnimalData attribute it is supposed to filter (class, continent etc.) */
    @objc dynamic public var type: String = "-"

    /** Value of the filtered attribute. */
    @objc dynamic public var value: String = "-"

    override public static func primaryKey() -> String? {
        return "_id"
    }

    public convenience init(withId id: Int, type: String, value: String) {
        self.init()
        self._id = id
        self.type = type
        self.value = value
    }
}
