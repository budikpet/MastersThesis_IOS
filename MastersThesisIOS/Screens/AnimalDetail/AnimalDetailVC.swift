//
//  AnimalDetailVC.swift
//  MastersThesisIOS
//
//  Created by Petr Budík on 28/03/2021.
//  Copyright © 2021 Petr Budík. All rights reserved.
//

import UIKit
import ReactiveSwift

protocol AnimalDetailFlowDelegate: class {

}

final class AnimalDetailVC: BaseViewController {

    private weak var tableView: UITableView!

    // MARK: Dependencies

    private let viewModel: AnimalDetailViewModeling

    weak var flowDelegate: AnimalDetailFlowDelegate?

    // MARK: Initializers

    init(viewModel: AnimalDetailViewModeling) {
        self.viewModel = viewModel

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: View life cycle

    override func loadView() {
        super.loadView()
        view.backgroundColor = .white
        view.accessibilityIdentifier = "AnimalDetailVC"

    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupBindings()

//        // TODO: Move to VM?
//        navigationItem.title = L10n.NavigationItem.Title.lexicon
    }

    // MARK: Helpers

    private func setupBindings() {

//        activityIndicator.reactive.isAnimating <~ viewModel.actions.fetchPhoto.isExecuting
//
//        viewModel.actions.fetchPhoto <~ reloadButton.reactive.controlEvents(.touchUpInside).map { _ in }
//
//        imageView.reactive.image <~ viewModel.photo

    }

}
