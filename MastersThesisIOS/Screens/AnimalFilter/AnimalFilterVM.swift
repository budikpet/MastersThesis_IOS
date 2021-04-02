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

    var data: Results<AnimalData> { get }

    func animal(at index: Int) -> AnimalData
    func getAnimalFilterItemCellVM(at indexPath: IndexPath) -> AnimalFilterItemCellVM
    func rowHeightAt(_ index: Int) -> CGFloat
}

extension AnimalFilterViewModeling where Self: AnimalFilterViewModelingActions {
    var actions: AnimalFilterViewModelingActions { self }
}

final class AnimalFilterVM: BaseViewModel, AnimalFilterViewModeling, AnimalFilterViewModelingActions {
    typealias Dependencies = HasNetwork & HasRealmDBManager
    let realmDbManager: RealmDBManaging

    var data: Results<AnimalData>

    // MARK: Actions
    internal var updateLocalDB: Action<Bool, UpdateStatus, UpdateError>

    // MARK: Initializers

    init(dependencies: Dependencies) {
        realmDbManager = dependencies.realmDBManager
        updateLocalDB = realmDbManager.actions.updateLocalDB

        data = realmDbManager.objects.animalData

        super.init()
        setupBindings()
    }

    private func setupBindings() {

    }
}

// MARK: VC Delegate/DataSource helpers

extension AnimalFilterVM {
    func animal(at index: Int) -> AnimalData {
        let item = data[index]

        return item
    }

    func getAnimalFilterItemCellVM(at indexPath: IndexPath) -> AnimalFilterItemCellVM {
        // TODO: Connect to section/index
        return AnimalFilterItemCellVM(withValue: "TMP", checked: true)
    }

    func rowHeightAt(_ index: Int) -> CGFloat {
        return 50.0
    }
}
