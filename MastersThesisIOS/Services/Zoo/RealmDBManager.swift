//
//  RealmDBManager.swift
//  MastersThesisIOS
//
//  Created by Petr Budík on 30/03/2021.
//  Copyright © 2021 Petr Budík. All rights reserved.
//

import Foundation
import RealmSwift
import ReactiveSwift

protocol HasRealmDBManager {
    var realmDBManager: RealmDBManaging { get }
}

protocol RealmDBManagingActions {

}

protocol RealmDBManaging {
    var actions: RealmDBManagingActions { get }
}

final class RealmDBManager: RealmDBManaging, RealmDBManagingActions {
    typealias Dependencies = HasRealm

    private let realm: Realm

    var actions: RealmDBManagingActions { self }

    init(dependencies: Dependencies) {
        self.realm = dependencies.realm
    }
}
