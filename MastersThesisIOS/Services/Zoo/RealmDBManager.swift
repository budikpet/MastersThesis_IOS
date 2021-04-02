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
import os.log

protocol HasRealmDBManager {
    var realmDBManager: RealmDBManaging { get }
}

protocol RealmDBManagingActions {
    var updateLocalDB: Action<Bool, UpdateStatus, UpdateError> { get }
}

protocol RealmDBManagingObjects {
    var metadata: Results<Metadata> { get }
    var animalData: Results<AnimalData> { get }
    var animalsFilter: Results<AnimalsFilter> { get }
}

protocol RealmDBManaging {
    var actions: RealmDBManagingActions { get }
    var objects: RealmDBManagingObjects { get }
}

/**
 Handles updating of local Realm DB.
 */
final class RealmDBManager: RealmDBManaging, RealmDBManagingActions, RealmDBManagingObjects {
    typealias Dependencies = HasZooAPI
    private let realm: Realm!
    private let zooApi: ZooAPIServicing

    // MARK: Actions
    internal var actions: RealmDBManagingActions { self }
    internal lazy var updateLocalDB: Action<Bool, UpdateStatus, UpdateError> = Action { [unowned self] isForced in
        self.runUpdate(forced: isForced)
    }

    // MARK: Objects
    internal var objects: RealmDBManagingObjects { self }
    internal var metadata: Results<Metadata>
    internal var animalData: Results<AnimalData>
    internal var animalsFilter: Results<AnimalsFilter>

    init(dependencies: Dependencies) {
        self.zooApi = dependencies.zooAPI
        self.realm = RealmDBManager.initRealm()
        self.metadata = realm.objects(Metadata.self).filter("_id == 0")
        self.animalData = realm.objects(AnimalData.self)
            .sorted(byKeyPath: "name", ascending: true)
        self.animalsFilter = realm.objects(AnimalsFilter.self)
    }
}

// MARK: Helpers

extension RealmDBManager {
    private func runUpdate(forced: Bool = false) -> SignalProducer<UpdateStatus, UpdateError> {
        if let metadata = self.metadata.first, !forced {
            if(metadata.last_update_end < Date()) {
                // If the end of the last update happened before today then no data is probably there
                os_log("Update not needed.")
                return SignalProducer<UpdateStatus, UpdateError>(value: .dataNotUpdated)
                    .delay(1.0, on: QueueScheduler.main)
            }
        }

        os_log("Update required.")

        return SignalProducer([updateAnimalData(), updateAnimalFilters()])
            .flatten(.concat)
    }

    private func updateAnimalData() -> SignalProducer<UpdateStatus, UpdateError> {
        zooApi.getAnimals()
            .mapError() { UpdateError.updateError($0) }
            .observe(on: QueueScheduler.main)
            .flatMap(.concat) { [weak self] (metadata, animals) -> SignalProducer<UpdateStatus, UpdateError> in
                guard let realm = self?.realm else { return SignalProducer(error: UpdateError.realmError) }

                os_log("Storing animal data.")

                do {
                    try realm.write() {
                        realm.add(Metadata(using: metadata), update: .modified)
                        realm.add(animals.map() { AnimalData(using: $0) }, update: .modified)
                    }
                } catch (let e) {
                    fatalError("Error occured when writing to realm: \(e)")
                }

                return SignalProducer(value: UpdateStatus.dataUpdated)
            }
    }

    private func updateAnimalFilters() -> SignalProducer<UpdateStatus, UpdateError> {
        SignalProducer([zooApi.getClasses(), zooApi.getFoods(), zooApi.getBiotops()])
            .flatten(.concat)
            .collect()
            .mapError() { UpdateError.updateError($0) }
            .observe(on: QueueScheduler.main)
            .flatMap(.concat) { [weak self] resultsList -> SignalProducer<UpdateStatus, UpdateError> in
                guard let realm = self?.realm else { return SignalProducer(error: UpdateError.realmError) }

                os_log("Storing animal filters.")

                if(resultsList.isEmpty) {
                    return SignalProducer(value: UpdateStatus.dataUpdated)
                }

                do {
                    try realm.write() {
                        // swiftlint:disable force_unwrapping
                        realm.add(Metadata(using: resultsList.first!.0), update: .modified)
                        for (_, filter) in resultsList {
                            realm.add(AnimalsFilter(filter), update: .modified)
                        }
                    }
                } catch (let e) {
                    fatalError("Error occured when writing to realm: \(e)")
                }

                return SignalProducer(value: UpdateStatus.dataUpdated)
            }
    }

    private static func initRealm() -> Realm {
        do {
            guard let fileURL = FileManager.default
                .containerURL(forSecurityApplicationGroupIdentifier: Bundle.main.bundleIdentifier ?? "cz.budikpet.MastersThesisIOS")?
                .appendingPathComponent("default.realm")
            else {
                throw "Could not get fileURL for Realm configuration."
            }
            Realm.Configuration.defaultConfiguration = Realm.Configuration(fileURL: fileURL)

            return try Realm()
        } catch {
            fatalError("Error initializing new Realm for the first time: \(error)")
        }
    }
}

enum UpdateStatus {
    case dataUpdated
    case dataNotUpdated
}

enum UpdateError: Error {
    case realmError
    case updateError(RequestError)
}
