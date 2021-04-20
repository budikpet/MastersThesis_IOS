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

protocol RealmDBManaging {
    var actions: RealmDBManagingActions { get }
    var realm: Realm { get }

    func realmEdit(_ editClosure: (Realm) -> ())
}

/**
 Handles updating of local Realm DB.
 */
final class RealmDBManager: RealmDBManaging, RealmDBManagingActions {
    typealias Dependencies = HasZooAPI
    private let zooApi: ZooAPIServicing

    // MARK: Actions
    internal var actions: RealmDBManagingActions { self }
    internal lazy var updateLocalDB: Action<Bool, UpdateStatus, UpdateError> = Action { [unowned self] isForced in
        self.runUpdate(forced: isForced)
    }

    // MARK: Local
    internal var realm: Realm
    internal var metadata: Results<Metadata>

    init(dependencies: Dependencies) {
        self.zooApi = dependencies.zooAPI
        self.realm = RealmDBManager.initRealm()
        self.metadata = realm.objects(Metadata.self).filter("_id == 0")
    }

    func realmEdit(_ editClosure: (Realm) -> ()) {
        do {
            try realm.write() {
                editClosure(realm)
            }
        } catch (let e) {
            fatalError("Error occured when writing to realm: \(e)")
        }
    }
}

// MARK: Helpers

extension RealmDBManager {
    /**
     Checks whether it is necessary to start an update. If it is necessary then it starts the update.
     - Returns:
        A SignalProducer that either returns `UpdateStatus.dataNotUpdated` if it isn't necessary to update or a SignalProducer that handles updating all data.
     */
    private func runUpdate(forced: Bool = false) -> SignalProducer<UpdateStatus, UpdateError> {
        if let metadata = self.metadata.first, !forced {
            if(metadata.last_update_end < Date()) {
                // If the end of the last update happened before today then no data is probably there
                os_log("Update not needed.", log: Logger.networkingLog(), type: .info)
                return SignalProducer<UpdateStatus, UpdateError>(value: .dataNotUpdated)
                    .delay(1.0, on: QueueScheduler.main)
            }
        }

        os_log("Update required.", log: Logger.networkingLog(), type: .info)

        return SignalProducer([updateAnimalData(), updateAnimalFilters(), updateMapMetadata()])
            .flatten(.concat)
    }

    /**
     - Returns:
        A SignalProducer that downloads all AnimalData data and stores it in Realm DB, resulting in UpdateStatus.
     */
    private func updateAnimalData() -> SignalProducer<UpdateStatus, UpdateError> {
        zooApi.getAnimals()
            .mapError() { UpdateError.updateError($0) }
            .observe(on: QueueScheduler.main)
            .flatMap(.concat) { [weak self] (metadata, animals) -> SignalProducer<UpdateStatus, UpdateError> in
                guard let self = self else { return SignalProducer(error: UpdateError.realmError) }

                os_log("Storing animal data.", log: Logger.appLog(), type: .info)

                self.realmEdit { (realm: Realm) in
                    realm.add(Metadata(using: metadata), update: .modified)
                    realm.add(animals.map() { AnimalData(using: $0) }, update: .modified)
                }

                return SignalProducer(value: UpdateStatus.dataUpdated)
            }
    }

    /**
     - Returns:
        A SignalProducer that combines results from all endpoints that contain filters data. Then all results are stored in Realm DB resulting in UpdateStatus.
     */
    private func updateAnimalFilters() -> SignalProducer<UpdateStatus, UpdateError> {
        SignalProducer([zooApi.getClasses(), zooApi.getFoods(), zooApi.getBiotops()])
            .flatten(.concat)
            .collect()
            .mapError() { UpdateError.updateError($0) }
            .observe(on: QueueScheduler.main)
            .flatMap(.concat) { [weak self] resultsList -> SignalProducer<UpdateStatus, UpdateError> in
                guard let self = self else { return SignalProducer(error: UpdateError.realmError) }

                os_log("Storing animal filters.", log: Logger.appLog(), type: .info)

                guard let fetchedMetadata = resultsList.first?.0 else { return SignalProducer(value: UpdateStatus.dataUpdated) }

                self.realmEdit { (realm: Realm) in
                    realm.add(Metadata(using: fetchedMetadata), update: .modified)
                    for (_, filter) in resultsList {
                        realm.add(AnimalFilter(filter), update: .modified)
                    }
                }

                return SignalProducer(value: UpdateStatus.dataUpdated)
            }
    }

    /**
     - Returns:
        A SignalProducer that downloads map metadata and stores it in Realm DB, resulting in UpdateStatus.
     */
    private func updateMapMetadata() -> SignalProducer<UpdateStatus, UpdateError> {
        zooApi.getMapMetadata()
            .mapError() { UpdateError.updateError($0) }
            .observe(on: QueueScheduler.main)
            .flatMap(.concat) { [weak self] (mapMetadata: MapMetadata) -> SignalProducer<UpdateStatus, UpdateError> in
                guard let self = self else { return SignalProducer(error: UpdateError.realmError) }

                os_log("Storing map metadata.", log: Logger.appLog(), type: .info)

                self.realmEdit { (realm: Realm) in
                    realm.add(Metadata(using: mapMetadata.metadata), update: .modified)
                    realm.add(mapMetadata.roadNodes.map() { RoadNode($0) }, update: .modified)
                    realm.add(mapMetadata.roads.map() { Road($0) }, update: .modified)
                }

                return SignalProducer(value: UpdateStatus.dataUpdated)
            }
    }

    /**
     Initializes `Realm` instance with all needed configuration
     - Returns:
        A new `Realm` instance.
     */
    private static func initRealm() -> Realm {
        do {
            // TODO: This configuration causes hard crash on start on physical device. Find out why.
//            guard let fileURL = FileManager.default
//                .containerURL(forSecurityApplicationGroupIdentifier: Bundle.main.bundleIdentifier ?? "cz.budikpet.MastersThesisIOS")?
//                .appendingPathComponent("default.realm")
//            else {
//                throw "Could not get fileURL for Realm configuration."
//            }
//            Realm.Configuration.defaultConfiguration = Realm.Configuration(fileURL: fileURL)

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
