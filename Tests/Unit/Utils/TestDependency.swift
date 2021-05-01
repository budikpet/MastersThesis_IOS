import Foundation
import RealmSwift
import CoreLocation
@testable import MastersThesisIOS

/// Container for all app dependencies
final class TestAppDependency: HasAllDependencies {
    lazy var network: Networking = Network()
    lazy var realm: Realm = self.createEmptyRealm()

    lazy var jsonAPI: JSONAPIServicing = JSONAPIService(dependencies: self)
    lazy var zooAPI: ZooAPIServicing = ZooAPIService(dependencies: self)

    lazy var fetcher: Fetcher = FirebaseFetcher(key: "min_version")

    lazy var storageManager: StorageManaging = StorageManager(dependencies: self)
    lazy var zooNavigationService: ZooNavigationServicing = ZooNavigationService(dependencies: self)
    lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters

        return manager
    }()

    lazy var testRealmInitializer: TestRealmInitializer = TestRealmInitializer(dependencies: self)

    // MARK: - Initializers

    /// This class is not supposed to be instantiated elsewhere
    fileprivate init() {

    }

    /**
     Initializes `Realm` instance with all needed configuration
     - Returns:
        A new `Realm` instance.
     */
    func createEmptyRealm() -> Realm {
        do {
            let realmConfig: Realm.Configuration = Realm.Configuration(inMemoryIdentifier: UUID().uuidString, encryptionKey: nil, readOnly: false, schemaVersion: 0, migrationBlock: nil, objectTypes: nil)
            let realm = try Realm(configuration: realmConfig)

            try! realm.write { () -> Void in
                realm.deleteAll()
            }

            return realm
        } catch {
            fatalError("Error initializing new Realm for the first time: \(error)")
        }
    }
}

// MARK: Singleton

let testDependencies = TestAppDependency()
