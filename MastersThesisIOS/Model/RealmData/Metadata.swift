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

    public convenience init(using fetchedMetadata: FetchedMetadata) {
        self.init()
        self._id = 0
        self.next_update = fetchedMetadata.next_update
        self.last_update_start = fetchedMetadata.last_update_start
        self.last_update_end = fetchedMetadata.last_update_end
    }
}

struct FetchedMetadata {
    let next_update: Date
    let last_update_start: Date
    let last_update_end: Date
    let scheduler_state: Int

    // swiftlint:disable force_cast
    init(using dict: [String: Any]) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"

        self.scheduler_state = (dict["scheduler_state"] as? Int) ?? 0
        self.next_update = formatter.date(from: FetchedMetadata.removedMillis(dict["next_update"] as! String)) ?? Date()
        self.last_update_start = formatter.date(from: FetchedMetadata.removedMillis(dict["last_update_start"] as! String)) ?? Date()
        self.last_update_end = formatter.date(from: FetchedMetadata.removedMillis(dict["last_update_end"] as! String)) ?? Date()
    }

    private static func removedMillis(_ dateString: String) -> String {
        return dateString.replacingOccurrences(of: "\\.\\d+", with: "", options: .regularExpression)
    }
}

