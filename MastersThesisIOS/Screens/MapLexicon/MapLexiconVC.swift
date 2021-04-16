//
//  MapLexiconVC.swift
//  MastersThesisIOS
//
//  Created by Petr Budík on 16/04/2021.
//

import UIKit
import ReactiveSwift

protocol MapLexiconVCFlowDelegate: class {
    func viewAnimalFromMap(using animal: AnimalData)
}

/**
 A lexicon VC that is supposed to be used to show animals highlighted from the map directly.
 */
final class MapLexiconVC: BaseViewController {
    // MARK: Dependencies

    private let viewModel: MapLexiconViewModeling
    weak var flowDelegate: MapLexiconVCFlowDelegate?

    private weak var tableView: UITableView!

    // MARK: Initializers

    init(viewModel: MapLexiconViewModeling) {
        self.viewModel = viewModel

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: View life cycle

    override func loadView() {
        super.loadView()
        view.accessibilityIdentifier = "MapLexiconVC"

        let tableView = UITableView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.accessibilityIdentifier = "MapLexiconVC_TableView"

        tableView.register(LexiconItemCellVC.self, forCellReuseIdentifier: LexiconItemCellVC.identifier)
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

    private func setupBindings() {
    }
}

// MARK: UITableView delegate and data source
extension MapLexiconVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.animalData.value.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // swiftlint:disable force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: LexiconItemCellVC.identifier, for: indexPath) as! LexiconItemCellVC
        cell.viewModel = viewModel.getLexiconItemCellVM(at: indexPath.row)

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let animal = viewModel.animal(at: indexPath.row)
        tableView.deselectRow(at: indexPath, animated: true)

        flowDelegate?.viewAnimalFromMap(using: animal)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return viewModel.rowHeightAt(indexPath.row)
    }
}
