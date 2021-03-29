import Foundation
import RealmSwift

typealias HasBaseAPIDependecies = HasNetwork & HasJSONAPI & HasAuthenticatedJSONAPI & HasAuthHandler
typealias HasAPIDependencies = HasPushAPI & HasFetcher & HasExampleAPI & HasZooAPI
typealias HasCredentialsDependencies = HasCredentialsProvider & HasCredentialsStore
typealias HasManagerDependencies = HasPushManager & HasUserManager & HasFirebasePushObserver & HasVersionUpdateManager & HasRealm

/// Container for all app dependencies
final class AppDependency: HasBaseAPIDependecies, HasCredentialsDependencies, HasManagerDependencies, HasAPIDependencies {
    lazy var network: Networking = Network()
    lazy var authHandler: AuthHandling = AuthHandler()

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

    lazy var realm: Realm = AppDependency.realm()

    // MARK: - Initializers

    /// This class is not supposed to be instantiated elsewhere
    fileprivate init() {

    }

    /**
     Provides Realm DB object. Automatically creates in-memory Realm DB object when testing.
     */
    private static func realm() -> Realm {
        do {
            guard let fileURL = FileManager.default
                .containerURL(forSecurityApplicationGroupIdentifier: Bundle.main.bundleIdentifier ?? "cz.budikpet.MastersThesisIOS")?
                .appendingPathComponent("default.realm")
            else {
                throw "Could not get fileURL."
            }
            let config = Realm.Configuration(fileURL: fileURL)

            return try Realm(configuration: config)
        } catch {
            fatalError("Error initializing new Realm for the first time: \(error)")
        }
    }
}

protocol HasNoDependency { }
extension AppDependency: HasNoDependency { }

protocol HasRealm {
    var network: Networking { get }
}

let appDependencies = AppDependency()
