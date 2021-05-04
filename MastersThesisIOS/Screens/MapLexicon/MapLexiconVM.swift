//
//  MapLexiconVM.swift
//  MastersThesisIOS
//
//  Created by Petr Budík on 16/04/2021.
//

import UIKit
import ReactiveSwift
import os.log

protocol MapLexiconViewModeling {
    var animalData: MutableProperty<[AnimalData]> { get }

    func animal(at index: Int) -> AnimalData
    func getLexiconItemCellVM(at index: Int) -> LexiconItemCellVM
    func rowHeightAt(_ index: Int) -> CGFloat
}

final class MapLexiconVM: BaseViewModel, MapLexiconViewModeling {
    typealias Dependencies = HasNoDependency

    // MARK: Internal
    internal var animalData: MutableProperty<[AnimalData]>

    // MARK: Initializers

    init(dependencies: Dependencies, dataToShow animalData: [AnimalData]) {
        self.animalData = MutableProperty(animalData)

        super.init()
        setupBindings()
    }

    private func setupBindings() {

    }
}

// MARK: VC Delegate/DataSource helpers

extension MapLexiconVM {
    func animal(at index: Int) -> AnimalData {
        return animalData.value[index]
    }

    func getLexiconItemCellVM(at index: Int) -> LexiconItemCellVM {
        return LexiconItemCellVM(withAnimal: animal(at: index))
    }

    func rowHeightAt(_ index: Int) -> CGFloat {
        return 100.0
    }
}
