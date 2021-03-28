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

    var animal: MutableProperty<AnimalData> { get }
}

extension AnimalDetailViewModeling where Self: AnimalDetailViewModelingActions {
    var actions: AnimalDetailViewModelingActions { self }
}

final class AnimalDetailVM: BaseViewModel, AnimalDetailViewModeling, AnimalDetailViewModelingActions {
    typealias Dependencies = HasNoDependency

    let animal: MutableProperty<AnimalData>

    // MARK: Initializers

    init(dependencies: Dependencies, using animal: AnimalData) {
        self.animal = MutableProperty(animal)

        super.init()
        setupBindings()
    }

    private func setupBindings() {

    }
}
