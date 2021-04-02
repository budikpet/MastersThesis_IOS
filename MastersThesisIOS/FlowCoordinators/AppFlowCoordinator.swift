import UIKit
import ACKategories
import os.log

final class AppFlowCoordinator: Base.FlowCoordinatorNoDeepLink {
    private weak var tabBarController: UITabBarController?

    override func start(in window: UIWindow) {
        super.start(in: window)

        let tabBarController = UITabBarController()
        self.tabBarController = tabBarController
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
}

extension AppFlowCoordinator: LexiconVCFlowDelegate {
    func viewFilters() {
        print("view filters")
    }

    func viewAnimal(using animal: AnimalData) {
        let vm = AnimalDetailVM(dependencies: appDependencies, using: animal)
        let vc = AnimalDetailVC(viewModel: vm)
        vc.flowDelegate = self

        guard let navController = self.navigationController(for: .lexicon) as? UINavigationController else {
            fatalError("Did not get UINavigationController from the root TabBar.")
        }

        navController.pushViewController(vc, animated: true)
    }
}

extension AppFlowCoordinator: AnimalDetailFlowDelegate {

}

// MARK: Helpers

extension AppFlowCoordinator {
    private func navigationController(for tabBarPage: TabBarPage) -> UIViewController? {
        return self.tabBarController?.viewControllers?[tabBarPage.pageOrderNumber()]
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
            let vm = LexiconVM(dependencies: appDependencies)
            let vc = LexiconVC(viewModel: vm)
            vc.flowDelegate = self
            navVC.pushViewController(vc, animated: true)
        case .zooMap:
            let vm = MapVM(dependencies: appDependencies)
            let vc = MapVC(viewModel: vm)
            navVC.pushViewController(vc, animated: true)
        }

        return navVC
    }
}
