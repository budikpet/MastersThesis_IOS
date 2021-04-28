import Foundation
import RealmSwift
import CoreLocation

typealias HasBaseAPIDependecies = HasNetwork & HasJSONAPI & HasRealm
typealias HasAPIDependencies = HasFetcher & HasZooAPI
typealias HasManagerDependencies = HasRealmDBManager & HasLocationManager & HasZooNavigationService

/// Container for all app dependencies
final class AppDependency: HasBaseAPIDependecies, HasManagerDependencies, HasAPIDependencies {
    lazy var network: Networking = Network()
    lazy var realm: Realm = self.initRealm()

    lazy var jsonAPI: JSONAPIServicing = JSONAPIService(dependencies: self)
    lazy var zooAPI: ZooAPIServicing = ZooAPIService(dependencies: self)

    lazy var fetcher: Fetcher = FirebaseFetcher(key: "min_version")

    lazy var realmDBManager: RealmDBManaging = RealmDBManager(dependencies: self)
    lazy var zooNavigationService: ZooNavigationServicing = ZooNavigationService(dependencies: self)
    lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters

        return manager
    }()

    // MARK: - Initializers

    /// This class is not supposed to be instantiated elsewhere
    fileprivate init() {

    }

    /**
     Initializes `Realm` instance with all needed configuration
     - Returns:
        A new `Realm` instance.
     */
    private func initRealm() -> Realm {
        do {
            return try Realm()
        } catch {
            fatalError("Error initializing new Realm for the first time: \(error)")
        }
    }
}

// MARK: Other protocols

protocol HasLocationManager {
    var locationManager: CLLocationManager { get }
}

protocol HasRealm {
    var realm: Realm { get }
}

protocol HasNoDependency { }
extension AppDependency: HasNoDependency { }

// MARK: Singleton

let appDependencies = AppDependency()
