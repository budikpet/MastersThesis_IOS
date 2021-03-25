//
//  LexiconVC.swift
//  MastersThesisIOS
//
//  Created by Petr Budík on 21/03/2021.
//

import UIKit
import ReactiveSwift

final class LexiconVC: BaseViewController {

    private weak var tableView: UITableView!

    // MARK: Dependencies

    private let viewModel: LexiconViewModeling

    // MARK: Initializers

    init(viewModel: LexiconViewModeling) {
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
        view.accessibilityIdentifier = "LexiconVC"

        let tableView = UITableView(frame: self.view.bounds, style: UITableView.Style.plain)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.accessibilityIdentifier = "LexiconVC_TableView"

        tableView.register(LexiconItemCell.self, forCellReuseIdentifier: "LexiconItemCell")
        view.addSubview(tableView)
        self.tableView = tableView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = 120

        setupBindings()

        // TODO: Move to VM?
        navigationItem.title = L10n.NavigationItem.Title.lexicon
    }

    // MARK: Helpers

    private func setupBindings() {

        viewModel.data.signal
            .take(during: reactive.lifetime)
            .observeValues { [unowned self] _ in
                self.tableView.reloadData()
            }

//        activityIndicator.reactive.isAnimating <~ viewModel.actions.fetchPhoto.isExecuting
//
//        viewModel.actions.fetchPhoto <~ reloadButton.reactive.controlEvents(.touchUpInside).map { _ in }
//
//        imageView.reactive.image <~ viewModel.photo

    }

}

// MARK: UITableView delegate and data source
extension LexiconVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.data.value.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // swiftlint:disable force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: "LexiconItemCell", for: indexPath) as! LexiconItemCell
        let data = viewModel.item(at: indexPath.row)
        cell.setData(using: data)

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let animals = viewModel.data.value

        let item = animals[indexPath.row]

        tableView.deselectRow(at: indexPath, animated: true)
    }
}
