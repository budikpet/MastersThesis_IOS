//
//  TestRealmDBManager.swift
//  MastersThesisIOS
//
//  Created by Petr Budík on 30/03/2021.
//  Copyright © 2021 Petr Budík. All rights reserved.
//

import Foundation
import RealmSwift
import ReactiveSwift
import os.log
@testable import MastersThesisIOS

/**
 Handles updating of local Realm DB.
 */
final class TestRealmInitializer {
    typealias Dependencies = HasRealm & HasRealmDBManager

    // MARK: Local
    internal var realm: Realm
    internal var realmDbManager: RealmDBManaging

    init(dependencies: Dependencies) {
        self.realm = dependencies.realm
        self.realmDbManager = dependencies.realmDBManager
    }

    public func updateRealm() {
        self.realmDbManager.realmEdit { (realm: Realm) in
            let mapMetadata = realmDbManager.loadMapMetadata()
            realm.add(Metadata(using: mapMetadata.metadata), update: .modified)
            realm.add(mapMetadata.roadNodes.map() { RoadNode($0) }, update: .modified)
            realm.add(mapMetadata.roads.map() { Road($0) }, update: .modified)

            let animalData = realmDbManager.loadAnimalData()
            realm.add(animalData.map { AnimalData(using: $0) }, update: .modified)

            let animalFilters = realmDbManager.loadAnimalFilters()
            realm.add(animalFilters.map { AnimalFilter($0) }, update: .modified)
        }
    }
}
