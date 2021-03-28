//
//  LexiconVM.swift
//  MastersThesisIOS
//
//  Created by Petr Budík on 21/03/2021.
//

import UIKit
import ReactiveSwift
import os.log

protocol LexiconViewModelingActions {
}

protocol LexiconViewModeling {
	var actions: LexiconViewModelingActions { get }

    var data: Property<[AnimalData]> { get }

    func animal(at index: Int) -> AnimalData
    func getLexiconItemCellVM(at index: Int) -> LexiconItemCellVM
    func rowHeightAt(_ index: Int) -> CGFloat
}

extension LexiconViewModeling where Self: LexiconViewModelingActions {
    var actions: LexiconViewModelingActions { self }
}

final class LexiconVM: BaseViewModel, LexiconViewModeling, LexiconViewModelingActions {
    typealias Dependencies = HasNetwork

    var data: Property<[AnimalData]>

    let animals: [AnimalData] = {
        let data1 = AnimalData(withId: 1)
        data1.name = "Name 1"
        data1.location_in_zoo = "Pavilon XYZ"
        data1.image_url = "https://www.zoopraha.cz/images/lexikon/Adax_foto_Vaclav_Silha_3I4A6578_export.jpg"
        data1.latin_name = "Animalus Namus 1"
        data1.base_summary = "Lorem ipsum for the base summary."
        data1.class_ = "Savec"
        data1.class_latin = "Savcum"
        data1.order = "Order"
        data1.order_latin = "Order_latin"
        data1.continent = "Europe"
        data1.continent_detail = "Czech republic"
        data1.biotop = "Hory"
        data1.biotop_detail = "Alpy"
        data1.food = "Food"
        data1.sizes = "Sizes"
        data1.reproduction = "Reproduction"
        data1.interesting_data = "Lorem ipsum for interesting data."
        data1.about_placement_in_zoo_prague = "Lorem ipsum for placement details."
        data1.location_in_zoo = "Horní část Zoo"
        data1.map_locations.append(objectsIn: [Int64.init(1), Int64.init(2)])

        let data2 = AnimalData(withId: 2)
        data2.name = "Name 2"
//        data2.location_in_zoo = "Horní část Zoo"
        data2.map_locations.append(21)
        data2.image_url = "https://www.zoopraha.cz/images/lexikon/bazant_palawansky_DSC_1416.jpg"

        let data3 = AnimalData(withId: 3)
        data3.name = "Name 3"
//        data3.map_locations.append(44)
        data3.image_url = "https://www.zoopraha.cz/images/lexikon-images/_22J6092.jpg"

        return [data1, data2, data3]
    }()

    // MARK: Initializers

    init(dependencies: Dependencies) {
        data = Property(initial: [], then: SignalProducer(value: animals))

        super.init()
        setupBindings()
    }

    private func setupBindings() {

    }
}

// MARK: VC Delegate/DataSource helpers

extension LexiconVM {
    func animal(at index: Int) -> AnimalData {
        let item = data.value[index]

        return item
    }

    func getLexiconItemCellVM(at index: Int) -> LexiconItemCellVM {
        return LexiconItemCellVM(withAnimal: animal(at: index))
    }

    func rowHeightAt(_ index: Int) -> CGFloat {
        return 80.0
    }
}
