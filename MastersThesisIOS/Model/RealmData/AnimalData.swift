//
//  AnimalData.swift
//  MastersThesisIOS
//
//  Created by Petr Budík on 22/03/2021.
//  Copyright © 2021 Petr Budík. All rights reserved.
//

import Foundation
import RealmSwift

class AnimalData: Object {
    public let _id: Int64
    @objc dynamic public var name: String = "-"
    @objc dynamic public var latin_name: String = "-"
    @objc dynamic public var base_summary: String = "-"
    @objc dynamic public var image_url: String = "-"
    @objc dynamic public var class_: String = "-"
    @objc dynamic public var class_latin: String = "-"
    @objc dynamic public var order: String = "-"
    @objc dynamic public var order_latin: String = "-"
    @objc dynamic public var continent: String = "-"
    @objc dynamic public var continent_detail: String = "-"
    @objc dynamic public var biotop: String = "-"
    @objc dynamic public var biotop_detail: String = "-"
    @objc dynamic public var food: String = "-"
    @objc dynamic public var sizes: String = "-"
    @objc dynamic public var reproduction: String = "-"
    @objc dynamic public var interesting_data: String = "-"
    @objc dynamic public var about_placement_in_zoo_prague: String = "-"
    @objc dynamic public var location_in_zoo: String = "-"
    public let mapLocations = List<Int64>()

    override public static func primaryKey() -> String? {
        return "_id"
    }

    init(withId id: Int64) {
        self._id = id
    }
}
