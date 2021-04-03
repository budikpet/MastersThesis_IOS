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

    var data: Results<AnimalFilter> { get }
    var editedRows: EditedRows { get }

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

    var data: Results<AnimalFilter>

    // MARK: Actions
    internal var updateLocalDB: Action<Bool, UpdateStatus, UpdateError>

    var editedRows: EditedRows = .all

    // MARK: Initializers

    init(dependencies: Dependencies) {
        realmDbManager = dependencies.realmDBManager
        updateLocalDB = realmDbManager.actions.updateLocalDB

        data = realmDbManager.objects.animalFilter

        super.init()
        setupBindings()
    }

    private func setupBindings() {

    }
}

// MARK: VC Delegate/DataSource helpers

extension AnimalFilterVM {
    func pickValue(at indexPath: IndexPath) {
        let filter = data[indexPath.section]
        editedRows = EditedRows.one(indexPath.row)

        realmDbManager.realmEdit { _ in
            filter.checkmarkValues[indexPath.row] = !filter.checkmarkValues[indexPath.row]
        }
    }

    func getAnimalFilterItemCellVM(at indexPath: IndexPath) -> AnimalFilterItemCellVM {
        let filter = data[indexPath.section]
        let value = filter.values[indexPath.row]
        let isChecked = filter.checkmarkValues[indexPath.row]
        return AnimalFilterItemCellVM(withValue: value, checked: isChecked)
    }

    func rowHeightAt(_ index: Int) -> CGFloat {
        return 30.0
    }
}

enum EditedRows {
    case all
    case one(Int)
}
