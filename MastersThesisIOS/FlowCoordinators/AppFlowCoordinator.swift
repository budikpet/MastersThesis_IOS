import UIKit
import ACKategories

final class AppFlowCoordinator: Base.FlowCoordinatorNoDeepLink {

    override func start(in window: UIWindow) {
        super.start(in: window)

        let tabBarController = UITabBarController()
        window.rootViewController = tabBarController
        rootViewController = tabBarController

        let vcs = TabBarPage.allCases
            .sorted { $0.pageOrderNumber() < $1.pageOrderNumber() }
            .map({ initTabController($0) })

        // Customize TabBarController
        tabBarController.setViewControllers(vcs, animated: true)
        /// Let set index
        tabBarController.selectedIndex = TabBarPage.lexicon.pageOrderNumber()
        /// Styling
        tabBarController.tabBar.isTranslucent = false
    }

    private func initTabController(_ page: TabBarPage) -> UINavigationController {
        let navVC = UINavigationController()
        navVC.setNavigationBarHidden(false, animated: false)

        do {
            navVC.tabBarItem = try UITabBarItem.init(title: page.localizedName(), image: page.pageImage(), tag: page.pageOrderNumber())
        } catch {
            fatalError(error.localizedDescription)
        }

        switch page {
        case .lexicon:
            let lexiconVM = LexiconVM(dependencies: appDependencies)
            let lexiconVC = LexiconVC(viewModel: lexiconVM)
            navVC.pushViewController(lexiconVC, animated: true)
        case .zooMap:
            let lexiconVM = MapVM(dependencies: appDependencies)
            let lexiconVC = MapVC(viewModel: lexiconVM)
            navVC.pushViewController(lexiconVC, animated: true)
        }

        return navVC
    }
}
