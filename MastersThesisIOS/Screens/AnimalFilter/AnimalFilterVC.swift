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

    private weak var tableView: UITableView!
    private weak var resetFilter: UIBarButtonItem!

    // MARK: Initializers

    init(viewModel: AnimalFilterViewModeling) {
        self.viewModel = viewModel

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: View life cycle

    override func loadView() {
        super.loadView()
        view.accessibilityIdentifier = "AnimalFilterVC"

        let resetFilter = UIBarButtonItem(image: UIImage(systemName: "trash"), style: .plain, target: self, action: #selector(resetFilterTapped))
        self.resetFilter = resetFilter
        navigationItem.rightBarButtonItem = resetFilter

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

        navigationItem.title = L10n.NavigationItem.Title.animalFilter
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.persistChanges()
    }

    // MARK: Helpers

    private func setupBindings() {
        tableView.reactive.reloadData <~ viewModel.viewedAnimalFilters.producer.map() { _ in }
    }

    @objc
    private func resetFilterTapped(_ sender: UIBarButtonItem) {
        viewModel.resetFilter()
    }

}

// MARK: UITableView delegate and data source
extension AnimalFilterVC: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.viewedAnimalFilters.value.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch viewModel.viewedAnimalFilters.value[section].type {
        case "class_":
            return L10n.AnimalFilter.class
        case "biotop":
            return L10n.AnimalFilter.biotop
        case "food":
            return L10n.AnimalFilter.food
        case "location_in_zoo":
            return L10n.AnimalFilter.zooHouse
        default:
            fatalError("Unknown section value")
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.viewedAnimalFilters.value[section].cellValues.count
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
}
