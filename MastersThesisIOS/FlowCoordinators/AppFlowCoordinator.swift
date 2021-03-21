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
        tabBarController.selectedIndex = TabBarPage.zooMap.pageOrderNumber()
        /// Styling
        tabBarController.tabBar.isTranslucent = false

//        let vm = ExampleViewModel(dependencies: appDependencies)
//        let vc = ExampleViewController(viewModel: vm)
//
//        window.rootViewController = vc
//
//        rootViewController = vc
    }

    private func initTabController(_ page: TabBarPage) -> UINavigationController {
        let navVC = UINavigationController()
        navVC.setNavigationBarHidden(false, animated: false)
        navVC.tabBarItem = UITabBarItem.init(title: page.rawValue, image: nil, tag: page.pageOrderNumber())

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
