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
    var updateLocalDB: Action<Bool, UpdateStatus, UpdateError> { get }
}

protocol RealmDBManaging {
    var actions: RealmDBManagingActions { get }
}

/**
 Handles updating of local Realm DB.
 */
final class RealmDBManager: RealmDBManaging, RealmDBManagingActions {
    typealias Dependencies = HasZooAPI

    var actions: RealmDBManagingActions { self }

    internal lazy var updateLocalDB: Action<Bool, UpdateStatus, UpdateError> = Action { [unowned self] isForced in self.runUpdate(forced: isForced) }

    private let zooApi: ZooAPIServicing
    private let realm: Realm!
    private let metadata: Results<Metadata>

    init(dependencies: Dependencies) {
        self.zooApi = dependencies.zooAPI
        self.realm = RealmDBManager.initRealm()
        self.metadata = realm.objects(Metadata.self).filter("_id == 0")
    }
}

// MARK: Helpers

extension RealmDBManager {
    private func runUpdate(forced: Bool = false) -> SignalProducer<UpdateStatus, UpdateError> {
        if let metadata = self.metadata.first, !forced {
            return SignalProducer<UpdateStatus, UpdateError>(value: .dataNotUpdated)
        }

        return zooApi.getAnimals()
            .mapError() { UpdateError.updateError($0) }
            .observe(on: QueueScheduler.main)
            .flatMap(.concat) { [weak self] (metadata, animals) -> SignalProducer<UpdateStatus, UpdateError> in
                guard let realm = self?.realm else { return SignalProducer(error: UpdateError.realmError) }

                do {
                    try realm.write() {
                        realm.add(Metadata(using: metadata))
                        realm.add(animals.map() { AnimalData(using: $0) })
                    }
                } catch (let e) {
                    fatalError("Error occured when writing to realm: \(e)")
                }

                return SignalProducer(value: UpdateStatus.dataUpdated)
            }
//        SignalProducer { sink, _ in
//            if(forced) {
//                return self.zooApi.getAnimals()
//                    .map() { metadata, animals -> UpdateStatus in
//                        return .dataUpdated
//                    }
//            } else {
//                return SignalProducer<UpdateStatus, UpdateError>(value: .dataNotUpdated)
//            }
//        }
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
