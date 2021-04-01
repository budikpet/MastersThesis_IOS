//
//  AnimalDetailVM.swift
//  MastersThesisIOS
//
//  Created by Petr Budík on 28/03/2021.
//  Copyright © 2021 Petr Budík. All rights reserved.
//

import UIKit
import ReactiveSwift
import os.log

protocol AnimalDetailViewModelingActions {
}

protocol AnimalDetailViewModeling {
    var actions: AnimalDetailViewModelingActions { get }

    var animal: Property<AnimalData> { get }
}

extension AnimalDetailViewModeling where Self: AnimalDetailViewModelingActions {
    var actions: AnimalDetailViewModelingActions { self }
}

final class AnimalDetailVM: BaseViewModel, AnimalDetailViewModeling, AnimalDetailViewModelingActions {
    typealias Dependencies = HasRealmDBManager
    private let realmDbManager: RealmDBManaging

    let animal: Property<AnimalData>

    // MARK: Initializers

    init(dependencies: Dependencies, using animal: AnimalData) {
        self.realmDbManager = dependencies.realmDBManager
        self.animal = animal.reactive.property

        super.init()
        setupBindings()
    }

    private func setupBindings() {

    }
}
