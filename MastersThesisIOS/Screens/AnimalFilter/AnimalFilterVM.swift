//
//  AnimalFilterVM.swift
//  MastersThesisIOS
//
//  Created by Petr Budík on 02/04/2021.
//  Copyright © 2021 Petr Budík. All rights reserved.
//

import UIKit
import ReactiveSwift
import RealmSwift
import os.log

protocol AnimalFilterViewModelingActions {
    var updateLocalDB: Action<Bool, UpdateStatus, UpdateError> { get }
}

protocol AnimalFilterViewModeling {
    var actions: AnimalFilterViewModelingActions { get }

    var viewedAnimalFilters: MutableProperty<[ViewedAnimalFilter]> { get }

    func persistChanges()
    func pickValue(at indexPath: IndexPath)
    func getAnimalFilterItemCellVM(at indexPath: IndexPath) -> AnimalFilterItemCellVM
    func rowHeightAt(_ index: Int) -> CGFloat
}

extension AnimalFilterViewModeling where Self: AnimalFilterViewModelingActions {
    var actions: AnimalFilterViewModelingActions { self }
}

final class AnimalFilterVM: BaseViewModel, AnimalFilterViewModeling, AnimalFilterViewModelingActions {
    typealias Dependencies = HasNetwork & HasRealmDBManager
    let realmDbManager: RealmDBManaging

    internal var viewedAnimalFilters: MutableProperty<[ViewedAnimalFilter]>

    // MARK: Actions
    internal var updateLocalDB: Action<Bool, UpdateStatus, UpdateError>

    private var animalFilters: Results<AnimalFilter>
    private var realmToken: NotificationToken?

    // MARK: Initializers

    init(dependencies: Dependencies) {
        realmDbManager = dependencies.realmDBManager
        updateLocalDB = realmDbManager.actions.updateLocalDB

        animalFilters = realmDbManager.realm.objects(AnimalFilter.self)
        viewedAnimalFilters = MutableProperty(animalFilters.map() { ViewedAnimalFilter($0) })

        super.init()
        setupBindings()
    }

    deinit {
        realmToken?.invalidate()
    }

    func persistChanges() {
        realmDbManager.realmEdit { (realm: Realm) in
            for viewedAnimalFilter in viewedAnimalFilters.value {
                viewedAnimalFilter.persistChanges(realm)
            }
        }
    }

    private func setupBindings() {
        realmToken = animalFilters.observe { [weak self] (changes: RealmCollectionChange) in
            guard let self = self else { return }
            switch changes {
            case .initial:
                break
            case .update(let newAnimalFilters, _, _, _):
                self.viewedAnimalFilters.value = newAnimalFilters.map() { ViewedAnimalFilter($0) }
                break
            case .error:
                fatalError("Error occured during observation.")
            }
        }
    }
}

// MARK: VC Delegate/DataSource helpers

extension AnimalFilterVM {
    func pickValue(at indexPath: IndexPath) {
        let filter = viewedAnimalFilters.value[indexPath.section]
        let cellValue = filter.cellValues[indexPath.row]

        cellValue.1.value = !cellValue.1.value
    }

    func getAnimalFilterItemCellVM(at indexPath: IndexPath) -> AnimalFilterItemCellVM {
        let filter = viewedAnimalFilters.value[indexPath.section]
        let cellValue = filter.cellValues[indexPath.row]
        return AnimalFilterItemCellVM(withValue: cellValue.0, checked: cellValue.1)
    }

    func rowHeightAt(_ index: Int) -> CGFloat {
        return 30.0
    }
}

/**
 Stores AnimalFilter values for viewing in AnimalFilter view.
 Has better structure for viewing than AnimalFilter class and its changes aren't stored in DB immediately.
 */
struct ViewedAnimalFilter {
    public let type: String

    /** Value of the filtered attribute. */
    public let cellValues: [(String, MutableProperty<Bool>)]

    private let animalFilter: AnimalFilter

    init(_ animalFilter: AnimalFilter) {
        self.type = animalFilter.type
        self.cellValues = Array(zip(animalFilter.values, animalFilter.checkmarkValues))
            .map { (value, checkmarkValue) -> (String, MutableProperty<Bool>) in
                (value, MutableProperty(checkmarkValue))
            }

        self.animalFilter = animalFilter
    }

    public func persistChanges(_ realm: Realm) {
        for (index, (_, newCheckmarkValue)) in cellValues.enumerated() {
            let checkmarkValue = animalFilter.checkmarkValues[index]
            if(checkmarkValue != newCheckmarkValue.value) {
                animalFilter.checkmarkValues[index] = newCheckmarkValue.value
            }
        }
    }
}
