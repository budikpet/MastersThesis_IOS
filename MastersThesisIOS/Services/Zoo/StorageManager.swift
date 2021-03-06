//
//  StorageManager.swift
//  MastersThesisIOS
//
//  Created by Petr Budík on 30/03/2021.
//  Copyright © 2021 Petr Budík. All rights reserved.
//

import Foundation
import RealmSwift
import ReactiveSwift
import os.log

protocol HasStorageManager {
    var storageManager: StorageManaging { get }
}

protocol StorageManagingActions {
    var updateLocalDB: Action<Bool, UpdateStatus, UpdateError> { get }
}

protocol StorageManaging {
    var actions: StorageManagingActions { get }
    var realm: Realm { get }

    func realmEdit(_ editClosure: (Realm) -> ())

    func getMbtilesUrl() -> URL
    func getSceneUrl() -> URL
    func loadMapConfig() -> MapConfig

    func loadLocalMapConfig() -> MapConfig
    func loadMapMetadata() -> MapMetadata
    func loadAnimalData() -> [DetachedAnimalData]
    func loadAnimalFilters() -> [DetachedAnimalFilter]
}

/**
 Handles updating of local Realm DB.
 */
final class StorageManager: StorageManaging, StorageManagingActions {
    typealias Dependencies = HasZooAPI & HasRealm
    private let zooApi: ZooAPIServicing

    // MARK: Actions
    internal var actions: StorageManagingActions { self }
    internal lazy var updateLocalDB: Action<Bool, UpdateStatus, UpdateError> = Action { [unowned self] isForced in
        self.runUpdate(forced: isForced)
    }

    // MARK: Local
    internal var realm: Realm
    internal var metadata: Results<Metadata>

    private static let mbtilesFilename: String = "zooPrague.mbtiles"

    init(dependencies: Dependencies) {
        self.zooApi = dependencies.zooAPI
        self.realm = dependencies.realm
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
        var producers = [updateAnimalData(), updateAnimalFilters(), updateMapMetadata(), updateMapData()]

        if(realm.isEmpty) {
            // If realm is empty, first download data from local files
            producers.insert(runUpdateFromLocalFiles(), at: 0)
        }

        return SignalProducer(producers)
            .flatten(.concat)
    }
}

// MARK: Protocol

extension StorageManager {
    /// - Returns: A URL to the MBTiles file. Either the default one from resources or the downloaded one from documents directory.
    func getMbtilesUrl() -> URL {
        let storedMbtiles = URL.documents.appendingPathComponent(StorageManager.mbtilesFilename)

        if(FileManager.default.fileExists(atPath: storedMbtiles.path)) {
            // Return MBTiles that was downloaded
            return storedMbtiles
        }

        // Return default MBTiles from resources
        guard let mbtilesUrl = Bundle.resources.url(forResource: "defaultZooPrague", withExtension: "mbtiles", subdirectory: "Map") else { fatalError("MBTiles file not found.") }
        return mbtilesUrl
    }

    /// - Returns: A URL to the scene file that is stored in resources.
    func getSceneUrl() -> URL {
        guard let sceneUrl = Bundle.resources.url(forResource: "bubbleWrapStyle", withExtension: "yaml", subdirectory: "Map/bubbleWrapStyle") else { fatalError("Scene file not found.") }
        return sceneUrl
    }

    /// - Returns: A MapConfig object created from default resources.
    public func loadMapConfig() -> MapConfig {
        guard let configFile = Bundle.resources.url(forResource: "defaultConfig", withExtension: "json", subdirectory: "Map") else { fatalError("Config file not found.") }

        do {
            let configData = try Data(contentsOf: configFile)
            return try JSONDecoder().decode(MapConfig.self, from: configData)
        } catch {
            fatalError("Could not load map config.")
        }
    }
}

// MARK: Helper functions for update from remote DB

extension StorageManager {
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
        SignalProducer([zooApi.getClasses(), zooApi.getFoods(), zooApi.getBiotops(), zooApi.getZooHouses()])
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
                    realm.delete(realm.objects(Road.self))
                    realm.delete(realm.objects(RoadNode.self))

                    realm.add(Metadata(using: mapMetadata.metadata), update: .modified)
                    realm.add(mapMetadata.roadNodes.map() { RoadNode($0) }, update: .modified)
                    realm.add(mapMetadata.roads.map() { Road($0) }, update: .modified)
                }

                return SignalProducer(value: UpdateStatus.dataUpdated)
            }
    }

    /**
     - Returns:
        A SignalProducer that downloads map data and stores it in local document storage, resulting in UpdateStatus.
     */
    private func updateMapData() -> SignalProducer<UpdateStatus, UpdateError> {
        zooApi.getMapData()
            .mapError { UpdateError.updateError($0) }
            .observe(on: QueueScheduler.main)
            .flatMap(.concat) { (data: Data) -> SignalProducer<UpdateStatus, UpdateError> in
                let url = URL.documents.appendingPathComponent(StorageManager.mbtilesFilename)

                do {
                    try data.write(to: url, options: .atomic)
                } catch {
                    return SignalProducer(error: UpdateError.filesystemError)
                }

                return SignalProducer(value: UpdateStatus.dataUpdated)
            }
    }
}

// MARK: Helper functions for update from local files

extension StorageManager {
    /// - Returns: A SignalProducer that stores all default data from resources to Realm DB
    internal func runUpdateFromLocalFiles() -> SignalProducer<UpdateStatus, UpdateError> {
        SignalProducer { [weak self] observer, lifetime in
            os_log("Updating from local files.", log: Logger.appLog(), type: .info)

            guard let self = self else {
                observer.send(error: UpdateError.realmError)
                return
            }

            self.realmEdit { (realm: Realm) in
                let mapMetadata = self.loadMapMetadata()
                realm.add(Metadata(using: mapMetadata.metadata), update: .modified)
                realm.add(mapMetadata.roadNodes.map() { RoadNode($0) }, update: .modified)
                realm.add(mapMetadata.roads.map() { Road($0) }, update: .modified)
                let animalData = self.loadAnimalData()
                realm.add(animalData.map { AnimalData(using: $0) }, update: .modified)
                let animalFilters = self.loadAnimalFilters()
                realm.add(animalFilters.map { AnimalFilter($0) }, update: .modified)
            }

            observer.send(value: UpdateStatus.dataUpdated)
            observer.sendCompleted()
        }
    }

    internal func loadLocalMapConfig() -> MapConfig {
        guard let configFile = Bundle.resources.url(forResource: "defaultConfig", withExtension: "json", subdirectory: "Map") else { fatalError("Config file not found.") }

        do {
            let data = try Data(contentsOf: configFile)
            return try JSONDecoder().decode(MapConfig.self, from: data)
        } catch {
            fatalError("Could not load map config.")
        }
    }

    internal func loadMapMetadata() -> MapMetadata {
        guard let configFile = Bundle.resources.url(forResource: "defaultMapMetadata", withExtension: "json", subdirectory: "Map") else { fatalError("Map metadata file not found.") }

        do {
            let data = try Data(contentsOf: configFile)
            if let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                return MapMetadata(using: dict)
            } else {
                throw "Could not parse map metadata file into JSON."
            }
        } catch {
            fatalError("Could not load map config.")
        }
    }

    internal func loadAnimalData() -> [DetachedAnimalData] {
        guard let configFile = Bundle.resources.url(forResource: "defaultAnimalData", withExtension: "json", subdirectory: "Map") else { fatalError("Animal data file not found.") }

        do {
            let data = try Data(contentsOf: configFile)
            if let dicts = try JSONSerialization.jsonObject(with: data, options: []) as? Array<[String: Any]> {
                return dicts.map { DetachedAnimalData(using: $0) }
            } else {
                throw "Could not parse animal data file into JSON."
            }
        } catch {
            fatalError("Could not load map config.")
        }
    }

    internal func loadAnimalFilters() -> [DetachedAnimalFilter] {
        guard let configFile = Bundle.resources.url(forResource: "defaultFilters", withExtension: "json", subdirectory: "Map") else { fatalError("Filters file not found.") }

        do {
            let data = try Data(contentsOf: configFile)
            if let dicts = try JSONSerialization.jsonObject(with: data, options: []) as? [String: [String]] {
                guard let classes = dicts["classes"],
                      let biotops = dicts["biotops"],
                      let foods = dicts["foods"],
                      let zooHouses = dicts["zooHouses"]
                else {
                    fatalError("Filters could not be loaded into dictionaries.")
                }
                return [DetachedAnimalFilter(ofType: "class_", classes), DetachedAnimalFilter(ofType: "biotop", biotops), DetachedAnimalFilter(ofType: "food", foods), DetachedAnimalFilter(ofType: "location_in_zoo", zooHouses)]
            } else {
                throw "Could not parse animal data file into JSON."
            }
        } catch {
            fatalError("Could not load map config.")
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
    case filesystemError
}
