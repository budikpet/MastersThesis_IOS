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

final class AnimalFilterVC: BaseViewController {
    // MARK: Dependencies

    private let viewModel: AnimalFilterViewModeling

    private var realmToken: NotificationToken?

    private weak var tableView: UITableView!

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

        let tableView = UITableView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.accessibilityIdentifier = "AnimalFilterVC_TableView"
        tableView.separatorStyle = .none

        tableView.register(AnimalFilterItemCellVC.self, forCellReuseIdentifier: AnimalFilterItemCellVC.identifier)
        view.addSubview(tableView)
        self.tableView = tableView

        tableView.snp.makeConstraints { (make) in
            make.edges.equalTo(self.view)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupBindings()

        navigationItem.title = L10n.NavigationItem.Title.lexicon
    }

    // MARK: Helpers

    private func setupBindings() {

        realmToken = viewModel.data.observe { [weak self] (changes: RealmCollectionChange) in
            guard let self = self else { return }
            switch changes {
            case .initial:
                self.tableView.reloadData()
                break
            case .update(_, _, _, let modifications):
                self.tableView.beginUpdates()

                switch self.viewModel.editedRows {
                case .all:
                    self.tableView.reloadData()
                case .one(let row):
                    self.tableView.reloadRows(at: modifications.map({ IndexPath(row: row, section: $0) }),
                                         with: .automatic)
                }

                self.tableView.endUpdates()
                break
            case .error:
                fatalError("Error occured during observation.")
            }
        }

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

}

// MARK: UITableView delegate and data source
extension AnimalFilterVC: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.data.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch viewModel.data[section].type {
        case "class_":
            return L10n.AnimalFilter.class
        case "biotop":
            return L10n.AnimalFilter.biotop
        case "food":
            return L10n.AnimalFilter.food
        default:
            fatalError("Unknown section value")
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.data[section].values.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // swiftlint:disable force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: AnimalFilterItemCellVC.identifier, for: indexPath) as! AnimalFilterItemCellVC
        cell.viewModel = viewModel.getAnimalFilterItemCellVM(at: indexPath)

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.pickValue(at: indexPath)
        tableView.deselectRow(at: indexPath, animated: true)
    }

//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return viewModel.rowHeightAt(indexPath.row)
//    }
}

struct Section {

}
