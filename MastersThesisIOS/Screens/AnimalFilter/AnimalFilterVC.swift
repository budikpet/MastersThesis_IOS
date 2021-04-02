//
//  AnimalFilterVC.swift
//  MastersThesisIOS
//
//  Created by Petr Budík on 02/04/2021.
//  Copyright © 2021 Petr Budík. All rights reserved.
//

import UIKit
import ReactiveSwift
import ReactiveCocoa
import RealmSwift

protocol AnimalFilterVCFlowDelegate: class {
    func viewAnimal(using animal: AnimalData)
    func viewFilters()
}

final class AnimalFilterVC: BaseViewController {
    // MARK: Dependencies

    private let viewModel: AnimalFilterViewModeling
    weak var flowDelegate: AnimalFilterVCFlowDelegate?

    private var realmToken: NotificationToken?

    private weak var tableView: UITableView!
    private weak var filterItem: UIBarButtonItem!

    // MARK: Initializers

    init(viewModel: AnimalFilterViewModeling) {
        self.viewModel = viewModel

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        realmToken?.invalidate()
    }

    // MARK: View life cycle

    override func loadView() {
        super.loadView()
        view.backgroundColor = .white
        view.accessibilityIdentifier = "AnimalFilterVC"

        let filterItem = UIBarButtonItem(image: UIImage(named: "animalFilter"), style: .plain, target: self, action: #selector(filterTapped))
        self.filterItem = filterItem
        navigationItem.rightBarButtonItem = filterItem

        let tableView = UITableView(frame: self.view.bounds, style: UITableView.Style.plain)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.accessibilityIdentifier = "AnimalFilterVC_TableView"

        tableView.register(AnimalFilterItemCellVC.self, forCellReuseIdentifier: AnimalFilterItemCellVC.identifier)
        view.addSubview(tableView)
        self.tableView = tableView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = 120

        setupBindings()

        navigationItem.title = L10n.NavigationItem.Title.lexicon
    }

    // MARK: Helpers

    private func setupBindings() {

//        realmToken = viewModel.data.observe { [weak self] (changes: RealmCollectionChange) in
//            guard let tableView = self?.tableView else { return }
//            switch changes {
//            case .initial:
//                tableView.reloadData()
//                break
//            case .update(_, let deletions, let insertions, let modifications):
//                tableView.beginUpdates()
//                tableView.insertRows(at: insertions.map({ IndexPath(row: $0, section: 0) }),
//                                     with: .automatic)
//                tableView.deleteRows(at: deletions.map({ IndexPath(row: $0, section: 0)}),
//                                     with: .automatic)
//                tableView.reloadRows(at: modifications.map({ IndexPath(row: $0, section: 0) }),
//                                     with: .automatic)
//                tableView.endUpdates()
//                break
//            case .error:
//                fatalError("Error occured during observation.")
//            }
//        }

//        viewModel.data.signal
//            .take(during: reactive.lifetime)
//            .observeValues { [unowned self] _ in
//                self.tableView.reloadData()
//            }
//        let res = SignalProducer(value: Change.initial(viewModel.data))
//        self.reactive.changes <~ res

//        activityIndicator.reactive.isAnimating <~ viewModel.actions.fetchPhoto.isExecuting
//
//        viewModel.actions.fetchPhoto <~ reloadButton.reactive.controlEvents(.touchUpInside).map { _ in }
//
//        imageView.reactive.image <~ viewModel.photo

    }

    @objc
    private func filterTapped(_ sender: UIBarButtonItem) {
        flowDelegate?.viewFilters()
    }

}

// MARK: UITableView delegate and data source
extension AnimalFilterVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.data.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // swiftlint:disable force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: AnimalFilterItemCellVC.identifier, for: indexPath) as! AnimalFilterItemCellVC
        cell.viewModel = viewModel.getAnimalFilterItemCellVM(at: indexPath)

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let animal = viewModel.animal(at: indexPath.row)
        tableView.deselectRow(at: indexPath, animated: true)

        flowDelegate?.viewAnimal(using: animal)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return viewModel.rowHeightAt(indexPath.row)
    }
}
