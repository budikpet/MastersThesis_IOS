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
    @objc dynamic public var _id: Int64 = -1
    @objc dynamic public var name: String = "-"
    @objc dynamic public var name_latin: String = "-"
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
    @objc dynamic public var food_detail: String = "-"
    @objc dynamic public var sizes: String = "-"
    @objc dynamic public var reproduction: String = "-"
    @objc dynamic public var interesting_data: String = "-"
    @objc dynamic public var about_placement_in_zoo_prague: String = "-"
    @objc dynamic public var location_in_zoo: String = "-"
    public let map_locations = List<Int64>()

    override public static func primaryKey() -> String? {
        return "_id"
    }

    public convenience init(withId id: Int64) {
        self.init()
        self._id = id
    }

    public convenience init(using fetchedData: FetchedAnimalData) {
        self.init()
        self._id = fetchedData._id
        self.name = fetchedData.name
        self.name_latin = fetchedData.latin_name
        self.base_summary = fetchedData.base_summary
        self.image_url = fetchedData.image_url
        self.class_ = fetchedData.class_
        self.class_latin = fetchedData.class_latin
        self.order = fetchedData.order
        self.order_latin = fetchedData.order_latin
        self.continent = fetchedData.continent
        self.continent_detail = fetchedData.continent_detail
        self.biotop = fetchedData.biotop
        self.biotop_detail = fetchedData.biotop_detail
        self.food = fetchedData.food
        self.food_detail = fetchedData.food_detail
        self.sizes = fetchedData.sizes
        self.reproduction = fetchedData.reproduction
        self.interesting_data = fetchedData.interesting_data
        self.about_placement_in_zoo_prague = fetchedData.about_placement_in_zoo_prague
        self.location_in_zoo = fetchedData.location_in_zoo
        self.map_locations.append(objectsIn: fetchedData.map_locations)
    }

    public func createShownLocation() -> String {
        var res: String = ""
        if(self.location_in_zoo == "-" && self.map_locations.count == 0) {
            res = "-"
        } else if(self.location_in_zoo == "-") {
            res = L10n.Label.externalPen
        } else if(self.map_locations.count == 0) {
            res = self.location_in_zoo
        } else {
            res = "\(self.location_in_zoo), \(L10n.Label.externalPen)"
        }
        res = res.trimmed().lowercased().capitalizingFirstLetter()

        return res
    }
}

struct FetchedAnimalData {
    let _id: Int64
    let name: String
    let latin_name: String
    let base_summary: String
    let image_url: String
    let class_: String
    let class_latin: String
    let order: String
    let order_latin: String
    let continent: String
    let continent_detail: String
    let biotop: String
    let biotop_detail: String
    let food: String
    let food_detail: String
    let sizes: String
    let reproduction: String
    let interesting_data: String
    let about_placement_in_zoo_prague: String
    let location_in_zoo: String
    let map_locations: [Int64]

    // swiftlint:disable force_cast
    init(using dict: [String: Any]) {
        self._id = dict["_id"] as! Int64
        self.name = (dict["name"] as? String) ?? "-"
        self.latin_name = (dict["latin_name"] as? String) ?? "-"
        self.base_summary = (dict["base_summary"] as? String) ?? "-"
        self.class_ = (dict["class_"] as? String) ?? "-"
        self.class_latin = (dict["class_latin"] as? String) ?? "-"
        self.order = (dict["order"] as? String) ?? "-"
        self.order_latin = (dict["order_latin"] as? String) ?? "-"
        self.continent = (dict["continent"] as? String) ?? "-"
        self.continent_detail = (dict["continent_detail"] as? String) ?? "-"
        self.biotop = (dict["biotop"] as? String) ?? "-"
        self.biotop_detail = (dict["biotop_detail"] as? String) ?? "-"
        self.food = (dict["food"] as? String) ?? "-"
        self.food_detail = (dict["food_detail"] as? String) ?? "-"
        self.sizes = (dict["sizes"] as? String) ?? "-"
        self.reproduction = (dict["reproduction"] as? String) ?? "-"
        self.interesting_data = (dict["interesting_data"] as? String) ?? "-"
        self.about_placement_in_zoo_prague = (dict["about_placement_in_zoo_prague"] as? String) ?? "-"
        self.location_in_zoo = (dict["location_in_zoo"] as? String) ?? "-"
        self.map_locations = (dict["map_locations"] as? [Int64]) ?? []

        if let image_url = (dict["image"] as? String) {
            if(image_url.hasPrefix("https://")) {
                self.image_url = image_url
            } else if(image_url.hasPrefix("http://")) {
                self.image_url = image_url.replacingOccurrences(of: "http", with: "https")
            } else {
                self.image_url = "https://\(image_url)"
            }
        } else {
            // TODO: Change to default image?
            self.image_url = "-"
        }
    }
}
