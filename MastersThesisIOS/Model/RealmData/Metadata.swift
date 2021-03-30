//
//  Metadata.swift
//  MastersThesisIOS
//
//  Created by Petr Budík on 29/03/2021.
//  Copyright © 2021 Petr Budík. All rights reserved.
//

import RealmSwift

class Metadata: Object {
    @objc dynamic public var _id: Int = 0
    @objc dynamic public var next_update: Date = Date()
    @objc dynamic public var last_update_start: Date = Date()
    @objc dynamic public var last_update_end: Date = Date()

    override public static func primaryKey() -> String? {
        return "_id"
    }

    public convenience init(withId id: Int) {
        self.init()
        self._id = id
    }
}
