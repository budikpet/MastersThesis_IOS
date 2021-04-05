//
//  LexiconVC.swift
//  MastersThesisIOS
//
//  Created by Petr Budík on 21/03/2021.
//

import UIKit
import ReactiveSwift
import ReactiveCocoa
import RealmSwift

protocol LexiconVCFlowDelegate: class {
    func viewAnimal(using animal: AnimalData)
    func viewFilters()
}

final class LexiconVC: BaseViewController {
    // MARK: Dependencies

    private let viewModel: LexiconViewModeling
    weak var flowDelegate: LexiconVCFlowDelegate?

    private weak var tableView: UITableView!
    private weak var refreshControl: UIRefreshControl!
    private lazy var searchBar: UISearchBar = UISearchBar()

    private var filterItem: UIBarButtonItem!
    private var searchItem: UIBarButtonItem!

    private lazy var searchBarVisibilityAction: Action<Bool, Void, Never> = Action { [weak self] (isVisible: Bool) in
        (self?.searchBarVisibility(isVisible: isVisible) ?? SignalProducer.empty)
    }

    // MARK: Initializers

    init(viewModel: LexiconViewModeling) {
        self.viewModel = viewModel

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.filterItem = nil
        self.searchItem = nil
    }

    // MARK: View life cycle

    override func loadView() {
        super.loadView()
        view.backgroundColor = .white
        view.accessibilityIdentifier = "LexiconVC"

        searchBar.sizeToFit()
        searchBar.placeholder = " Search..."
        searchBar.showsCancelButton = true

        let filterItem = UIBarButtonItem(image: UIImage(named: "animalFilter"), style: .plain, target: self, action: #selector(self.filterTapped))
        self.filterItem = filterItem

        let searchItem = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: nil)
        self.searchItem = searchItem

        self.navigationItem.rightBarButtonItems = [searchItem, filterItem]

        let tableView = UITableView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.accessibilityIdentifier = "LexiconVC_TableView"

        tableView.register(LexiconItemCellVC.self, forCellReuseIdentifier: LexiconItemCellVC.identifier)
        view.addSubview(tableView)
        self.tableView = tableView

        let refreshControl = UIRefreshControl()
        self.refreshControl = refreshControl
        refreshControl.attributedTitle = NSAttributedString(string: L10n.Lexicon.updatingDB)
        tableView.addSubview(refreshControl)

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
        tableView.reactive.reloadData <~ viewModel.filteredAnimalData.signal.map() { _ in }

        refreshControl.reactive.isRefreshing <~ viewModel.actions.updateLocalDB.isExecuting
        viewModel.actions.updateLocalDB <~ refreshControl.reactive.controlEvents(.valueChanged).map() { _ in false }

        // Bind showing/hiding SearchBar
        self.searchItem.reactive.pressed = CocoaAction(self.searchBarVisibilityAction) { _ -> Bool in return true }
        self.searchBarVisibilityAction <~ self.searchBar.reactive.cancelButtonClicked.map() { return false }

        // Bind hiding UIBarButtonItems when SearchBar is used
        self.navigationItem.reactive.rightBarButtonItems <~ self.searchBar.reactive.visibility
            .map() { [weak self] searchBarVisible -> [UIBarButtonItem] in
                guard let self = self else { return [] }
                return searchBarVisible ? [] : [self.searchItem, self.filterItem]
            }

        self.viewModel.searchText <~ SignalProducer(self.searchBar.reactive.continuousTextValues)
            .compactMap() { return $0 }

        // Reset searchText and search bar when the search bar is opened/closed
        self.viewModel.searchText <~ self.searchBar.reactive.visibility.compactMap { _ in "" }
        self.searchBar.reactive.text <~ self.searchBar.reactive.visibility.compactMap { _ in "" }

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

//    @objc
//    private func searchTapped(_ sender: UIBarButtonItem) {
//        navigationItem.titleView = self.searchBar
//        self.searchBar.showsCancelButton = true
//        self.searchBar.becomeFirstResponder()
////        navigationItem.rightBarButtonItems = nil
//    }

}

// MARK: Helpers
extension LexiconVC {
    @objc
    private func filterTapped(_ sender: UIBarButtonItem) {
        flowDelegate?.viewFilters()
    }

    private func searchBarVisibility(isVisible: Bool) -> SignalProducer<Void, Never> {
        SignalProducer<Void, Never> { [weak self] observer, _ in
            guard let self = self else { return }
            if(isVisible) {
                self.navigationItem.titleView = self.searchBar
                self.searchBar.isHidden = false
                self.searchBar.becomeFirstResponder()
            } else {
                self.navigationItem.titleView = nil
                self.searchBar.isHidden = true
            }

            observer.sendCompleted()
        }
    }
}

// MARK: UITableView delegate and data source
extension LexiconVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.filteredAnimalData.value.count
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

        flowDelegate?.viewAnimal(using: animal)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return viewModel.rowHeightAt(indexPath.row)
    }
}
