import UIKit

final class TestingAppDelegate: NSObject, UIApplicationDelegate {
    var window: UIWindow?

    private lazy var appFlowCoordinator = AppFlowCoordinator(dependencies: testDependencies)

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.makeKeyAndVisible()

        testDependencies.testRealmInitializer.updateRealm()

        // swiftlint:disable force_unwrapping
        appFlowCoordinator.start(in: window!)
        return true
    }
}
