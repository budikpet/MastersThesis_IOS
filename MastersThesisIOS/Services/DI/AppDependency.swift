import Foundation
import RealmSwift
import CoreLocation

typealias HasBaseAPIDependecies = HasNetwork & HasJSONAPI & HasAuthenticatedJSONAPI & HasAuthHandler & HasRealm
typealias HasAPIDependencies = HasPushAPI & HasFetcher & HasExampleAPI & HasZooAPI
typealias HasCredentialsDependencies = HasCredentialsProvider & HasCredentialsStore
typealias HasManagerDependencies = HasPushManager & HasUserManager & HasFirebasePushObserver & HasVersionUpdateManager & HasRealmDBManager & HasLocationManager & HasZooNavigationService

/// Container for all app dependencies
final class AppDependency: HasBaseAPIDependecies, HasCredentialsDependencies, HasManagerDependencies, HasAPIDependencies {
    lazy var network: Networking = Network()
    lazy var authHandler: AuthHandling = AuthHandler()
    lazy var realm: Realm = self.initRealm()

    lazy var credentialsProvider: CredentialsProvider = UserDefaults.credentials
    lazy var credentialsStore: CredentialsStore = UserDefaults.credentials

    lazy var jsonAPI: JSONAPIServicing = JSONAPIService(dependencies: self)
    lazy var authJSONAPI: JSONAPIServicing = AuthenticatedJSONAPIService(dependencies: self)
    lazy var pushAPI: PushAPIServicing = PushAPIService(dependencies: self)
    lazy var exampleAPI: ExampleAPIServicing = ExampleAPIService(dependencies: self)
    lazy var zooAPI: ZooAPIServicing = ZooAPIService(dependencies: self)

    lazy var fetcher: Fetcher = FirebaseFetcher(key: "min_version")
    lazy var firebasePushObserver: FirebasePushObserving = FirebasePushObserver(dependencies: self)

    lazy var pushManager: PushManaging = PushManager(dependencies: self)
    lazy var userManager: UserManaging = UserManager()
    lazy var versionUpdateManager: VersionUpdateManaging = VersionUpdateManager(dependencies: self)
    lazy var realmDBManager: RealmDBManaging = RealmDBManager(dependencies: self)
    lazy var zooNavigationService: ZooNavigationServicing = ZooNavigationService(dependencies: self)
    lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        manager.requestWhenInUseAuthorization()

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
